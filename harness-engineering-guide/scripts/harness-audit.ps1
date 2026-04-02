# harness-audit.ps1 — Harness engineering audit scanner
# Responsibility: CLI argument parsing, scoring, output formatting (JSON/Markdown/Blueprint).
# All detection logic lives in utils/dimension-scanners.ps1.
#
# Usage: pwsh harness-audit.ps1 [-RepoRoot <path>] [-Quick] [-Profile <type>] [-Stage <stage>]
#        [-Monorepo] [-Output <dir>] [-Format <fmt>] [-Blueprint] [-Persist]
param(
    [string]$RepoRoot = ".",
    [switch]$Quick,
    [string]$Profile = "",
    [string]$Stage = "",
    [switch]$Monorepo,
    [string]$Output = "",
    [string]$Format = "json",
    [switch]$Blueprint,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir/utils/dimension-scanners.ps1"

Push-Location $RepoRoot
$RepoAbs = (Get-Location).Path
$Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

# ===== Run all dimension scans =====
$scanDims = Invoke-AllScans

# ===== Quick Assessment =====
$score = 0
if (@($script:agentFiles).Count -gt 0) { $score++ }
if (@($script:ciConfigs).Count -gt 0) { $score++ }
if (@($script:linterConfigs).Count -gt 0) { $score++ }
if (@($script:typeConfigs).Count -gt 0) { $score++ }
if (@($script:testDirs).Count -gt 0) { $score++ }
if ($script:docsExists) { $score++ }

$quickAssessment = if ($score -ge 5) {
    "Good foundation - proceed to detailed audit"
} elseif ($score -ge 3) {
    "Partial harness - significant gaps likely"
} else {
    "Minimal harness - expect low scores across most dimensions"
}

$auditMode = if ($Quick) { "quick" } else { "full" }

# ===== JSON Output =====
$scanData = [ordered]@{
    repo_root     = $RepoAbs
    timestamp     = $Timestamp
    ecosystem     = $scanDims.ecosystem
    audit_mode    = $auditMode
    profile       = if ($Profile) { $Profile } else { "auto" }
    stage         = if ($Stage) { $Stage } else { "auto" }
    monorepo_mode = [bool]$Monorepo
    dimensions    = [ordered]@{
        "1_architecture_docs"     = $scanDims["1_architecture_docs"]
        "2_mechanical_constraints" = $scanDims["2_mechanical_constraints"]
        "3_observability"          = $scanDims["3_observability"]
        "4_testing"                = $scanDims["4_testing"]
        "5_context_engineering"    = $scanDims["5_context_engineering"]
        "6_entropy_management"     = $scanDims["6_entropy_management"]
        "7_long_running"           = $scanDims["7_long_running"]
        "8_safety"                 = $scanDims["8_safety"]
    }
    monorepo      = $scanDims.monorepo
    summary       = [ordered]@{
        agent_files_count      = @($script:agentFiles).Count
        ci_configs_count       = @($script:ciConfigs).Count
        linter_configs_count   = @($script:linterConfigs).Count
        formatter_configs_count = @($script:formatterConfigs).Count
        type_configs_count     = @($script:typeConfigs).Count
        has_precommit          = $script:hasPrecommit
        test_dirs_count        = @($script:testDirs).Count
        test_files_count       = $script:testFilesCount
        has_feature_tracker    = $script:hasFeatureTracker
        has_secret_scanning    = $script:hasSecretScanning
        has_mcp_config         = $script:hasMcpConfig
        quick_assessment       = $quickAssessment
    }
}

Pop-Location

if ($Persist) { $Blueprint = [switch]::new($true) }
if ($Blueprint) { $Format = "markdown" }

# ===== Gap Analysis =====
function Get-Gaps {
    $gaps = @()
    if (@($script:agentFiles).Count -eq 0) { $gaps += "NO_AGENT_FILE" }
    if (-not $script:docsExists) { $gaps += "NO_DOCS_DIR" }
    if (-not $script:docsHasArch) { $gaps += "NO_ARCHITECTURE_DOC" }
    if (-not $script:hasDesignDocs) { $gaps += "NO_DESIGN_DOCS" }
    if (@($script:ciConfigs).Count -eq 0) { $gaps += "NO_CI_PIPELINE" }
    if (@($script:linterConfigs).Count -eq 0) { $gaps += "NO_LINTER" }
    if (@($script:typeConfigs).Count -eq 0) { $gaps += "NO_TYPE_CHECKER" }
    if (@($script:testDirs).Count -eq 0) { $gaps += "NO_TESTS" }
    if (-not $script:hasQualityScore) { $gaps += "NO_TECH_DEBT_TRACKING" }
    if (-not $script:hasInitScript) { $gaps += "NO_ENV_RECOVERY" }
    if (-not $script:hasProgressTracking) { $gaps += "NO_PROGRESS_TRACKING" }
    if (-not $script:hasCodeowners) { $gaps += "NO_CODEOWNERS" }
    return $gaps
}

function Get-StatusText([bool]$val) { if ($val) { "PASS" } else { "FAIL" } }
function Get-ExistsText([bool]$val) { if ($val) { "exists" } else { "missing" } }
function Get-InfoText([bool]$val) { if ($val) { "PASS" } else { "INFO" } }

# ===== Markdown Report =====
function Format-Markdown {
    $repoName = Split-Path $RepoAbs -Leaf
    $afCount = @($script:agentFiles).Count
    $ciCount = @($script:ciConfigs).Count
    $lcCount = @($script:linterConfigs).Count
    $fcCount = @($script:formatterConfigs).Count
    $tcCount = @($script:typeConfigs).Count
    $tdCount = @($script:testDirs).Count
    $tfCount = $script:testFilesCount

    $modeLabel = if ($Quick) { "Quick Audit (15 vital-sign items)" } else { "Full Audit" }
    $titlePrefix = if ($Quick) { "Quick Harness Audit" } else { "Harness Audit" }
    $precommitDetail = if ($script:hasPrecommit) { $script:precommitTools -join ", " } else { "none" }
    $featureDetail = if ($script:hasFeatureTracker) { "exists" } else { "none" }
    $secretDetail = if ($script:hasSecretScanning) { $script:secretScanningTools -join ", " } else { "none" }
    $mcpDetail = if ($script:hasMcpConfig) { $script:mcpConfigFiles -join ", " } else { "none" }
    $md = @"
# ${titlePrefix}: $repoName

**Date**: $Timestamp
**Mode**: $modeLabel
**Profile**: $(if ($Profile) { $Profile } else { "auto" }) | **Stage**: $(if ($Stage) { $Stage } else { "auto" }) | **Ecosystem**: $($script:ecosystem)
**Assessment**: $quickAssessment

## Scan Results

| Dimension | Finding | Status |
|-----------|---------|--------|
| Agent instruction files | $afCount found | $(Get-StatusText ($afCount -gt 0)) |
| docs/ directory | $(Get-ExistsText $script:docsExists) | $(Get-StatusText $script:docsExists) |
| ARCHITECTURE.md | $(Get-ExistsText $script:docsHasArch) | $(Get-StatusText $script:docsHasArch) |
| CI configs | $ciCount found | $(Get-StatusText ($ciCount -gt 0)) |
| Linter configs | $lcCount found | $(Get-StatusText ($lcCount -gt 0)) |
| Formatter configs | $fcCount found | $(Get-StatusText ($fcCount -gt 0)) |
| Type checker configs | $tcCount found | $(Get-StatusText ($tcCount -gt 0)) |
| Pre-commit hooks | $precommitDetail | $(Get-InfoText $script:hasPrecommit) |
| Test directories | $tdCount found ($tfCount test files) | $(Get-StatusText ($tdCount -gt 0)) |
| Feature tracker | $featureDetail | $(Get-InfoText $script:hasFeatureTracker) |
| Tech debt tracking | $(Get-ExistsText $script:hasQualityScore) | $(Get-StatusText $script:hasQualityScore) |
| Environment recovery | $(Get-ExistsText $script:hasInitScript) | $(Get-StatusText $script:hasInitScript) |
| Progress tracking | $(Get-ExistsText $script:hasProgressTracking) | $(Get-StatusText $script:hasProgressTracking) |
| CODEOWNERS | $(Get-ExistsText $script:hasCodeowners) | $(Get-StatusText $script:hasCodeowners) |
| Secret scanning | $secretDetail | $(Get-InfoText $script:hasSecretScanning) |
| MCP config | $mcpDetail | $(Get-InfoText $script:hasMcpConfig) |

## Detected Files

**Agent files**: $(if ($afCount -gt 0) { ($script:agentFiles -join ", ") } else { "none" })
**CI configs**: $(if ($ciCount -gt 0) { ($script:ciConfigs -join ", ") } else { "none" })
**Linter configs**: $(if ($lcCount -gt 0) { ($script:linterConfigs -join ", ") } else { "none" })
**Formatter configs**: $(if ($fcCount -gt 0) { ($script:formatterConfigs -join ", ") } else { "none" })
**Type configs**: $(if ($tcCount -gt 0) { ($script:typeConfigs -join ", ") } else { "none" })
**Test dirs**: $(if ($tdCount -gt 0) { ($script:testDirs -join ", ") } else { "none" })
"@
    return $md
}

# ===== Blueprint Report =====
function Format-Blueprint {
    $md = Format-Markdown
    $gaps = Get-Gaps

    $md += "`n`n---`n`n## Gap Analysis & Recommendations`n"

    $gapDetails = @{
        "NO_AGENT_FILE" = @"

### Missing: Agent Instruction File (Dim 1)
- **Impact**: Agents have no project-specific guidance — they guess at conventions
- **Fix**: Create AGENTS.md using ``templates/universal/agents-md-scaffold.md``
- **Effort**: 30 min | **Priority**: HIGH
"@
        "NO_DOCS_DIR" = @"

### Missing: Structured docs/ Directory (Dim 1)
- **Impact**: No organized knowledge base for agents to reference
- **Fix**: Create ``docs/`` with an ``index.md`` and at least architecture + conventions subdocs
- **Effort**: 1-2 hours | **Priority**: MEDIUM
"@
        "NO_ARCHITECTURE_DOC" = @"

### Missing: Architecture Documentation (Dim 1)
- **Impact**: Agents cannot understand domain boundaries or dependency rules
- **Fix**: Create ``ARCHITECTURE.md`` with module boundaries, dependency directions, and key abstractions
- **Effort**: 1-2 hours | **Priority**: HIGH
"@
        "NO_CI_PIPELINE" = @"

### Missing: CI Pipeline (Dim 2)
- **Impact**: No mechanical enforcement — agents can merge broken code
- **Fix**: Add CI using ``templates/ci/github-actions/standard-pipeline.yml``
- **Effort**: 1 hour | **Priority**: CRITICAL
"@
        "NO_LINTER" = @"

### Missing: Linter Configuration (Dim 2)
- **Impact**: No style or correctness enforcement on agent-generated code
- **Fix**: Add linter config for your ecosystem (see ``data/ecosystems.json``)
- **Effort**: 30 min | **Priority**: CRITICAL
"@
        "NO_TYPE_CHECKER" = @"

### Missing: Type Checker (Dim 2)
- **Impact**: Agent can produce type-unsafe code that passes CI
- **Fix**: Add type checking in strict mode (see ``data/ecosystems.json``)
- **Effort**: 1 hour | **Priority**: CRITICAL
"@
        "NO_TESTS" = @"

### Missing: Test Suite (Dim 4)
- **Impact**: No regression detection — agent changes may silently break features
- **Fix**: Create test directory and add initial tests for core modules
- **Effort**: 2-4 hours | **Priority**: CRITICAL
"@
        "NO_TECH_DEBT_TRACKING" = @"

### Missing: Tech Debt Tracking (Dim 6)
- **Impact**: Quality degradation invisible until crisis
- **Fix**: Add ``templates/universal/tech-debt-tracker.json`` to track quality scores
- **Effort**: 15 min | **Priority**: LOW
"@
        "NO_ENV_RECOVERY" = @"

### Missing: Environment Recovery Script (Dim 7)
- **Impact**: Agents cannot reliably bootstrap development environment
- **Fix**: Create init script using ``templates/init/init.sh`` or ``init.ps1``
- **Effort**: 30 min | **Priority**: MEDIUM
"@
        "NO_PROGRESS_TRACKING" = @"

### Missing: Progress Tracking (Dim 7)
- **Impact**: No structured handoff between agent sessions
- **Fix**: Add execution plan template from ``templates/universal/execution-plan.md``
- **Effort**: 15 min | **Priority**: LOW
"@
        "NO_CODEOWNERS" = @"

### Missing: CODEOWNERS (Dim 8)
- **Impact**: No enforced review for security-critical paths
- **Fix**: Create ``.github/CODEOWNERS`` mapping critical paths to reviewers
- **Effort**: 15 min | **Priority**: MEDIUM
"@
    }

    foreach ($gap in $gaps) {
        if ($gapDetails.ContainsKey($gap)) { $md += $gapDetails[$gap] }
    }

    $md += "`n## Quick Wins (implement today)`n`n"
    $winNum = 1
    $criticalGaps = @("NO_AGENT_FILE", "NO_CI_PIPELINE", "NO_LINTER", "NO_TYPE_CHECKER", "NO_TESTS")
    $winLabels = @{
        "NO_AGENT_FILE" = "Create AGENTS.md from scaffold template"
        "NO_CI_PIPELINE" = "Add CI pipeline from templates/ci/"
        "NO_LINTER" = "Add linter config for $($script:ecosystem) ecosystem"
        "NO_TYPE_CHECKER" = "Enable type checking in strict mode"
        "NO_TESTS" = "Create initial test suite with CI integration"
    }
    foreach ($gap in $gaps) {
        if ($criticalGaps -contains $gap) {
            $md += "$winNum. $($winLabels[$gap])`n"
            $winNum++
        }
    }
    if ($winNum -eq 1) { $md += "No critical gaps found — focus on deepening existing checks.`n" }

    $md += @"

## Recommended Templates

| Gap | Template Path |
|-----|---------------|
"@
    $templateMap = @{
        "NO_AGENT_FILE" = "| Agent instruction file | ``templates/universal/agents-md-scaffold.md`` |"
        "NO_CI_PIPELINE" = "| CI pipeline (GitHub) | ``templates/ci/github-actions/standard-pipeline.yml`` |"
        "NO_TECH_DEBT_TRACKING" = "| Tech debt tracker | ``templates/universal/tech-debt-tracker.json`` |"
        "NO_ENV_RECOVERY" = "| Environment recovery | ``templates/init/init.sh`` / ``templates/init/init.ps1`` |"
        "NO_PROGRESS_TRACKING" = "| Task decomposition | ``templates/universal/execution-plan.md`` |"
    }
    foreach ($gap in $gaps) {
        if ($templateMap.ContainsKey($gap)) { $md += "`n$($templateMap[$gap])" }
    }

    $md += "`n`n## Ecosystem CI Commands ($($script:ecosystem))`n`n"
    $md += "Populate your CI pipeline with these commands (from ``data/ecosystems.json``):`n`n"

    $ciCmds = @{
        "node" = @"
| Step | Command |
|------|---------|
| Install | ``npm ci --silent`` |
| Lint | ``npx eslint . && npx biome check .`` |
| Typecheck | ``npx tsc --noEmit`` |
| Test | ``npx vitest run --coverage`` |
| Build | ``npm run build`` |
| Format check | ``npx biome format --check . || npx prettier --check .`` |
"@
        "python" = @"
| Step | Command |
|------|---------|
| Install | ``pip install -e '.[dev]' || pip install -r requirements.txt`` |
| Lint | ``ruff check .`` |
| Typecheck | ``mypy src/`` |
| Test | ``pytest --cov=src --cov-fail-under=80`` |
| Format check | ``ruff format --check .`` |
"@
        "go" = @"
| Step | Command |
|------|---------|
| Install | ``go mod download`` |
| Lint | ``golangci-lint run`` |
| Typecheck | ``go vet ./...`` |
| Test | ``go test -race -coverprofile=coverage.out ./...`` |
| Build | ``go build ./...`` |
| Format check | ``gofmt -l . | (! grep .)`` |
"@
        "rust" = @"
| Step | Command |
|------|---------|
| Install | ``cargo fetch`` |
| Lint | ``cargo clippy -- -D warnings`` |
| Typecheck | ``cargo check`` |
| Test | ``cargo test`` |
| Build | ``cargo build --release`` |
| Format check | ``cargo fmt --check`` |
"@
    }

    if ($ciCmds.ContainsKey($script:ecosystem)) {
        $md += $ciCmds[$script:ecosystem]
    } else {
        $md += "See ``data/ecosystems.json`` for $($script:ecosystem)-specific commands.`n"
    }

    $md += @"

---

*Blueprint generated by harness-audit.ps1. For full scoring, run the agent-led audit (Mode 1 in SKILL.md). Use -Quick for a 15-item vital-sign check.*
*Profile and stage weight tables are in ``data/profiles.json`` and ``data/stages.json``.*
"@

    return $md
}

# ===== Write Output =====
$repoName = Split-Path $RepoAbs -Leaf
$dateStr = Get-Date -Format "yyyy-MM-dd"

if ($Blueprint) {
    $finalOutput = Format-Blueprint
} elseif ($Format -eq "markdown") {
    $finalOutput = Format-Markdown
} else {
    $finalOutput = $scanData | ConvertTo-Json -Depth 10
}

if ($Persist) {
    $harnessDir = Join-Path $RepoAbs "harness-system"
    New-Item -ItemType Directory -Path $harnessDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $harnessDir "modules") -Force | Out-Null
    $finalOutput | Out-File (Join-Path $harnessDir "MASTER.md") -Encoding utf8
    Write-Host "Harness blueprint persisted to $harnessDir/MASTER.md"
    Write-Host "Add module overrides in $harnessDir/modules/ (e.g. ci.md, testing.md)"
} elseif ($Output) {
    New-Item -ItemType Directory -Path $Output -Force | Out-Null
    if ($Format -eq "markdown" -or $Blueprint) {
        $ext = "md"
        if ($Blueprint) { $suffix = "blueprint" }
        elseif ($Quick) { $suffix = "quick-audit" }
        else { $suffix = "audit" }
    } else {
        $ext = "json"
        $suffix = if ($Quick) { "quick-audit" } else { "audit" }
    }
    $filename = "${dateStr}_${repoName}_${suffix}.${ext}"
    $finalOutput | Out-File "$Output/$filename" -Encoding utf8
    Write-Host "Output written to $Output/$filename"
} else {
    $finalOutput
}
