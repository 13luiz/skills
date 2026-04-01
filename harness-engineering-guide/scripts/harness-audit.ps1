# harness-audit.ps1 — Enhanced harness engineering audit scanner
# Usage: pwsh harness-audit.ps1 [-RepoRoot <path>] [-Profile <type>] [-Stage <stage>] [-Monorepo] [-Output <dir>] [-Format <fmt>] [-Blueprint]
# Options:
#   -Profile <type>    Project type profile (see data/profiles.json)
#   -Stage <stage>     Lifecycle stage: bootstrap | growth | mature
#   -Monorepo          Enable monorepo per-package scanning
#   -Output <dir>      Output directory for reports
#   -Format <fmt>      Output format: json (default) | markdown
#   -Blueprint         Generate actionable blueprint with gap analysis and template recommendations
#   -Persist           Generate blueprint and save to harness-system/MASTER.md in the repo
param(
    [string]$RepoRoot = ".",
    [string]$Profile = "",
    [string]$Stage = "",
    [switch]$Monorepo,
    [string]$Output = "",
    [string]$Format = "json",
    [switch]$Blueprint,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"
Push-Location $RepoRoot
$RepoAbs = (Get-Location).Path
$Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

function Find-FilesRecursive {
    param([string[]]$Names, [int]$Depth = 4)
    $results = @()
    foreach ($name in $Names) {
        Get-ChildItem -Path . -Filter $name -Recurse -Depth $Depth -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
            ForEach-Object { $results += $_.FullName.Replace((Get-Location).Path + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/') }
    }
    return $results | Sort-Object -Unique
}

function Find-DirsRecursive {
    param([string[]]$Names, [int]$Depth = 4)
    $results = @()
    foreach ($name in $Names) {
        Get-ChildItem -Path . -Directory -Filter $name -Recurse -Depth $Depth -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
            ForEach-Object { $results += $_.FullName.Replace((Get-Location).Path + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/') }
    }
    return $results | Sort-Object -Unique
}

function Test-FileContains {
    param([string]$Path, [string]$Pattern)
    if (Test-Path $Path) {
        return (Select-String -Path $Path -Pattern $Pattern -Quiet -ErrorAction SilentlyContinue) -eq $true
    }
    return $false
}

function Count-GrepFiles {
    param([string]$Pattern, [string[]]$Include, [string]$SearchPath = ".")
    $count = 0
    foreach ($inc in $Include) {
        $files = Get-ChildItem -Path $SearchPath -Filter $inc -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]|[\\/]node_modules[\\/]|[\\/]vendor[\\/]|[\\/]\.venv[\\/]' }
        foreach ($f in $files) {
            if (Select-String -Path $f.FullName -Pattern $Pattern -Quiet -ErrorAction SilentlyContinue) {
                $count++
                if ($count -ge 20) { return $count }
            }
        }
    }
    return $count
}

# --- Dimension 1: Agent Instruction Files ---
$agentFiles = Find-FilesRecursive -Names @("AGENTS.md", "CLAUDE.md", "CODEX.md", ".cursorrules")
$cursorRules = Get-ChildItem -Path . -Filter "*.md" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '[\\/]\.cursor[\\/]rules[\\/]' -and $_.FullName -notmatch '[\\/]\.git[\\/]' } |
    ForEach-Object { $_.FullName.Replace((Get-Location).Path + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/') }
if ($cursorRules) { $agentFiles = @($agentFiles) + @($cursorRules) | Sort-Object -Unique }

# --- Dimension 1: Docs Structure ---
$docsExists = Test-Path "docs" -PathType Container
$docsHasIndex = (Test-Path "docs/index.md") -or (Test-Path "docs/INDEX.md") -or (Test-Path "docs/README.md")
$docsHasArch = (Test-Path "docs/ARCHITECTURE.md") -or (Test-Path "ARCHITECTURE.md")
$hasDesignDocs = (Test-Path "docs/design-docs") -or (Test-Path "docs/adr") -or
    (Test-Path "docs/adrs") -or (Test-Path "docs/decisions") -or (Test-Path "docs/exec-plans")

# --- Dimension 2: CI Configs ---
$ciConfigs = @()
if (Test-Path ".github/workflows") {
    Get-ChildItem ".github/workflows" -Include @("*.yml", "*.yaml") -ErrorAction SilentlyContinue |
        ForEach-Object { $ciConfigs += ".github/workflows/$($_.Name)" }
}
foreach ($f in @(".gitlab-ci.yml", "Jenkinsfile", "azure-pipelines.yml")) {
    if (Test-Path $f) { $ciConfigs += $f }
}
if (Test-Path ".circleci/config.yml") { $ciConfigs += ".circleci/config.yml" }

# --- Dimension 2: Linter/Formatter Configs ---
$linterNames = @(
    ".eslintrc", ".eslintrc.js", ".eslintrc.json", ".eslintrc.yml",
    "eslint.config.js", "eslint.config.mjs",
    ".prettierrc", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js",
    "biome.json", "biome.jsonc",
    "ruff.toml", ".flake8", ".pylintrc",
    ".golangci.yml", ".golangci.yaml",
    "clippy.toml", ".clippy.toml",
    ".rubocop.yml", "checkstyle.xml", ".swiftlint.yml",
    "analysis_options.yaml", "detekt.yml",
    ".editorconfig"
)
$linterConfigs = Find-FilesRecursive -Names $linterNames

# --- Dimension 2: Type Checking ---
$typeNames = @("tsconfig.json", "mypy.ini", ".mypy.ini", "pyrightconfig.json")
$typeConfigs = Find-FilesRecursive -Names $typeNames
if ((Test-Path "pyproject.toml") -and (Test-FileContains "pyproject.toml" "\[tool\.mypy\]|\[tool\.pyright\]")) {
    $typeConfigs = @($typeConfigs) + @("pyproject.toml (type config)")
}

# --- Dimension 4: Test Directories ---
$testDirs = Find-DirsRecursive -Names @("tests", "__tests__", "test", "spec")
$testFilesCount = (Get-ChildItem -Path . -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and ($_.Name -match '\.(test|spec)\.' -or $_.Name -match '(_test\.|test_)') } |
    Measure-Object).Count

# --- Dimension 6: Quality Tracking ---
$hasQualityScore = (Test-Path "QUALITY_SCORE.md") -or (Test-Path "quality-score.md") -or
    (Test-Path "tech-debt-tracker.json") -or (Test-Path "docs/QUALITY_SCORE.md")

# --- Dimension 7: Long-Running Support ---
$hasInitScript = (Test-Path "init.sh") -or (Test-Path "setup.sh") -or
    (Test-Path "Makefile") -or (Test-Path "docker-compose.yml") -or
    (Test-Path "docker-compose.yaml") -or (Test-Path "devcontainer.json") -or
    (Test-Path ".devcontainer")
$hasProgressTracking = (Test-Path "progress.txt") -or (Test-Path "progress.md") -or
    (Test-Path "progress.json") -or (Test-Path "exec-plans") -or (Test-Path "docs/exec-plans")

# --- Dimension 8: Safety ---
$hasCodeowners = (Test-Path "CODEOWNERS") -or (Test-Path ".github/CODEOWNERS") -or (Test-Path "docs/CODEOWNERS")

# --- Ecosystem Detection ---
$ecosystem = "unknown"
$ecosystemsDetected = @()
if (Test-Path "package.json") { $ecosystem = "node"; $ecosystemsDetected += "node" }
if ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt") -or (Test-Path "setup.py") -or (Test-Path "Pipfile")) {
    $ecosystem = "python"; $ecosystemsDetected += "python"
}
if (Test-Path "go.mod") { $ecosystem = "go"; $ecosystemsDetected += "go" }
if (Test-Path "Cargo.toml") { $ecosystem = "rust"; $ecosystemsDetected += "rust" }
if (Test-Path "Gemfile") { $ecosystem = "ruby"; $ecosystemsDetected += "ruby" }
if ((Test-Path "pom.xml") -or (Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) { $ecosystemsDetected += "java" }
if (Test-Path "Package.swift") { $ecosystemsDetected += "swift" }
if (Test-Path "pubspec.yaml") { $ecosystem = "dart"; $ecosystemsDetected += "dart" }

# --- Content Analysis: Dim 3 ---
$srcIncludes = @("*.ts", "*.js", "*.py", "*.go", "*.rs", "*.java", "*.kt", "*.cs", "*.rb")
$loggingFrameworkFiles = Count-GrepFiles -Pattern "winston|pino|bunyan|loguru|structlog|import logging|go\.uber\.org/zap|logrus|zerolog|log/slog|tracing::|Serilog|NLog|Rails\.logger" -Include $srcIncludes
$printOnlyFiles = 0
if ($loggingFrameworkFiles -eq 0) {
    $printOnlyFiles = Count-GrepFiles -Pattern "console\.(log|error|warn)|print\(|fmt\.Print|println!|System\.out\.print" -Include $srcIncludes
}
$otelFiles = Count-GrepFiles -Pattern "opentelemetry|@opentelemetry|go\.opentelemetry\.io|OpenTelemetry" -Include ($srcIncludes + @("*.json", "*.toml", "*.yaml", "*.yml"))
$metricsFiles = Count-GrepFiles -Pattern "prometheus|prom-client|prometheus_client|micrometer|Prometheus\.NET" -Include ($srcIncludes + @("*.json", "*.toml"))
$e2eDepFiles = Count-GrepFiles -Pattern "playwright|puppeteer|cypress|chromedp|selenium|capybara" -Include @("*.json", "*.toml", "*.txt", "*.cfg")
$customErrorFiles = Count-GrepFiles -Pattern "class \w+Error|new Error\(|raise \w+Error|errors\.New|anyhow!|thiserror" -Include $srcIncludes
$genericCatchFiles = Count-GrepFiles -Pattern "catch\s*\(\s*\)|except:|except Exception|recover\(\)" -Include $srcIncludes

# --- Content Analysis: Dim 5 ---
$agentFileQuality = @{ file = ""; line_count = 0; doc_links = 0; command_refs = 0 }
foreach ($af in @("AGENTS.md", "CLAUDE.md", "CODEX.md")) {
    if (Test-Path $af) {
        $content = Get-Content $af -ErrorAction SilentlyContinue
        $agentFileQuality.file = $af
        $agentFileQuality.line_count = $content.Count
        $agentFileQuality.doc_links = ($content | Select-String -Pattern '\[.*\]\(.*\)|see |refer to |docs/' -AllMatches).Count
        $agentFileQuality.command_refs = ($content | Select-String -Pattern '```|npm |yarn |pnpm |pip |cargo |go |make |docker' -AllMatches).Count
        break
    }
}
$docsStructure = @{ exists = $docsExists; has_index = $docsHasIndex; subdirs = 0; total_files = 0 }
if ($docsExists) {
    $docsStructure.subdirs = (Get-ChildItem "docs" -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    $docsStructure.total_files = (Get-ChildItem "docs" -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
}
$hasLlmsTxt = Test-Path "llms.txt"
$hasLlmsFullTxt = Test-Path "llms-full.txt"
$stateFiles = @()
foreach ($sf in @("progress.json", "features.json", "feature-checklist.json", "progress.txt", "progress.md")) {
    if (Test-Path $sf) { $stateFiles += $sf }
}
$artifactDirs = @()
foreach ($ad in @("reports", "artifacts", "output", ".artifacts")) {
    if (Test-Path $ad -PathType Container) { $artifactDirs += $ad }
}

# --- Content Analysis: Dim 6 ---
$principleRefs = 0
foreach ($pf in @("AGENTS.md", "CLAUDE.md", "CODEX.md", "docs/PRINCIPLES.md", "docs/CONVENTIONS.md")) {
    if (Test-Path $pf) {
        $principleRefs += (Select-String -Path $pf -Pattern "principle|golden rule|convention|guideline|must always|never do|prefer .* over" -AllMatches -ErrorAction SilentlyContinue).Count
    }
}
$todoFiles = Count-GrepFiles -Pattern "TODO|todo:" -Include $srcIncludes
$fixmeFiles = Count-GrepFiles -Pattern "FIXME|fixme:" -Include $srcIncludes
$hackFiles = Count-GrepFiles -Pattern "HACK|WORKAROUND|XXX" -Include $srcIncludes
$hasTracker = $hasQualityScore
$trackerHasContent = $false
foreach ($tf in @("tech-debt-tracker.json", "QUALITY_SCORE.md", "quality-score.md", "docs/QUALITY_SCORE.md")) {
    if (Test-Path $tf) {
        $trackerHasContent = (Get-Item $tf).Length -gt 50
        break
    }
}
$hasDeadCodeRules = $false
$hasDuplicateRules = $false
foreach ($cfg in @(".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js", "biome.json", "ruff.toml", "pyproject.toml", ".golangci.yml", ".golangci.yaml")) {
    if (Test-Path $cfg) {
        if (Test-FileContains $cfg "no-unused|dead.code|unused|F401|F811") { $hasDeadCodeRules = $true }
        if (Test-FileContains $cfg "no-duplicate|duplicate|similar|clone") { $hasDuplicateRules = $true }
    }
}

# --- Monorepo Detection ---
$isMonorepo = $false
$monorepoType = "none"
$monorepoPackages = @()
if (Test-Path "pnpm-workspace.yaml") { $isMonorepo = $true; $monorepoType = "pnpm" }
elseif (Test-Path "lerna.json") { $isMonorepo = $true; $monorepoType = "lerna" }
elseif (Test-Path "nx.json") { $isMonorepo = $true; $monorepoType = "nx" }
elseif (Test-Path "turbo.json") { $isMonorepo = $true; $monorepoType = "turborepo" }
elseif ((Test-Path "package.json") -and (Test-FileContains "package.json" '"workspaces"')) {
    $isMonorepo = $true; $monorepoType = "npm-workspaces"
}
elseif ((Test-Path "Cargo.toml") -and (Test-FileContains "Cargo.toml" '\[workspace\]')) {
    $isMonorepo = $true; $monorepoType = "cargo-workspace"
}
elseif (Test-Path "go.work") { $isMonorepo = $true; $monorepoType = "go-workspace" }

if ($isMonorepo) {
    foreach ($pdir in @("packages", "apps", "libs", "services", "modules", "crates", "internal", "cmd")) {
        if (Test-Path $pdir -PathType Container) {
            Get-ChildItem $pdir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $monorepoPackages += $_.Name }
        }
    }
}

# --- Quick Assessment ---
$score = 0
if (@($agentFiles).Count -gt 0) { $score++ }
if (@($ciConfigs).Count -gt 0) { $score++ }
if (@($linterConfigs).Count -gt 0) { $score++ }
if (@($typeConfigs).Count -gt 0) { $score++ }
if (@($testDirs).Count -gt 0) { $score++ }
if ($docsExists) { $score++ }

$quickAssessment = switch ($true) {
    ($score -ge 5) { "Good foundation - proceed to detailed audit" }
    ($score -ge 3) { "Partial harness - significant gaps likely" }
    default { "Minimal harness - expect low scores across most dimensions" }
}

# --- Build Output ---
$scanData = [ordered]@{
    repo_root            = $RepoAbs
    timestamp            = $Timestamp
    ecosystem            = $ecosystem
    ecosystems_detected  = @($ecosystemsDetected)
    profile              = if ($Profile) { $Profile } else { "auto" }
    stage                = if ($Stage) { $Stage } else { "auto" }
    monorepo_mode        = $Monorepo.IsPresent
    dimensions           = [ordered]@{
        "1_architecture_docs"   = [ordered]@{
            agent_instruction_files = @($agentFiles)
            docs_exists             = $docsExists
            docs_has_index          = $docsHasIndex
            docs_has_architecture   = $docsHasArch
            has_design_docs         = $hasDesignDocs
        }
        "2_mechanical_constraints" = [ordered]@{
            ci_configs     = @($ciConfigs)
            linter_configs = @($linterConfigs)
            type_configs   = @($typeConfigs)
        }
        "4_testing"             = [ordered]@{
            test_dirs        = @($testDirs)
            test_files_count = $testFilesCount
        }
        "6_entropy_management"  = [ordered]@{
            has_quality_score = $hasQualityScore
        }
        "7_long_running"        = [ordered]@{
            has_init_script       = $hasInitScript
            has_progress_tracking = $hasProgressTracking
        }
        "8_safety"              = [ordered]@{
            has_codeowners = $hasCodeowners
        }
    }
    content_analysis     = [ordered]@{
        dim3_observability = [ordered]@{
            structured_logging = [ordered]@{
                logging_framework_files = $loggingFrameworkFiles
                print_only              = ($loggingFrameworkFiles -eq 0 -and $printOnlyFiles -gt 0)
            }
            metrics_tracing    = [ordered]@{
                opentelemetry_files = $otelFiles
                metrics_files       = $metricsFiles
            }
            ui_visibility      = [ordered]@{
                e2e_dependency_files = $e2eDepFiles
            }
            error_context      = [ordered]@{
                custom_error_files  = $customErrorFiles
                generic_catch_files = $genericCatchFiles
            }
        }
        dim5_context       = [ordered]@{
            agent_file_quality = $agentFileQuality
            docs_structure     = $docsStructure
            llms_txt           = [ordered]@{
                llms_txt      = $hasLlmsTxt
                llms_full_txt = $hasLlmsFullTxt
            }
            structured_state   = [ordered]@{
                state_files   = @($stateFiles)
                artifact_dirs = @($artifactDirs)
            }
        }
        dim6_entropy       = [ordered]@{
            golden_principles  = [ordered]@{
                principle_references = $principleRefs
            }
            tech_debt          = [ordered]@{
                todo_files          = $todoFiles
                fixme_files         = $fixmeFiles
                hack_files          = $hackFiles
                has_tracker         = $hasTracker
                tracker_has_content = $trackerHasContent
            }
            ai_slop_detection  = [ordered]@{
                has_dead_code_rules = $hasDeadCodeRules
                has_duplicate_rules = $hasDuplicateRules
            }
        }
        monorepo           = [ordered]@{
            is_monorepo = $isMonorepo
            type        = $monorepoType
            packages    = @($monorepoPackages)
        }
    }
    summary              = [ordered]@{
        agent_files_count    = @($agentFiles).Count
        ci_configs_count     = @($ciConfigs).Count
        linter_configs_count = @($linterConfigs).Count
        type_configs_count   = @($typeConfigs).Count
        test_dirs_count      = @($testDirs).Count
        test_files_count     = $testFilesCount
        quick_assessment     = $quickAssessment
    }
}

Pop-Location

if ($Persist) { $Blueprint = [switch]::new($true) }
if ($Blueprint) { $Format = "markdown" }

# --- Gap analysis ---
function Get-Gaps {
    $gaps = @()
    if (@($agentFiles).Count -eq 0) { $gaps += "NO_AGENT_FILE" }
    if (-not $docsExists) { $gaps += "NO_DOCS_DIR" }
    if (-not $docsHasArch) { $gaps += "NO_ARCHITECTURE_DOC" }
    if (-not $hasDesignDocs) { $gaps += "NO_DESIGN_DOCS" }
    if (@($ciConfigs).Count -eq 0) { $gaps += "NO_CI_PIPELINE" }
    if (@($linterConfigs).Count -eq 0) { $gaps += "NO_LINTER" }
    if (@($typeConfigs).Count -eq 0) { $gaps += "NO_TYPE_CHECKER" }
    if (@($testDirs).Count -eq 0) { $gaps += "NO_TESTS" }
    if (-not $hasQualityScore) { $gaps += "NO_TECH_DEBT_TRACKING" }
    if (-not $hasInitScript) { $gaps += "NO_ENV_RECOVERY" }
    if (-not $hasProgressTracking) { $gaps += "NO_PROGRESS_TRACKING" }
    if (-not $hasCodeowners) { $gaps += "NO_CODEOWNERS" }
    return $gaps
}

function Get-StatusText([bool]$val) { if ($val) { "PASS" } else { "FAIL" } }
function Get-ExistsText([bool]$val) { if ($val) { "exists" } else { "missing" } }

function Format-Markdown {
    $repoName = Split-Path $RepoAbs -Leaf
    $afCount = @($agentFiles).Count
    $ciCount = @($ciConfigs).Count
    $lcCount = @($linterConfigs).Count
    $tcCount = @($typeConfigs).Count
    $tdCount = @($testDirs).Count

    $md = @"
# Harness Audit: $repoName

**Date**: $Timestamp
**Profile**: $(if ($Profile) { $Profile } else { "auto" }) | **Stage**: $(if ($Stage) { $Stage } else { "auto" }) | **Ecosystem**: $ecosystem
**Assessment**: $quickAssessment

## Scan Results

| Dimension | Finding | Status |
|-----------|---------|--------|
| Agent instruction files | $afCount found | $(Get-StatusText ($afCount -gt 0)) |
| docs/ directory | $(Get-ExistsText $docsExists) | $(Get-StatusText $docsExists) |
| ARCHITECTURE.md | $(Get-ExistsText $docsHasArch) | $(Get-StatusText $docsHasArch) |
| CI configs | $ciCount found | $(Get-StatusText ($ciCount -gt 0)) |
| Linter configs | $lcCount found | $(Get-StatusText ($lcCount -gt 0)) |
| Type checker configs | $tcCount found | $(Get-StatusText ($tcCount -gt 0)) |
| Test directories | $tdCount found ($testFilesCount test files) | $(Get-StatusText ($tdCount -gt 0)) |
| Tech debt tracking | $(Get-ExistsText $hasQualityScore) | $(Get-StatusText $hasQualityScore) |
| Environment recovery | $(Get-ExistsText $hasInitScript) | $(Get-StatusText $hasInitScript) |
| Progress tracking | $(Get-ExistsText $hasProgressTracking) | $(Get-StatusText $hasProgressTracking) |
| CODEOWNERS | $(Get-ExistsText $hasCodeowners) | $(Get-StatusText $hasCodeowners) |

## Detected Files

**Agent files**: $(if ($afCount -gt 0) { ($agentFiles -join ", ") } else { "none" })
**CI configs**: $(if ($ciCount -gt 0) { ($ciConfigs -join ", ") } else { "none" })
**Linter configs**: $(if ($lcCount -gt 0) { ($linterConfigs -join ", ") } else { "none" })
**Type configs**: $(if ($tcCount -gt 0) { ($typeConfigs -join ", ") } else { "none" })
**Test dirs**: $(if ($tdCount -gt 0) { ($testDirs -join ", ") } else { "none" })
"@
    return $md
}

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
- **Fix**: Add CI using ``templates/ci/github-actions/standard-pipeline.yml`` (or gitlab-ci.yml / azure-pipelines.yml)
- **Effort**: 1 hour | **Priority**: CRITICAL
"@
        "NO_LINTER" = @"

### Missing: Linter Configuration (Dim 2)
- **Impact**: No style or correctness enforcement on agent-generated code
- **Fix**: Add linter config for your ecosystem (see ``data/ecosystems.json`` for recommendations)
- **Effort**: 30 min | **Priority**: CRITICAL
"@
        "NO_TYPE_CHECKER" = @"

### Missing: Type Checker (Dim 2)
- **Impact**: Agent can produce type-unsafe code that passes CI
- **Fix**: Add type checking in strict mode (see ``data/ecosystems.json`` for ecosystem-specific setup)
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
- **Fix**: Add ``templates/universal/tech-debt-tracker.json`` to track quality scores per module
- **Effort**: 15 min | **Priority**: LOW
"@
        "NO_ENV_RECOVERY" = @"

### Missing: Environment Recovery Script (Dim 7)
- **Impact**: Agents cannot reliably bootstrap development environment
- **Fix**: Create init script using ``templates/init/init.sh`` or ``templates/init/init.ps1``
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

    # Quick wins
    $md += "`n## Quick Wins (implement today)`n`n"
    $winNum = 1
    $criticalGaps = @("NO_AGENT_FILE", "NO_CI_PIPELINE", "NO_LINTER", "NO_TYPE_CHECKER", "NO_TESTS")
    $winLabels = @{
        "NO_AGENT_FILE" = "Create AGENTS.md from scaffold template"
        "NO_CI_PIPELINE" = "Add CI pipeline from templates/ci/"
        "NO_LINTER" = "Add linter config for $ecosystem ecosystem"
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

    # Recommended templates
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

    # CI commands
    $md += "`n`n## Ecosystem CI Commands ($ecosystem)`n`n"
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

    if ($ciCmds.ContainsKey($ecosystem)) {
        $md += $ciCmds[$ecosystem]
    } else {
        $md += "See ``data/ecosystems.json`` for $ecosystem-specific commands.`n"
    }

    $md += @"

---

*Blueprint generated by harness-audit.ps1. For full scoring, run the agent-led audit (Mode 1 in SKILL.md).*
*Profile and stage weight tables are in ``data/profiles.json`` and ``data/stages.json``.*
"@

    return $md
}

# --- Write output ---
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
        $suffix = if ($Blueprint) { "blueprint" } else { "audit" }
    } else {
        $ext = "json"
        $suffix = "audit"
    }
    $filename = "${dateStr}_${repoName}_${suffix}.${ext}"
    $finalOutput | Out-File "$Output/$filename" -Encoding utf8
    Write-Host "Output written to $Output/$filename"
} else {
    $finalOutput
}
