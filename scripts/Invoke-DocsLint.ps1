<#$
.SYNOPSIS
  Lightweight documentation linter for SAIF hackathon challenge files.
.DESCRIPTION
  Validates presence of required sections in student challenge Markdown files and checks for links to consolidated quality checklist.
.PARAMETER Path
  Optional root path (defaults to repo docs/hackathon/student-guide).
.EXAMPLE
  ./Invoke-DocsLint.ps1
.EXAMPLE
  ./Invoke-DocsLint.ps1 -Path ../docs/hackathon/student-guide
.NOTES
  Educational tool – not an exhaustive Markdown linter.
#>
param(
  [string]$Path = "$(Join-Path $PSScriptRoot '..' 'docs' 'hackathon' 'student-guide')"
)

$requiredSections = @(
  'Objective',
  'Scenario',
  'Instructions',
  'Success Criteria',
  'Scoring Rubric',
  'Quality Checklist',
  'Submission Artifacts'
)

$qualityLinkPattern = 'QUALITY-CHECKLIST'

$files = Get-ChildItem -Path $Path -Filter 'Challenge-*.md' -File | Sort-Object Name
if(-not $files){
  Write-Host "No challenge files found at $Path" -ForegroundColor Yellow
  exit 0
}

$errors = @()
foreach($file in $files){
  $content = Get-Content -Raw -Path $file.FullName
  $missing = @()
  foreach($section in $requiredSections){
    if($content -notmatch "##\s+$([regex]::Escape($section))"){
      $missing += $section
    }
  }
  if($content -notmatch $qualityLinkPattern){
    $missing += 'Quality Checklist Link'
  }
  if($missing.Count -gt 0){
    $errors += [pscustomobject]@{ File=$file.Name; Missing= ($missing -join ', ') }
  }
}

if($errors.Count -eq 0){
  Write-Host "Documentation lint passed." -ForegroundColor Green
  exit 0
}

Write-Host "Documentation lint found issues:" -ForegroundColor Red
$errors | Format-Table -AutoSize
exit 1
