<#$
.SYNOPSIS
  Aggregates multiple scoring sheet markdown files and exports a combined CSV + summary.
.DESCRIPTION
  Scans a directory recursively (or explicit file list) for SCORING-SHEET*.md files, parses challenge scores
  using the same logic as Export-ScoringSheet.ps1, and produces:
    - combined-scores.csv (all rows)
    - combined-totals.csv (totals per team + grand totals)
.PARAMETER RootPath
  Directory to search. Defaults to current directory.
.PARAMETER Pattern
  Filename pattern (wildcards). Default: SCORING-SHEET*.md
.PARAMETER OutputDirectory
  Output path for aggregated CSV files. Default: ./scoring-aggregate
.EXAMPLE
  ./Aggregate-ScoringSheets.ps1 -RootPath ./teams
.NOTES
  Relies on a simplified parser similar to Export-ScoringSheet; expects consistent formatting.
#>
param(
  [string]$RootPath = (Get-Location).Path,
  [string]$Pattern = 'SCORING-SHEET*.md',
  [string]$OutputDirectory = 'scoring-aggregate',
  [switch]$IncludeJson,
  [switch]$GenerateSummary
)

if(-not (Test-Path $RootPath)){ Write-Error "Root path not found: $RootPath"; exit 1 }
$files = Get-ChildItem -Path $RootPath -Filter $Pattern -Recurse -File
if(-not $files){ Write-Error 'No scoring sheet files found.'; exit 1 }

$all = @()
foreach($f in $files){
  $raw = Get-Content -Raw -Path $f.FullName
  $section = [regex]::Match($raw,'(?s)## Challenge Scores(.*?)## Totals')
  if(-not $section.Success){ Write-Warning "Skipping (section missing): $($f.Name)"; continue }
  $lines = $section.Groups[1].Value -split "`n" | Where-Object { $_.Trim().StartsWith('|') }
  if($lines.Count -lt 3){ continue }
  $teamName = ([regex]::Match($raw,'\| Team \| Coach').Success) ? (([regex]::Match($raw,'\|\s*Team\s*\|\s*Coach\s*\|\s*Date\s*\|[\r\n]+\|\s*(?<team>[^|]+)\|')).Groups['team'].Value.Trim()) : ($f.BaseName)
  foreach($line in $lines | Select-Object -Skip 2){
    if($line -match '^\|\s*-+') { continue }
    $cols = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if($cols.Count -lt 5){ continue }
    $score = $null; if($cols[3] -match '^[0-9]+$'){ $score = [int]$cols[3] }
    $all += [pscustomobject]@{
      Team      = $teamName
      Challenge = $cols[0]
      Criteria  = $cols[1]
      Max       = $cols[2]
      Score     = $score
      Notes     = $cols[4]
      Source    = $f.FullName
    }
  }
}

if(-not (Test-Path $OutputDirectory)){ New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
$combinedPath = Join-Path $OutputDirectory 'combined-scores.csv'
$all | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $combinedPath

# Totals per team
$scored = $all | Where-Object { $_.Score -ne $null }
$totals = $scored | Group-Object Team | ForEach-Object {
  $sum = ($_.Group.Score | Measure-Object -Sum).Sum
  [pscustomobject]@{ Team=$_.Name; TotalScore=$sum }
} | Sort-Object -Property TotalScore -Descending

# Ranking & percentile calculation (higher percentile = better performance)
$count = $totals.Count
$rank = 0
$lastScore = $null
$ties = 0
foreach($t in $totals){
  if($lastScore -ne $t.TotalScore){
    $rank = $rank + 1 + $ties
    $ties = 0
  } else {
    $ties++
  }
  $lastScore = $t.TotalScore
  # Percentile (reversed so best score = 100%)
  $percentile = if($count -gt 0){ [math]::Round(((($count - $rank) + 1) / [double]$count) * 100,2) } else { 0 }
  $t | Add-Member -NotePropertyName Rank -NotePropertyValue $rank
  $t | Add-Member -NotePropertyName Percentile -NotePropertyValue $percentile
}
$totalsPath = Join-Path $OutputDirectory 'combined-totals.csv'
$totals | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $totalsPath

# Optional JSON outputs
if($IncludeJson){
  ($all | ConvertTo-Json -Depth 4) | Out-File (Join-Path $OutputDirectory 'combined-scores.json') -Encoding UTF8
  ($totals | ConvertTo-Json -Depth 4) | Out-File (Join-Path $OutputDirectory 'combined-totals.json') -Encoding UTF8
}

# Optional summary (Markdown + HTML dashboard-style)
if($GenerateSummary){
  $summaryMd = Join-Path $OutputDirectory 'summary.md'
  $summaryHtml = Join-Path $OutputDirectory 'summary.html'
  $avg = ($totals.TotalScore | Measure-Object -Average).Average
  $maxScore = ($totals.TotalScore | Measure-Object -Maximum).Maximum
  $minScore = ($totals.TotalScore | Measure-Object -Minimum).Minimum
  $md = @()
  $md += '# Scoring Summary'
  $md += ''
  $md += "Generated: $(Get-Date -Format o)"
  $md += ''
  $md += '## Team Rankings'
  $md += ''
  $md += '| Rank | Team | Total Score | Percentile |'
  $md += '|------|------|-------------|------------|'
  foreach($row in $totals){
    $md += "| $($row.Rank) | $($row.Team) | $($row.TotalScore) | $($row.Percentile)% |"
  }
  $md += ''
  $md += '## Statistics'
  $md += ''
  $md += "- Teams: $count"
  $md += "- Average Score: {0:N2}" -f $avg
  $md += "- Max Score: $maxScore"
  $md += "- Min Score: $minScore"
  $md += ''
  $md += '## Notes'
  $md += '- Percentile: higher value indicates better relative performance (top score = 100%).'
  $md += '- Ties share the same rank; next rank skips appropriately.'
  $md -join "`n" | Out-File -FilePath $summaryMd -Encoding UTF8

  # Simple HTML
  $rowsHtml = ($totals | ForEach-Object { "<tr><td>$($_.Rank)</td><td>$($_.Team)</td><td>$($_.TotalScore)</td><td>$($_.Percentile)%</td></tr>" }) -join "`n"
  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Scoring Summary</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 1.5rem; }
    table { border-collapse: collapse; width: 60%; }
    th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
    th { background: #f2f2f2; }
  </style>
</head>
<body>
  <h1>Scoring Summary</h1>
  <p>Generated: $(Get-Date -Format o)</p>
  <h2>Team Rankings</h2>
  <table>
    <thead><tr><th>Rank</th><th>Team</th><th>Total Score</th><th>Percentile</th></tr></thead>
    <tbody>
      $rowsHtml
    </tbody>
  </table>
  <h2>Statistics</h2>
  <ul>
    <li>Teams: $count</li>
    <li>Average Score: {0:N2}</li>
    <li>Max Score: $maxScore</li>
    <li>Min Score: $minScore</li>
  </ul>
  <h2>Notes</h2>
  <ul>
    <li>Percentile: higher = better (top score = 100%).</li>
    <li>Ties share rank; next rank skips by tie count.</li>
  </ul>
</body>
</html>
"@
  $html -f $avg | Out-File -FilePath $summaryHtml -Encoding UTF8
  Write-Host "Summary generated: $summaryMd, $summaryHtml" -ForegroundColor Green
}

Write-Host "Aggregated rows: $($all.Count)" -ForegroundColor Green
Write-Host "Per-team totals exported: $totalsPath" -ForegroundColor Green
if($IncludeJson){ Write-Host 'JSON files exported.' -ForegroundColor Green }
