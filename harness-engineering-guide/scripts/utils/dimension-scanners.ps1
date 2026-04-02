# dimension-scanners.ps1 — Detection logic for all 8 audit dimensions
# Dot-sourced by harness-audit.ps1. Organizes detection BY DIMENSION, not by technique.
# Each Invoke-Dim*Scan returns an [ordered]@{} and sets script-scope globals for gap analysis.

# ===========================================================================
# Helpers
# ===========================================================================

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

$script:SrcIncludes = @("*.ts", "*.js", "*.py", "*.go", "*.rs", "*.java", "*.kt", "*.cs", "*.rb")

# ===========================================================================
# Dim 1: Architecture & Documentation
# ===========================================================================

function Invoke-Dim1Scan {
    $script:agentFiles = Find-FilesRecursive -Names @("AGENTS.md", "CLAUDE.md", "CODEX.md", ".cursorrules")
    $cursorRules = Get-ChildItem -Path . -Filter "*.md" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '[\\/]\.cursor[\\/]rules[\\/]' -and $_.FullName -notmatch '[\\/]\.git[\\/]' } |
        ForEach-Object { $_.FullName.Replace((Get-Location).Path + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/') }
    if ($cursorRules) { $script:agentFiles = @($script:agentFiles) + @($cursorRules) | Sort-Object -Unique }

    $script:agentFileLineCount = 0; $script:agentFileNonempty = $false; $script:agentFileSubstantiveLines = 0
    foreach ($af in @("AGENTS.md", "CLAUDE.md", "CODEX.md")) {
        if (Test-Path $af) {
            $script:agentFileLineCount = (Get-Content $af -ErrorAction SilentlyContinue | Measure-Object).Count
            $script:agentFileSubstantiveLines = (Get-Content $af -ErrorAction SilentlyContinue |
                Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#' } | Measure-Object).Count
            if ($script:agentFileSubstantiveLines -ge 3) { $script:agentFileNonempty = $true }
            break
        }
    }

    $script:docsExists = Test-Path "docs" -PathType Container
    $script:docsHasIndex = (Test-Path "docs/index.md") -or (Test-Path "docs/INDEX.md") -or (Test-Path "docs/README.md")
    $script:docsHasArch = (Test-Path "docs/ARCHITECTURE.md") -or (Test-Path "ARCHITECTURE.md")
    $script:hasDesignDocs = (Test-Path "docs/design-docs") -or (Test-Path "docs/adr") -or
        (Test-Path "docs/adrs") -or (Test-Path "docs/decisions") -or (Test-Path "docs/exec-plans")

    return [ordered]@{
        agent_instruction_files = @($script:agentFiles)
        agent_file_line_count          = $script:agentFileLineCount
        agent_file_substantive_lines   = $script:agentFileSubstantiveLines
        agent_file_nonempty            = $script:agentFileNonempty
        docs_exists             = $script:docsExists
        docs_has_index          = $script:docsHasIndex
        docs_has_architecture   = $script:docsHasArch
        has_design_docs         = $script:hasDesignDocs
    }
}

# ===========================================================================
# Dim 2: Mechanical Constraints
# ===========================================================================

function Invoke-Dim2Scan {
    $script:ciConfigs = @()
    if (Test-Path ".github/workflows") {
        Get-ChildItem ".github/workflows" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @(".yml", ".yaml") } |
            ForEach-Object { $script:ciConfigs += ".github/workflows/$($_.Name)" }
    }
    foreach ($f in @(".gitlab-ci.yml", "Jenkinsfile", "azure-pipelines.yml")) {
        if (Test-Path $f) { $script:ciConfigs += $f }
    }
    if (Test-Path ".circleci/config.yml") { $script:ciConfigs += ".circleci/config.yml" }

    $script:linterConfigs = Find-FilesRecursive -Names @(
        ".eslintrc", ".eslintrc.js", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js", "eslint.config.mjs",
        ".prettierrc", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js",
        "biome.json", "biome.jsonc", "ruff.toml", ".flake8", ".pylintrc",
        ".golangci.yml", ".golangci.yaml", "clippy.toml", ".clippy.toml",
        ".rubocop.yml", "checkstyle.xml", ".swiftlint.yml", "analysis_options.yaml", "detekt.yml", ".editorconfig")

    $script:formatterConfigs = Find-FilesRecursive -Names @(
        ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.js", ".prettierrc.cjs",
        "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs", "rustfmt.toml", ".rustfmt.toml", ".editorconfig")
    foreach ($bf in @("biome.json", "biome.jsonc")) {
        if (Test-Path $bf) { $script:formatterConfigs = @($script:formatterConfigs) + @("$bf (biome)") }
    }

    $script:typeConfigs = Find-FilesRecursive -Names @("tsconfig.json", "mypy.ini", ".mypy.ini", "pyrightconfig.json")
    if ((Test-Path "pyproject.toml") -and (Test-FileContains "pyproject.toml" "\[tool\.mypy\]|\[tool\.pyright\]")) {
        $script:typeConfigs = @($script:typeConfigs) + @("pyproject.toml (type config)")
    }

    $script:hasPrecommit = $false; $script:precommitTools = @()
    if (Test-Path ".pre-commit-config.yaml") { $script:hasPrecommit = $true; $script:precommitTools += "pre-commit" }
    if (Test-Path ".husky") { $script:hasPrecommit = $true; $script:precommitTools += "husky" }
    foreach ($lf in @("lefthook.yml", ".lefthook.yml", "lefthook.yaml", ".lefthook.yaml")) {
        if (Test-Path $lf) { $script:hasPrecommit = $true; $script:precommitTools += "lefthook"; break }
    }
    if ((Test-Path "package.json") -and (Test-FileContains "package.json" '"lint-staged"')) {
        $script:hasPrecommit = $true; $script:precommitTools += "lint-staged"
    }

    # CI content analysis
    $ciContent = [ordered]@{
        ci_runs_lint = $false; ci_runs_test = $false; ci_runs_typecheck = $false
        ci_runs_format = $false; ci_runs_build = $false; ci_runs_secret_scan = $false; ci_has_human_gates = $false
    }
    foreach ($cf in $script:ciConfigs) {
        if (-not (Test-Path $cf)) { continue }
        if (Test-FileContains $cf "eslint|biome check|biome lint|ruff check|golangci-lint|clippy|rubocop|pylint|flake8|bun (run )?lint|turbo lint") { $ciContent.ci_runs_lint = $true }
        if (Test-FileContains $cf "npm test|npx vitest|npx jest|pytest|go test|cargo test|rspec|dotnet test|mvn test|gradle test|bun test|bun turbo test|turbo test|bunx vitest") { $ciContent.ci_runs_test = $true }
        if (Test-FileContains $cf "tsc --noEmit|tsc -b|mypy|pyright|go vet|cargo check|bun typecheck|bun run typecheck|bunx tsc") { $ciContent.ci_runs_typecheck = $true }
        if (Test-FileContains $cf "prettier|biome format|ruff format|gofmt|cargo fmt|rustfmt") { $ciContent.ci_runs_format = $true }
        if (Test-FileContains $cf "npm run build|cargo build|go build|dotnet build|mvn package|gradle build|bun (run )?build|turbo build") { $ciContent.ci_runs_build = $true }
        if (Test-FileContains $cf "gitleaks|trufflehog|detect-secrets|git-secrets|secretlint") { $ciContent.ci_runs_secret_scan = $true }
        if (Test-FileContains $cf "when:\s*manual|required_reviewers|protection_rules|approval|manual-trigger") { $ciContent.ci_has_human_gates = $true }
    }

    # Dependency rules
    $depRules = [ordered]@{ any_detected = $false; eslint_boundaries = $false; import_linter = $false; depguard = $false; workspace_deps = $false }
    foreach ($cfg in @(".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js", "eslint.config.mjs")) {
        if ((Test-Path $cfg) -and (Test-FileContains $cfg "eslint-plugin-boundaries|no-restricted-imports|import/no-restricted-paths")) { $depRules.eslint_boundaries = $true }
    }
    if ((Test-Path "package.json") -and (Test-FileContains "package.json" "eslint-plugin-boundaries")) { $depRules.eslint_boundaries = $true }
    foreach ($cfg in @(".importlinter", "importlinter.cfg")) { if (Test-Path $cfg) { $depRules.import_linter = $true } }
    if ((Test-Path "pyproject.toml") -and (Test-FileContains "pyproject.toml" "\[tool\.importlinter\]")) { $depRules.import_linter = $true }
    foreach ($cfg in @(".golangci.yml", ".golangci.yaml")) {
        if ((Test-Path $cfg) -and (Test-FileContains $cfg "depguard")) { $depRules.depguard = $true }
    }
    if ((Test-Path "Cargo.toml") -and (Test-FileContains "Cargo.toml" "\[workspace\.dependencies\]")) { $depRules.workspace_deps = $true }
    $depRules.any_detected = $depRules.eslint_boundaries -or $depRules.import_linter -or $depRules.depguard -or $depRules.workspace_deps

    return [ordered]@{
        ci_configs        = @($script:ciConfigs)
        linter_configs    = @($script:linterConfigs)
        formatter_configs = @($script:formatterConfigs)
        type_configs      = @($script:typeConfigs)
        pre_commit_hooks  = [ordered]@{ has_precommit = $script:hasPrecommit; tools = @($script:precommitTools) }
        ci_content        = $ciContent
        dependency_rules  = $depRules
    }
}

# ===========================================================================
# Dim 3: Feedback Loops & Observability
# ===========================================================================

function Invoke-Dim3Scan {
    $si = $script:SrcIncludes
    $logFiles = Count-GrepFiles -Pattern "winston|pino|bunyan|loguru|structlog|import logging|go\.uber\.org/zap|logrus|zerolog|log/slog|tracing::|Serilog|NLog|Rails\.logger" -Include $si
    $printOnly = $false
    if ($logFiles -eq 0) {
        $pc = Count-GrepFiles -Pattern "console\.(log|error|warn)|print\(|fmt\.Print|println!|System\.out\.print" -Include $si
        if ($pc -gt 0) { $printOnly = $true }
    }
    $otelFiles = Count-GrepFiles -Pattern "opentelemetry|@opentelemetry|go\.opentelemetry\.io|OpenTelemetry" -Include ($si + @("*.json", "*.toml", "*.yaml", "*.yml"))
    $metricsFiles = Count-GrepFiles -Pattern "prometheus|prom-client|prometheus_client|micrometer|Prometheus\.NET" -Include ($si + @("*.json", "*.toml"))
    $e2eDepFiles = Count-GrepFiles -Pattern "playwright|puppeteer|cypress|chromedp|selenium|capybara" -Include @("*.json", "*.toml", "*.txt", "*.cfg")
    $customErrors = Count-GrepFiles -Pattern "class \w+Error|new Error\(|raise \w+Error|errors\.New|anyhow!|thiserror" -Include $si
    $genericCatches = Count-GrepFiles -Pattern "catch\s*\(\s*\)|except:|except Exception|recover\(\)" -Include $si

    return [ordered]@{
        structured_logging = [ordered]@{ logging_framework_files = $logFiles; print_only = $printOnly }
        metrics_tracing    = [ordered]@{ opentelemetry_files = $otelFiles; metrics_files = $metricsFiles }
        ui_visibility      = [ordered]@{ e2e_dependency_files = $e2eDepFiles }
        error_context      = [ordered]@{ custom_error_files = $customErrors; generic_catch_files = $genericCatches }
    }
}

# ===========================================================================
# Dim 4: Testing & Quality Verification
# ===========================================================================

function Invoke-Dim4Scan {
    $script:testDirs = Find-DirsRecursive -Names @("tests", "__tests__", "test", "spec")
    $script:testFilesCount = (Get-ChildItem -Path . -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and ($_.Name -match '\.(test|spec)\.' -or $_.Name -match '(_test\.|test_)') } |
        Measure-Object).Count

    $testFilesSampled = 0; $testFilesNonempty = 0; $testFilesWithAssertions = 0
    $sampleFiles = Get-ChildItem -Path . -Recurse -Depth 5 -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and ($_.Name -match '\.(test|spec)\.' -or $_.Name -match '(_test\.|test_)') } |
        Select-Object -First 20
    foreach ($tf in $sampleFiles) {
        $testFilesSampled++
        $lc = (Get-Content $tf.FullName -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($lc -gt 10) { $testFilesNonempty++ }
        if (Select-String -Path $tf.FullName -Pattern 'describe\(|it\(|test\(|expect\(|assert|should|assertEqual|assert_eq!|#\[test\]|@Test|def test_|func Test' -Quiet -ErrorAction SilentlyContinue) {
            $testFilesWithAssertions++
        }
    }

    $script:hasFeatureTracker = (Test-Path "features.json") -or (Test-Path "feature-checklist.json") -or
        (Test-Path "docs/features.json") -or (Test-Path "docs/feature-checklist.json")

    # Coverage thresholds
    $covResult = [ordered]@{ has_threshold = $false; has_coverage_tool = $false; ci_has_coverage = $false }
    if ((Test-Path "package.json") -and (Test-FileContains "package.json" "coverageThreshold|coverage.*threshold")) { $covResult.has_threshold = $true }
    foreach ($cfg in @("jest.config.js", "jest.config.ts", "jest.config.json", "vitest.config.ts", "vitest.config.js", "vitest.config.mts")) {
        if (Test-Path $cfg) {
            if (Test-FileContains $cfg "coverageThreshold|thresholds|coverage") { $covResult.has_coverage_tool = $true }
            if (Test-FileContains $cfg "coverageThreshold|branches|functions|lines|statements.*[0-9]") { $covResult.has_threshold = $true }
        }
    }
    if (Test-Path "pyproject.toml") {
        if (Test-FileContains "pyproject.toml" "fail_under") { $covResult.has_threshold = $true }
        if (Test-FileContains "pyproject.toml" "\[tool\.coverage\]|\[tool\.pytest.*cov\]") { $covResult.has_coverage_tool = $true }
    }
    if (Test-Path ".coveragerc") { $covResult.has_coverage_tool = $true; if (Test-FileContains ".coveragerc" "fail_under") { $covResult.has_threshold = $true } }
    foreach ($cf in $script:ciConfigs) {
        if (Test-Path $cf) {
            if (Test-FileContains $cf "cov-fail-under|coverage.*fail|coverprofile|tarpaulin|llvm-cov|codecov|coveralls") { $covResult.ci_has_coverage = $true }
            if (Test-FileContains $cf "cov-fail-under") { $covResult.has_threshold = $true }
        }
    }

    return [ordered]@{
        test_dirs                  = @($script:testDirs)
        test_files_count           = $script:testFilesCount
        test_files_nonempty_sample = [ordered]@{ sampled = $testFilesSampled; nonempty = $testFilesNonempty; with_assertions = $testFilesWithAssertions }
        ci_runs_test               = $ciContent.ci_runs_test
        has_feature_tracker        = $script:hasFeatureTracker
        coverage_thresholds        = $covResult
    }
}

# ===========================================================================
# Dim 5: Context Engineering
# ===========================================================================

function Invoke-Dim5Scan {
    $afq = [ordered]@{ file = ""; line_count = 0; doc_links = 0; command_refs = 0 }
    foreach ($af in @("AGENTS.md", "CLAUDE.md", "CODEX.md")) {
        if (Test-Path $af) {
            $content = Get-Content $af -ErrorAction SilentlyContinue
            $afq.file = $af; $afq.line_count = $content.Count
            $afq.doc_links = ($content | Select-String -Pattern '\[.*\]\(.*\)|see |refer to |docs/' -AllMatches -ErrorAction SilentlyContinue).Count
            $afq.command_refs = ($content | Select-String -Pattern '```|npm |yarn |pnpm |pip |cargo |go |make |docker' -AllMatches -ErrorAction SilentlyContinue).Count
            break
        }
    }

    $docsStruct = [ordered]@{ exists = $script:docsExists; has_index = $script:docsHasIndex; subdirs = 0; total_files = 0 }
    if ($script:docsExists) {
        $docsStruct.subdirs = (Get-ChildItem "docs" -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
        $docsStruct.total_files = (Get-ChildItem "docs" -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    $stateFiles = @()
    foreach ($sf in @("progress.json", "features.json", "feature-checklist.json", "progress.txt", "progress.md")) {
        if (Test-Path $sf) { $stateFiles += $sf }
    }
    $artifactDirs = @()
    foreach ($ad in @("reports", "artifacts", "output", ".artifacts")) {
        if (Test-Path $ad -PathType Container) { $artifactDirs += $ad }
    }

    $docFreshness = [ordered]@{ ci_has_doc_freshness = $false; has_doc_expiry_markers = $false }
    foreach ($cf in $script:ciConfigs) {
        if (Test-Path $cf) {
            if (Test-FileContains $cf "doc-freshness|doc.gardening|stale.docs|docs.*freshness") { $docFreshness.ci_has_doc_freshness = $true }
            $bn = Split-Path $cf -Leaf
            if ($bn -match "doc-freshness|doc.gardening") { $docFreshness.ci_has_doc_freshness = $true }
        }
    }
    if (Test-Path "docs") {
        $ec = (Get-ChildItem "docs" -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { Select-String -Path $_.FullName -Pattern "expires:|last-reviewed:|updated:|<!-- freshness" -Quiet -ErrorAction SilentlyContinue } |
            Measure-Object).Count
        if ($ec -gt 0) { $docFreshness.has_doc_expiry_markers = $true }
    }

    return [ordered]@{
        agent_file_quality = $afq
        docs_structure     = $docsStruct
        llms_txt           = [ordered]@{ llms_txt = (Test-Path "llms.txt"); llms_full_txt = (Test-Path "llms-full.txt") }
        structured_state   = [ordered]@{ state_files = @($stateFiles); artifact_dirs = @($artifactDirs) }
        doc_freshness      = $docFreshness
    }
}

# ===========================================================================
# Dim 6: Entropy Management & Garbage Collection
# ===========================================================================

function Invoke-Dim6Scan {
    $script:hasQualityScore = (Test-Path "QUALITY_SCORE.md") -or (Test-Path "quality-score.md") -or
        (Test-Path "tech-debt-tracker.json") -or (Test-Path "docs/QUALITY_SCORE.md")

    $principleRefs = 0
    foreach ($pf in @("AGENTS.md", "CLAUDE.md", "CODEX.md", "docs/PRINCIPLES.md", "docs/CONVENTIONS.md")) {
        if (Test-Path $pf) {
            $principleRefs += (Select-String -Path $pf -Pattern "principle|golden rule|convention|guideline|must always|never do|prefer .* over" -AllMatches -ErrorAction SilentlyContinue).Count
        }
    }

    $si = $script:SrcIncludes
    $todoF = Count-GrepFiles -Pattern "TODO|todo:" -Include $si
    $fixmeF = Count-GrepFiles -Pattern "FIXME|fixme:" -Include $si
    $hackF = Count-GrepFiles -Pattern "HACK|WORKAROUND|XXX" -Include $si
    $trackerContent = $false
    foreach ($tf in @("tech-debt-tracker.json", "QUALITY_SCORE.md", "quality-score.md", "docs/QUALITY_SCORE.md")) {
        if (Test-Path $tf) { $trackerContent = (Get-Item $tf).Length -gt 50; break }
    }

    $deadCode = $false; $dupRules = $false
    foreach ($cfg in @(".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js", "biome.json", "ruff.toml", "pyproject.toml", ".golangci.yml", ".golangci.yaml")) {
        if (Test-Path $cfg) {
            if (Test-FileContains $cfg "no-unused|dead.code|unused|F401|F811") { $deadCode = $true }
            if (Test-FileContains $cfg "no-duplicate|duplicate|similar|clone") { $dupRules = $true }
        }
    }

    $hasSlopCommand = $false; $hasSlopPolicy = $false
    foreach ($cmdDir in @(".opencode/command", ".claude/commands", ".cursor/rules")) {
        if (Test-Path $cmdDir -PathType Container) {
            $slopFiles = Get-ChildItem $cmdDir -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { Select-String -Path $_.FullName -Pattern "slop|rmslop|remove.*ai|clean.*ai|ai.*generated" -Quiet -ErrorAction SilentlyContinue }
            if ($slopFiles) { $hasSlopCommand = $true }
        }
    }
    foreach ($pf in @(".github/pull_request_template.md", "CONTRIBUTING.md", "AGENTS.md", "CLAUDE.md", "CODEX.md")) {
        if ((Test-Path $pf) -and (Test-FileContains $pf "ai.*slop|ai.generated|no ai|AI.*wall.*text")) { $hasSlopPolicy = $true }
    }

    return [ordered]@{
        has_quality_score = $script:hasQualityScore
        golden_principles = [ordered]@{ principle_references = $principleRefs }
        tech_debt         = [ordered]@{ todo_files = $todoF; fixme_files = $fixmeF; hack_files = $hackF; has_tracker = $script:hasQualityScore; tracker_has_content = $trackerContent }
        ai_slop_detection = [ordered]@{ has_dead_code_rules = $deadCode; has_duplicate_rules = $dupRules; has_manual_slop_command = $hasSlopCommand; has_slop_policy = $hasSlopPolicy }
    }
}

# ===========================================================================
# Dim 7: Long-Running Task Support
# ===========================================================================

function Invoke-Dim7Scan {
    $script:hasInitScript = (Test-Path "init.sh") -or (Test-Path "setup.sh") -or
        (Test-Path "Makefile") -or (Test-Path "docker-compose.yml") -or
        (Test-Path "docker-compose.yaml") -or (Test-Path "devcontainer.json") -or (Test-Path ".devcontainer") -or
        (Test-Path "flake.nix") -or (Test-Path "shell.nix")
    $initScriptLines = 0; $initScriptFile = ""
    foreach ($name in @("init.sh", "setup.sh", "Makefile", "docker-compose.yml", "docker-compose.yaml", "devcontainer.json", "flake.nix", "shell.nix")) {
        if (Test-Path $name) {
            $initScriptLines = (Get-Content $name -ErrorAction SilentlyContinue | Measure-Object).Count
            $initScriptFile = $name
            break
        }
    }
    if (-not $initScriptFile -and (Test-Path ".devcontainer" -PathType Container)) {
        $dcFile = Get-ChildItem ".devcontainer" -Filter "*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($dcFile) {
            $initScriptLines = (Get-Content $dcFile.FullName -ErrorAction SilentlyContinue | Measure-Object).Count
            $initScriptFile = ".devcontainer/$($dcFile.Name)"
        }
    }

    $script:hasProgressTracking = (Test-Path "progress.txt") -or (Test-Path "progress.md") -or
        (Test-Path "progress.json") -or (Test-Path "exec-plans") -or (Test-Path "docs/exec-plans")

    return [ordered]@{
        has_init_script       = $script:hasInitScript
        init_script_quality   = [ordered]@{ file = $initScriptFile; line_count = $initScriptLines }
        has_progress_tracking = $script:hasProgressTracking
    }
}

# ===========================================================================
# Dim 8: Safety & Access Control
# ===========================================================================

function Invoke-Dim8Scan {
    $script:hasCodeowners = (Test-Path "CODEOWNERS") -or (Test-Path ".github/CODEOWNERS") -or (Test-Path "docs/CODEOWNERS")

    $script:hasSecretScanning = $false; $script:secretScanningTools = @()
    foreach ($gf in @(".gitleaks.toml", "gitleaks.toml")) {
        if (Test-Path $gf) { $script:hasSecretScanning = $true; $script:secretScanningTools += "gitleaks"; break }
    }
    foreach ($sf in @(".secretlintrc", ".secretlintrc.json", ".secretlintrc.yml")) {
        if (Test-Path $sf) { $script:hasSecretScanning = $true; $script:secretScanningTools += "secretlint"; break }
    }
    if (Test-Path ".secrets.baseline") { $script:hasSecretScanning = $true; $script:secretScanningTools += "detect-secrets" }
    if (Test-Path ".gitguardian.yml") { $script:hasSecretScanning = $true; $script:secretScanningTools += "gitguardian" }

    $script:hasMcpConfig = $false; $script:mcpConfigFiles = @()
    foreach ($mf in @(".mcp.json", "mcp.json")) {
        if (Test-Path $mf) { $script:hasMcpConfig = $true; $script:mcpConfigFiles += $mf }
    }
    if (Test-Path ".cursor/mcp.json") { $script:hasMcpConfig = $true; $script:mcpConfigFiles += ".cursor/mcp.json" }

    # Release / deploy workflow detection (for 8.3 rollback capability assessment)
    $hasReleaseWorkflow = $false; $releaseWorkflowFiles = @()
    foreach ($cf in $script:ciConfigs) {
        if (-not (Test-Path $cf)) { continue }
        $bn = Split-Path $cf -Leaf
        if ($bn -match "publish|release|deploy") {
            $hasReleaseWorkflow = $true; $releaseWorkflowFiles += $cf
        } elseif (Test-FileContains $cf "gh release|npm publish|cargo publish|docker push|pypi.*upload") {
            $hasReleaseWorkflow = $true; $releaseWorkflowFiles += $cf
        }
    }

    return [ordered]@{
        has_codeowners        = $script:hasCodeowners
        has_secret_scanning   = $script:hasSecretScanning
        secret_scanning_tools = @($script:secretScanningTools)
        mcp_config            = [ordered]@{ has_mcp_config = $script:hasMcpConfig; files = @($script:mcpConfigFiles) }
        release_workflows     = [ordered]@{ has_release_workflow = $hasReleaseWorkflow; files = @($releaseWorkflowFiles) }
    }
}

# ===========================================================================
# Ecosystem & Monorepo Detection
# ===========================================================================

function Invoke-EcosystemDetection {
    $script:ecosystem = "unknown"; $script:ecosystemsDetected = @()
    if (Test-Path "package.json") { $script:ecosystem = "node"; $script:ecosystemsDetected += "node" }
    if ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt") -or (Test-Path "setup.py") -or (Test-Path "Pipfile")) {
        $script:ecosystem = "python"; $script:ecosystemsDetected += "python"
    }
    if (Test-Path "go.mod") { $script:ecosystem = "go"; $script:ecosystemsDetected += "go" }
    if (Test-Path "Cargo.toml") { $script:ecosystem = "rust"; $script:ecosystemsDetected += "rust" }
    if (Test-Path "Gemfile") { $script:ecosystem = "ruby"; $script:ecosystemsDetected += "ruby" }
    if ((Test-Path "pom.xml") -or (Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) { $script:ecosystemsDetected += "java" }
    if (Test-Path "Package.swift") { $script:ecosystemsDetected += "swift" }
    if (Test-Path "pubspec.yaml") { $script:ecosystem = "dart"; $script:ecosystemsDetected += "dart" }

    return [ordered]@{ primary = $script:ecosystem; detected = @($script:ecosystemsDetected) }
}

function Invoke-MonorepoDetection {
    $isMono = $false; $monoType = "none"; $packages = @()
    if (Test-Path "pnpm-workspace.yaml") { $isMono = $true; $monoType = "pnpm" }
    elseif (Test-Path "lerna.json") { $isMono = $true; $monoType = "lerna" }
    elseif (Test-Path "nx.json") { $isMono = $true; $monoType = "nx" }
    elseif (Test-Path "turbo.json") { $isMono = $true; $monoType = "turborepo" }
    elseif ((Test-Path "package.json") -and (Test-FileContains "package.json" '"workspaces"')) { $isMono = $true; $monoType = "npm-workspaces" }
    elseif ((Test-Path "Cargo.toml") -and (Test-FileContains "Cargo.toml" '\[workspace\]')) { $isMono = $true; $monoType = "cargo-workspace" }
    elseif (Test-Path "go.work") { $isMono = $true; $monoType = "go-workspace" }
    if ($isMono) {
        foreach ($pdir in @("packages", "apps", "libs", "services", "modules", "crates", "internal", "cmd")) {
            if (Test-Path $pdir -PathType Container) {
                Get-ChildItem $pdir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $packages += $_.Name }
            }
        }
    }
    return [ordered]@{ is_monorepo = $isMono; type = $monoType; packages = @($packages) }
}

# ===========================================================================
# Master Runner
# ===========================================================================

function Invoke-AllScans {
    $d1 = Invoke-Dim1Scan
    $d2 = Invoke-Dim2Scan
    $d3 = Invoke-Dim3Scan
    $d4 = Invoke-Dim4Scan
    $d5 = Invoke-Dim5Scan
    $d6 = Invoke-Dim6Scan
    $d7 = Invoke-Dim7Scan
    $d8 = Invoke-Dim8Scan
    $eco = Invoke-EcosystemDetection
    $mono = Invoke-MonorepoDetection

    return [ordered]@{
        "1_architecture_docs"   = $d1
        "2_mechanical_constraints" = $d2
        "3_observability"       = $d3
        "4_testing"             = $d4
        "5_context_engineering" = $d5
        "6_entropy_management"  = $d6
        "7_long_running"        = $d7
        "8_safety"              = $d8
        ecosystem               = $eco
        monorepo                = $mono
    }
}
