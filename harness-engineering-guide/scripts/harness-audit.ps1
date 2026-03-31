# harness-audit.ps1 — Scan a repository for harness engineering readiness
# Usage: pwsh harness-audit.ps1 [-RepoRoot <path>]
# Output: JSON object with discovered harness artifacts
param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"
Push-Location $RepoRoot

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

# --- Dimension 2: CI Configs ---
$ciConfigs = @()
$ciPatterns = @("*.yml", "*.yaml")
if (Test-Path ".github/workflows") {
    Get-ChildItem ".github/workflows" -Include $ciPatterns -ErrorAction SilentlyContinue |
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
    ".editorconfig"
)
$linterConfigs = Find-FilesRecursive -Names $linterNames

# --- Dimension 2: Type Checking ---
$typeNames = @("tsconfig.json", "mypy.ini", ".mypy.ini", "pyrightconfig.json")
$typeConfigs = Find-FilesRecursive -Names $typeNames
if ((Test-Path "pyproject.toml") -and (Select-String -Path "pyproject.toml" -Pattern "\[tool\.mypy\]|\[tool\.pyright\]" -Quiet)) {
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
    (Test-Path "Makefile") -or (Test-Path "docker-compose.yml") -or (Test-Path "docker-compose.yaml")
$hasProgressTracking = (Test-Path "progress.txt") -or (Test-Path "progress.md") -or
    (Test-Path "exec-plans") -or (Test-Path "docs/exec-plans")

# --- Dimension 8: Safety ---
$hasCodeowners = (Test-Path "CODEOWNERS") -or (Test-Path ".github/CODEOWNERS") -or (Test-Path "docs/CODEOWNERS")

# --- Ecosystem ---
$ecosystem = "unknown"
if (Test-Path "package.json") { $ecosystem = "node" }
if ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt") -or (Test-Path "setup.py")) { $ecosystem = "python" }
if (Test-Path "go.mod") { $ecosystem = "go" }
if (Test-Path "Cargo.toml") { $ecosystem = "rust" }
if (Test-Path "Gemfile") { $ecosystem = "ruby" }

# --- Quick Assessment ---
$score = 0
if ($agentFiles.Count -gt 0) { $score++ }
if ($ciConfigs.Count -gt 0) { $score++ }
if ($linterConfigs.Count -gt 0) { $score++ }
if ($typeConfigs.Count -gt 0) { $score++ }
if ($testDirs.Count -gt 0) { $score++ }
if ($docsExists) { $score++ }

$quickAssessment = switch ($true) {
    ($score -ge 5) { "Good foundation - proceed to detailed audit" }
    ($score -ge 3) { "Partial harness - significant gaps likely" }
    default { "Minimal harness - expect low scores across most dimensions" }
}

# --- Output ---
$output = [ordered]@{
    repo_root  = (Get-Location).Path
    ecosystem  = $ecosystem
    dimensions = [ordered]@{
        "1_architecture_docs"   = [ordered]@{
            agent_instruction_files = @($agentFiles)
            docs_exists             = $docsExists
            docs_has_index          = $docsHasIndex
            docs_has_architecture   = $docsHasArch
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
    summary    = [ordered]@{
        agent_files_count   = @($agentFiles).Count
        ci_configs_count    = @($ciConfigs).Count
        linter_configs_count = @($linterConfigs).Count
        type_configs_count  = @($typeConfigs).Count
        test_dirs_count     = @($testDirs).Count
        test_files_count    = $testFilesCount
        quick_assessment    = $quickAssessment
    }
}

Pop-Location
$output | ConvertTo-Json -Depth 5
