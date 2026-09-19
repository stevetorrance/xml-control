<#
.SYNOPSIS
    Copies demo files from sibling product repos into this Pages site.

.DESCRIPTION
    The site publishes generated artefacts (help pages, sample PDFs) that live in
    other repos. This script refreshes the copies under the site's demos folders so
    the published versions match the current source. Re-run it before pushing.

    Everything it writes lives in a 'demos' folder and is owned by this script --
    do not hand-edit those copies, edit the source and re-sync.

.PARAMETER SourceRoot
    Folder containing the sibling repos. Defaults to the parent of this repo.

.PARAMETER WhatIf
    Show what would be copied without writing anything.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceRoot
)

$ErrorActionPreference = 'Stop'

$siteRoot = Split-Path -Parent $PSScriptRoot
if (-not $SourceRoot) { $SourceRoot = Split-Path -Parent $siteRoot }

# Source path (relative to SourceRoot) -> destination path (relative to siteRoot).
# Add a line here when a new demo artefact needs publishing.
$items = @(
    @{
        From = 'ControlCircuit\ControlCircuit\HelpSystem\controlcircuit-onboarding.html'
        To   = 'control-circuit-2026\demos\controlcircuit-onboarding.html'
    }
    # Sample PDF output -- fill in once the export path is known, e.g.
    # @{ From = 'ControlCircuit\...\sample-schematic.pdf'
    #    To   = 'control-circuit-2026\demos\sample-schematic.pdf' }
)

$copied = 0
$missing = @()

foreach ($item in $items) {
    $from = Join-Path $SourceRoot $item.From
    $to = Join-Path $siteRoot $item.To

    if (-not (Test-Path -LiteralPath $from)) {
        $missing += $item.From
        Write-Warning "Source not found, skipping: $from"
        continue
    }

    $destDir = Split-Path -Parent $to
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $srcInfo = Get-Item -LiteralPath $from
    $unchanged = $false
    if (Test-Path -LiteralPath $to) {
        $dstInfo = Get-Item -LiteralPath $to
        $unchanged = ($srcInfo.Length -eq $dstInfo.Length) -and
                     ($srcInfo.LastWriteTimeUtc -le $dstInfo.LastWriteTimeUtc)
    }

    if ($unchanged) {
        Write-Host "  up to date  $($item.To)"
        continue
    }

    if ($PSCmdlet.ShouldProcess($item.To, 'Copy')) {
        Copy-Item -LiteralPath $from -Destination $to -Force
        $kb = [math]::Round($srcInfo.Length / 1KB)
        Write-Host "  copied      $($item.To)  ($kb KB)"
        $copied++
    }
}

Write-Host ''
Write-Host "Synced $copied file(s) from $SourceRoot"
if ($missing.Count -gt 0) {
    Write-Host "$($missing.Count) source file(s) missing -- see warnings above."
}
Write-Host 'Review with the local preview, then commit and push when ready.'
