# Publish a GitHub Release from doc/releases/v<tag>.md (requires gh CLI + auth).
param(
    [Parameter(Mandatory = $true)]
    [string] $Tag
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$notes = Join-Path $root "doc/releases/$Tag.md"
if (-not (Test-Path $notes)) {
    throw "Missing release notes: $notes"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw 'Install GitHub CLI (gh) and run: gh auth login'
}

gh release view $Tag 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Release $Tag already exists. Edit on GitHub or delete first."
    exit 1
}

gh release create $Tag --title $Tag --notes-file $notes
Write-Host "Created https://github.com/songzhendong/skywalking-dart/releases/tag/$Tag"
