# Data Consistency Validation Script (PowerShell)
# Validates that data files are internally consistent and reference valid IDs

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$DataDir = Join-Path $ProjectRoot "data"

Write-Host "=== Harness Engineering Guide - Data Validation ==="
Write-Host ""

$Errors = 0

# Load data files
$stages = Get-Content (Join-Path $DataDir "stages.json") -Raw | ConvertFrom-Json
$profiles = Get-Content (Join-Path $DataDir "profiles.json") -Raw | ConvertFrom-Json
$checklistItems = Get-Content (Join-Path $DataDir "checklist-items.json") -Raw | ConvertFrom-Json

# Build a set of valid item IDs for fast lookup
$validIds = @{}
foreach ($item in $checklistItems.items) {
    $validIds[$item.id] = $true
}

# ===== 1. Validate stages.json references valid item IDs =====
Write-Host "[1/4] Validating stages.json active_items..."

foreach ($stageName in @("bootstrap", "growth", "mature")) {
    Write-Host "  Checking stage: $stageName"
    $activeItems = $stages.stages.$stageName.active_items

    if (-not $activeItems -or $activeItems.Count -eq 0) {
        Write-Host "    ERROR: No active_items found for stage $stageName"
        $Errors++
        continue
    }

    foreach ($itemId in $activeItems) {
        if (-not $validIds.ContainsKey($itemId)) {
            Write-Host "    ERROR: Stage '$stageName' references non-existent item '$itemId'"
            $Errors++
        }
    }
}

if ($Errors -eq 0) {
    Write-Host "  ✓ All stage references are valid"
}
Write-Host ""

# ===== 2. Validate profiles.json skip_items and critical_items =====
Write-Host "[2/4] Validating profiles.json item references..."

$profileNames = $profiles.profiles.PSObject.Properties.Name | Sort-Object

foreach ($profileName in $profileNames) {
    Write-Host "  Checking profile: $profileName"
    $prof = $profiles.profiles.$profileName

    # Check skip_items
    if ($prof.skip_items) {
        foreach ($itemId in $prof.skip_items) {
            if (-not $validIds.ContainsKey($itemId)) {
                Write-Host "    ERROR: Profile '$profileName' skip_items references non-existent item '$itemId'"
                $Errors++
            }
        }
    }

    # Check critical_items
    if ($prof.critical_items) {
        foreach ($itemId in $prof.critical_items) {
            if (-not $validIds.ContainsKey($itemId)) {
                Write-Host "    ERROR: Profile '$profileName' critical_items references non-existent item '$itemId'"
                $Errors++
            }
        }
    }
}

if ($Errors -eq 0) {
    Write-Host "  ✓ All profile references are valid"
}
Write-Host ""

# ===== 3. Validate profile weights sum to 1.0 =====
Write-Host "[3/4] Validating profile weights sum to 1.0..."

foreach ($profileName in $profileNames) {
    $prof = $profiles.profiles.$profileName
    $weights = $prof.weights.PSObject.Properties.Value
    $weightSum = ($weights | Measure-Object -Sum).Sum

    # Allow 0.001 tolerance for floating point
    if ([Math]::Abs($weightSum - 1.0) -gt 0.001) {
        Write-Host "  ERROR: Profile '$profileName' weights sum to $weightSum (expected 1.0)"
        $Errors++
    }
}

if ($Errors -eq 0) {
    Write-Host "  ✓ All profile weights sum to 1.0"
}
Write-Host ""

# ===== 4. Validate Quick Audit has exactly 15 items =====
Write-Host "[4/4] Validating Quick Audit item count..."

$quickCount = ($checklistItems.items | Where-Object { $_.quick_mode -eq $true }).Count

if ($quickCount -ne 15) {
    Write-Host "  ERROR: Quick Audit should have exactly 15 items, found $quickCount"
    $Errors++
} else {
    Write-Host "  ✓ Quick Audit has exactly 15 items"
}
Write-Host ""

# ===== Summary =====
Write-Host "=== Validation Summary ==="
if ($Errors -eq 0) {
    Write-Host "✓ All validation checks passed"
    exit 0
} else {
    Write-Host "✗ Found $Errors error(s)"
    exit 1
}
