<#!
.SYNOPSIS
  Extracts the Challenge Scores table from the coach scoring sheet markdown and exports to CSV.

.DESCRIPTION
  Parses the markdown table under the '## Challenge Scores' heading in
  docs/hackathon/coach-guide/SCORING-SHEET.md (or a custom path) and exports
  a CSV file with columns: Challenge, Criteria, Max, Score, Notes.

  Blank / non‑numeric Score cells are exported as empty. The script ignores
  separator rows (those containing only dashes) and header rows.

.PARAMETER InputPath
  Path to the markdown scoring sheet. Defaults to the repository version.

.PARAMETER OutputPath
  Destination CSV file path. Defaults to ./scoring-results.csv in the working directory.

.PARAMETER Challenge
  Optional filter (e.g. '01', '08'). If set, only that challenge's rows are exported.

.PARAMETER IncludeEmpty
  If supplied, include rows with empty Score. Otherwise rows with no score are still included (since coaches may progressively fill them) – kept for future flexibility.

.EXAMPLE
  ./Export-ScoringSheet.ps1

.EXAMPLE
  ./Export-ScoringSheet.ps1 -Challenge 08 -OutputPath results/score-ch08.csv

.NOTES
  Educational helper – not a full markdown parser. Assumes pipe table format consistent with shipped scoring sheet.
#>
param(
  [string]$InputPath = (Join-Path $PSScriptRoot '..' 'docs' 'hackathon' 'coach-guide' 'SCORING-SHEET.md'),
  [string]$OutputPath = (Join-Path (Get-Location) 'scoring-results.csv'),
  [string]$JsonPath,
  [string]$Challenge,
  [switch]$IncludeEmpty,
  [switch]$IncludeTotals
)

if(-not (Test-Path $InputPath)){
  Write-Error "Input scoring sheet not found: $InputPath"; exit 1
}

$content = Get-Content -Raw -Path $InputPath -ErrorAction Stop

# Locate the Challenge Scores section
$sectionPattern = '(?s)## Challenge Scores(.*?)## Totals'
$match = [regex]::Match($content, $sectionPattern)
if(-not $match.Success){
  Write-Error 'Unable to locate "## Challenge Scores" section.'; exit 1
}

$tableBlock = $match.Groups[1].Value
$lines = $tableBlock -split "`n" | Where-Object { $_.Trim().StartsWith('|') }

if(-not $lines){
  Write-Error 'No table lines detected under Challenge Scores.'; exit 1
}

$headerLine = $lines | Select-Object -First 1
$expectedHeaders = 'Challenge','Criteria','Max','Score','Notes / Evidence Reference'
$headerCols = ($headerLine -split '\|')[1..5].ForEach({ $_.Trim() })

# Basic sanity check – ignore mismatch but warn.
if($headerCols[0] -ne 'Challenge'){
  Write-Warning 'Header line not in expected format; continuing with best-effort parse.'
}

$data = @()
foreach($line in $lines | Select-Object -Skip 2){ # Skip header + separator
  if([string]::IsNullOrWhiteSpace($line)){ continue }
  if($line -match '^\|\s*-+'){ continue }
  $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
  # After split first and last elements may be empty due to leading/trailing pipe
  $cols = $cols | Where-Object { $_ -ne '' -or $cols.Count -eq 0 }
  if($cols.Count -lt 5){ continue }
  $challengeVal = $cols[0]
  if($Challenge -and $challengeVal -ne $Challenge){ continue }
  $scoreRaw = $cols[3]
  $scoreParsed = $null
  if($scoreRaw -match '^[0-9]+$'){ $scoreParsed = [int]$scoreRaw }
  elseif(-not $IncludeEmpty){
    # keep row anyway (coaches want full template); do nothing
  }
  $data += [pscustomobject]@{
    Challenge = $challengeVal
    Criteria  = $cols[1]
    Max       = $cols[2]
    Score     = $scoreParsed
    Notes     = $cols[4]
  }
}

if(-not $data){
  Write-Warning 'No rows parsed – check file contents or filter criteria.'
}

$outDir = Split-Path -Parent $OutputPath
if(-not (Test-Path $outDir)){ New-Item -ItemType Directory -Path $outDir | Out-Null }

if($IncludeTotals){
  # Compute totals by challenge and grand total
  $grouped = $data | Group-Object Challenge
  $totals = foreach($g in $grouped){
    $sum = ($g.Group | Where-Object { $_.Score -ne $null }).Score | Measure-Object -Sum
    [pscustomobject]@{
      Challenge = "$($g.Name) (TOTAL)"
      Criteria  = '—'
      Max       = '—'
      Score     = $sum.Sum
      Notes     = 'Computed total'
    }
  }
  $grand = ($data | Where-Object { $_.Score -ne $null }).Score | Measure-Object -Sum
  $totals += [pscustomobject]@{ Challenge='ALL (GRAND TOTAL)'; Criteria='—'; Max='—'; Score=$grand.Sum; Notes='Aggregate of all scored rows'}
  $export = $data + $totals
  $export | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8
  if($JsonPath){
    $export | ConvertTo-Json -Depth 4 | Out-File -FilePath $JsonPath -Encoding UTF8
  }
} else {
  $data | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8
  if($JsonPath){
    $data | ConvertTo-Json -Depth 4 | Out-File -FilePath $JsonPath -Encoding UTF8
  }
}

Write-Host "Scoring data exported: $OutputPath" -ForegroundColor Green
if($JsonPath){ Write-Host "JSON exported: $JsonPath" -ForegroundColor Green }