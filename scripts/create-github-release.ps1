# Publish a GitHub Release from doc/releases/v<Tag>.md (requires gh CLI + auth).
param(
    [Parameter(Mandatory = $true)]
    [string] $Tag
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ($Tag -notmatch '^v') { $Tag = "v$Tag" }

$notes = Join-Path $root "doc/releases/$Tag.md"
if (-not (Test-Path $notes)) {
    throw "Missing release notes: $notes (create doc/releases/$Tag.md first)"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw 'Install GitHub CLI (gh) and run: gh auth login'
}

gh release view $Tag 2>$null
if ($LASTEXITCODE -eq 0) {
    throw "Release $Tag already exists on GitHub"
}

gh release create $Tag --title $Tag --notes-file $notes
Write-Host "Created release $Tag"
