#!/usr/bin/env bash
# dimension-scanners.sh — Detection logic for all 8 audit dimensions
# Sourced by harness-audit.sh. Organizes detection BY DIMENSION, not by technique.
#
# Each scan_dim*() function:
#   1. Sets global variables (used by main script for gap analysis, scoring, markdown)
#   2. Sets DIM*_JSON (complete JSON fragment for that dimension's output)
#
# Usage:
#   source dimension-scanners.sh
#   run_all_scans "$REPO_ABS"
#   # Globals: AGENT_FILES, CI_CONFIGS, etc. (for gap/markdown)
#   # JSON fragments: DIM1_JSON, DIM2_JSON, ..., ECOSYSTEM_JSON, MONOREPO_JSON
set -euo pipefail

# ===========================================================================
# Helpers
# ===========================================================================

json_array() {
  local arr=("$@")
  if [ ${#arr[@]} -eq 0 ]; then
    echo "[]"
    return
  fi
  printf '['
  for i in "${!arr[@]}"; do
    printf '"%s"' "${arr[$i]}"
    [ "$i" -lt $((${#arr[@]} - 1)) ] && printf ','
  done
  printf ']'
}

find_files() {
  local pattern="$1"
  find . -maxdepth 4 -path "./.git" -prune -o -name "$pattern" -print 2>/dev/null | sed 's|^\./||' | sort
}

find_dirs() {
  local pattern="$1"
  find . -maxdepth 4 -path "./.git" -prune -o -type d -name "$pattern" -print 2>/dev/null | sed 's|^\./||' | sort
}

collect_files() {
  local -n _out=$1; shift
  for name in "$@"; do
    while IFS= read -r f; do
      [ -n "$f" ] && _out+=("$f")
    done < <(find_files "$name")
  done
}

collect_dirs() {
  local -n _out=$1; shift
  for name in "$@"; do
    while IFS= read -r d; do
      [ -n "$d" ] && _out+=("$d")
    done < <(find_dirs "$name")
  done
}

# ===========================================================================
# Dim 1: Architecture & Documentation
# ===========================================================================

scan_dim1() {
  AGENT_FILES=()
  collect_files AGENT_FILES AGENTS.md CLAUDE.md CODEX.md .cursorrules
  while IFS= read -r f; do
    [ -n "$f" ] && AGENT_FILES+=("$f")
  done < <(find . -maxdepth 4 -path "*/.cursor/rules/*.md" -print 2>/dev/null | sed 's|^\./||' | sort)

  DOCS_EXISTS=false; DOCS_HAS_INDEX=false; DOCS_HAS_ARCH=false; HAS_DESIGN_DOCS=false
  if [ -d "docs" ]; then
    DOCS_EXISTS=true
    for idx in docs/index.md docs/INDEX.md docs/README.md; do
      [ -f "$idx" ] && DOCS_HAS_INDEX=true && break
    done
    for arch in docs/ARCHITECTURE.md ARCHITECTURE.md; do
      [ -f "$arch" ] && DOCS_HAS_ARCH=true && break
    done
  fi
  for dd in docs/design-docs docs/adr docs/adrs docs/decisions docs/exec-plans; do
    [ -d "$dd" ] && HAS_DESIGN_DOCS=true && break
  done

  DIM1_JSON=$(cat <<EOF
{
  "agent_instruction_files": $(json_array "${AGENT_FILES[@]+"${AGENT_FILES[@]}"}"),
  "docs_exists": $DOCS_EXISTS,
  "docs_has_index": $DOCS_HAS_INDEX,
  "docs_has_architecture": $DOCS_HAS_ARCH,
  "has_design_docs": $HAS_DESIGN_DOCS
}
EOF
  )
}

# ===========================================================================
# Dim 2: Mechanical Constraints
# ===========================================================================

scan_dim2() {
  local repo="$1"

  # --- CI configs ---
  CI_CONFIGS=()
  # GitHub Actions: direct directory scan (find -path glob unreliable for dotdirs on some platforms)
  if [ -d ".github/workflows" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] && CI_CONFIGS+=("$f")
    done < <(find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | sort)
  fi
  # Other CI systems: direct file checks
  for ci_file in .gitlab-ci.yml Jenkinsfile azure-pipelines.yml; do
    [ -f "$ci_file" ] && CI_CONFIGS+=("$ci_file")
  done
  [ -f ".circleci/config.yml" ] && CI_CONFIGS+=(".circleci/config.yml")

  # --- Linter configs ---
  LINTER_CONFIGS=()
  collect_files LINTER_CONFIGS \
    .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml eslint.config.js eslint.config.mjs \
    .prettierrc .prettierrc.json .prettierrc.yml prettier.config.js \
    biome.json biome.jsonc \
    ruff.toml .flake8 .pylintrc \
    .golangci.yml .golangci.yaml \
    clippy.toml .clippy.toml \
    .rubocop.yml checkstyle.xml .swiftlint.yml \
    analysis_options.yaml detekt.yml .editorconfig

  # --- Formatter configs (independent from linters) ---
  FORMATTER_CONFIGS=()
  collect_files FORMATTER_CONFIGS \
    .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs \
    prettier.config.js prettier.config.cjs prettier.config.mjs \
    rustfmt.toml .rustfmt.toml .editorconfig
  for bf in biome.json biome.jsonc; do
    [ -f "$bf" ] && FORMATTER_CONFIGS+=("$bf (biome)")
  done

  # --- Type checking ---
  TYPE_CONFIGS=()
  collect_files TYPE_CONFIGS tsconfig.json mypy.ini .mypy.ini pyrightconfig.json
  if [ -f "pyproject.toml" ] && grep -q "\[tool\.mypy\]\|\[tool\.pyright\]" pyproject.toml 2>/dev/null; then
    TYPE_CONFIGS+=("pyproject.toml (type config)")
  fi

  # --- Pre-commit hooks ---
  HAS_PRECOMMIT=false; PRECOMMIT_TOOLS=()
  [ -f ".pre-commit-config.yaml" ] && HAS_PRECOMMIT=true && PRECOMMIT_TOOLS+=("pre-commit")
  [ -d ".husky" ] && HAS_PRECOMMIT=true && PRECOMMIT_TOOLS+=("husky")
  for name in lefthook.yml .lefthook.yml lefthook.yaml .lefthook.yaml; do
    [ -f "$name" ] && HAS_PRECOMMIT=true && PRECOMMIT_TOOLS+=("lefthook") && break
  done
  [ -f "package.json" ] && grep -q '"lint-staged"' package.json 2>/dev/null && HAS_PRECOMMIT=true && PRECOMMIT_TOOLS+=("lint-staged")

  # --- CI content analysis (grep inside CI files) ---
  local ci_runs_lint=false ci_runs_test=false ci_runs_typecheck=false
  local ci_runs_format=false ci_runs_build=false ci_runs_secret_scan=false
  local ci_has_human_gates=false
  for cf in "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"; do
    [ -f "$cf" ] || continue
    grep -qiE 'eslint|biome check|biome lint|ruff check|golangci-lint|clippy|rubocop|pylint|flake8|bun (run )?lint|turbo lint' "$cf" 2>/dev/null && ci_runs_lint=true
    grep -qiE 'npm test|npx vitest|npx jest|pytest|go test|cargo test|rspec|dotnet test|mvn test|gradle test|bun test|bun turbo test|turbo test|bunx vitest' "$cf" 2>/dev/null && ci_runs_test=true
    grep -qiE 'tsc --noEmit|tsc -b|mypy|pyright|go vet|cargo check|bun typecheck|bun run typecheck|bunx tsc' "$cf" 2>/dev/null && ci_runs_typecheck=true
    grep -qiE 'prettier|biome format|ruff format|gofmt|cargo fmt|rustfmt' "$cf" 2>/dev/null && ci_runs_format=true
    grep -qiE 'npm run build|cargo build|go build|dotnet build|mvn package|gradle build|bun (run )?build|turbo build' "$cf" 2>/dev/null && ci_runs_build=true
    grep -qiE 'gitleaks|trufflehog|detect-secrets|git-secrets|secretlint' "$cf" 2>/dev/null && ci_runs_secret_scan=true
    grep -qiE 'when:\s*manual|required_reviewers|protection_rules|approval|manual-trigger' "$cf" 2>/dev/null && ci_has_human_gates=true
  done
  CI_RUNS_LINT=$ci_runs_lint; CI_RUNS_TEST=$ci_runs_test
  CI_RUNS_SECRET_SCAN=$ci_runs_secret_scan; CI_HAS_HUMAN_GATES=$ci_has_human_gates

  # --- Dependency direction rules (grep inside configs) ---
  local dep_any=false dep_eslint=false dep_importlinter=false dep_depguard=false dep_workspace=false
  for cfg in .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs; do
    [ -f "$cfg" ] && grep -qiE 'eslint-plugin-boundaries|no-restricted-imports|import/no-restricted-paths' "$cfg" 2>/dev/null && dep_eslint=true
  done
  [ -f "package.json" ] && grep -qiE 'eslint-plugin-boundaries' package.json 2>/dev/null && dep_eslint=true
  for cfg in .importlinter importlinter.cfg; do [ -f "$cfg" ] && dep_importlinter=true; done
  [ -f "pyproject.toml" ] && grep -q '\[tool\.importlinter\]' pyproject.toml 2>/dev/null && dep_importlinter=true
  for cfg in .golangci.yml .golangci.yaml; do
    [ -f "$cfg" ] && grep -qi 'depguard' "$cfg" 2>/dev/null && dep_depguard=true
  done
  [ -f "Cargo.toml" ] && grep -q '\[workspace\.dependencies\]' Cargo.toml 2>/dev/null && dep_workspace=true
  ($dep_eslint || $dep_importlinter || $dep_depguard || $dep_workspace) && dep_any=true

  DIM2_JSON=$(cat <<EOF
{
  "ci_configs": $(json_array "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"),
  "linter_configs": $(json_array "${LINTER_CONFIGS[@]+"${LINTER_CONFIGS[@]}"}"),
  "formatter_configs": $(json_array "${FORMATTER_CONFIGS[@]+"${FORMATTER_CONFIGS[@]}"}"),
  "type_configs": $(json_array "${TYPE_CONFIGS[@]+"${TYPE_CONFIGS[@]}"}"),
  "pre_commit_hooks": {"has_precommit": $HAS_PRECOMMIT, "tools": $(json_array "${PRECOMMIT_TOOLS[@]+"${PRECOMMIT_TOOLS[@]}"}")},
  "ci_content": {"ci_runs_lint": $ci_runs_lint, "ci_runs_test": $ci_runs_test, "ci_runs_typecheck": $ci_runs_typecheck, "ci_runs_format": $ci_runs_format, "ci_runs_build": $ci_runs_build, "ci_runs_secret_scan": $ci_runs_secret_scan, "ci_has_human_gates": $ci_has_human_gates},
  "dependency_rules": {"any_detected": $dep_any, "eslint_boundaries": $dep_eslint, "import_linter": $dep_importlinter, "depguard": $dep_depguard, "workspace_deps": $dep_workspace}
}
EOF
  )
}

# ===========================================================================
# Dim 3: Feedback Loops & Observability
# ===========================================================================

scan_dim3() {
  local repo="$1"
  local src_ext="--include=*.ts --include=*.js --include=*.py --include=*.go --include=*.rs --include=*.java --include=*.kt --include=*.cs --include=*.rb"

  # Structured logging
  local log_files
  log_files=$(grep -rl $src_ext \
    -E "winston|pino|bunyan|consola|log4js|loguru|structlog|import logging|go\.uber\.org/zap|logrus|zerolog|log/slog|tracing::|env_logger|slog|Serilog|NLog|Microsoft\.Extensions\.Logging|Rails\.logger|SemanticLogger" \
    "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')
  local print_only=false
  if [ "$log_files" -eq 0 ]; then
    local pc
    pc=$(grep -rl $src_ext \
      -E "console\.(log|error|warn)|print\(|fmt\.Print|println!|System\.out\.print" \
      "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')
    [ "$pc" -gt 0 ] && print_only=true
  fi

  # Metrics & tracing
  local otel_files metrics_files tracing_files
  otel_files=$(grep -rl $src_ext --include='*.toml' --include='*.json' --include='*.yaml' --include='*.yml' \
    -E "opentelemetry|@opentelemetry|go\.opentelemetry\.io|OpenTelemetry" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')
  metrics_files=$(grep -rl $src_ext --include='*.toml' --include='*.json' \
    -E "prometheus|prom-client|prometheus_client|micrometer|Prometheus\.NET" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')
  tracing_files=$(grep -rl --include='*.yaml' --include='*.yml' --include='*.json' --include='*.toml' \
    -E "jaeger|zipkin|datadog|newrelic|sentry" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')

  # E2E / UI visibility
  local e2e_dep_files
  e2e_dep_files=$(grep -rl --include='*.json' --include='*.toml' --include='*.txt' --include='*.cfg' \
    -E "playwright|puppeteer|cypress|@testing-library|chromedp|selenium|capybara" "$repo" 2>/dev/null | head -5 | wc -l | tr -d ' ')

  # Error context quality
  local custom_errors generic_catches
  custom_errors=$(grep -rl $src_ext \
    -E "class \w+Error|new Error\(|raise \w+Error|errors\.New|anyhow!|thiserror" "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')
  generic_catches=$(grep -rl $src_ext \
    -E "catch\s*\(\s*\)|except:|except Exception|recover\(\)" "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')

  DIM3_JSON=$(cat <<EOF
{
  "structured_logging": {"logging_framework_files": $log_files, "print_only": $print_only},
  "metrics_tracing": {"opentelemetry_files": $otel_files, "metrics_files": $metrics_files, "tracing_files": $tracing_files},
  "ui_visibility": {"e2e_dependency_files": $e2e_dep_files},
  "error_context": {"custom_error_files": $custom_errors, "generic_catch_files": $generic_catches}
}
EOF
  )
}

# ===========================================================================
# Dim 4: Testing & Quality Verification
# ===========================================================================

scan_dim4() {
  local repo="$1"

  TEST_DIRS=()
  collect_dirs TEST_DIRS tests __tests__ test spec
  TEST_FILES_COUNT=$(find . -maxdepth 5 -path "./.git" -prune -o \( \
    -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \
    \) -print 2>/dev/null | wc -l | tr -d ' ')

  HAS_FEATURE_TRACKER=false
  for name in features.json feature-checklist.json; do
    ([ -f "$name" ] || [ -f "docs/$name" ]) && HAS_FEATURE_TRACKER=true && break
  done

  # Coverage thresholds (grep configs + CI)
  local cov_threshold=false cov_tool=false ci_cov=false
  if [ -f "package.json" ]; then
    grep -qE 'coverageThreshold|coverage.*threshold' package.json 2>/dev/null && cov_threshold=true
  fi
  for cfg in jest.config.js jest.config.ts jest.config.json vitest.config.ts vitest.config.js vitest.config.mts; do
    if [ -f "$cfg" ]; then
      grep -qiE 'coverageThreshold|thresholds|coverage' "$cfg" 2>/dev/null && cov_tool=true
      grep -qiE 'coverageThreshold|branches|functions|lines|statements.*[0-9]' "$cfg" 2>/dev/null && cov_threshold=true
    fi
  done
  if [ -f "pyproject.toml" ]; then
    grep -qE 'fail_under' pyproject.toml 2>/dev/null && cov_threshold=true
    grep -qE '\[tool\.coverage\]|\[tool\.pytest.*cov\]' pyproject.toml 2>/dev/null && cov_tool=true
  fi
  [ -f ".coveragerc" ] && { cov_tool=true; grep -qE 'fail_under' .coveragerc 2>/dev/null && cov_threshold=true; }
  [ -f "setup.cfg" ] && grep -qE 'fail_under' setup.cfg 2>/dev/null && cov_threshold=true
  for cf in "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"; do
    [ -f "$cf" ] || continue
    grep -qiE 'cov-fail-under|coverage.*fail|coverprofile|tarpaulin|llvm-cov|codecov|coveralls' "$cf" 2>/dev/null && ci_cov=true
    grep -qiE 'cov-fail-under' "$cf" 2>/dev/null && cov_threshold=true
  done

  DIM4_JSON=$(cat <<EOF
{
  "test_dirs": $(json_array "${TEST_DIRS[@]+"${TEST_DIRS[@]}"}"),
  "test_files_count": $TEST_FILES_COUNT,
  "has_feature_tracker": $HAS_FEATURE_TRACKER,
  "coverage_thresholds": {"has_threshold": $cov_threshold, "has_coverage_tool": $cov_tool, "ci_has_coverage": $ci_cov}
}
EOF
  )
}

# ===========================================================================
# Dim 5: Context Engineering
# ===========================================================================

scan_dim5() {
  local repo="$1"

  # Agent file quality
  local af_file="" af_lines=0 af_links=0 af_cmds=0
  for af in AGENTS.md CLAUDE.md CODEX.md; do
    if [ -f "$af" ]; then
      af_file="$af"
      af_lines=$(wc -l < "$af" | tr -d ' ')
      af_links=$(grep -c -E '\[.*\]\(.*\)|see |refer to |docs/' "$af" 2>/dev/null || echo "0")
      af_cmds=$(grep -c -E '^\s*```|npm |yarn |pnpm |pip |cargo |go |make |docker' "$af" 2>/dev/null || echo "0")
      break
    fi
  done

  # Docs structure
  local docs_subdirs=0 docs_total=0
  if [ "$DOCS_EXISTS" = true ]; then
    docs_subdirs=$(find docs -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
    docs_total=$(find docs -type f -name '*.md' | wc -l | tr -d ' ')
  fi

  # llms.txt
  local has_llms=false has_llms_full=false
  [ -f "llms.txt" ] && has_llms=true
  [ -f "llms-full.txt" ] && has_llms_full=true

  # Structured state
  local state_files=() artifact_dirs=()
  for sf in progress.json features.json feature-checklist.json progress.txt progress.md; do
    [ -f "$sf" ] && state_files+=("$sf")
  done
  for ad in reports artifacts output .artifacts; do
    [ -d "$ad" ] && artifact_dirs+=("$ad")
  done

  # Doc freshness (CI + doc markers)
  local ci_doc_fresh=false has_doc_expiry=false
  for cf in "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"; do
    [ -f "$cf" ] || continue
    grep -qiE 'doc-freshness|doc.gardening|stale.docs|docs.*freshness' "$cf" 2>/dev/null && ci_doc_fresh=true
    local bn; bn=$(basename "$cf" 2>/dev/null)
    echo "$bn" | grep -qiE 'doc-freshness|doc.gardening' && ci_doc_fresh=true
  done
  if [ -d "docs" ]; then
    local ec
    ec=$(grep -rl --include='*.md' -E 'expires:|last-reviewed:|updated:|<!-- freshness' docs 2>/dev/null | head -5 | wc -l | tr -d ' ')
    [ "$ec" -gt 0 ] && has_doc_expiry=true
  fi

  DIM5_JSON=$(cat <<EOF
{
  "agent_file_quality": {"file": "$af_file", "line_count": $af_lines, "doc_links": $af_links, "command_refs": $af_cmds},
  "docs_structure": {"exists": $DOCS_EXISTS, "has_index": $DOCS_HAS_INDEX, "subdirs": $docs_subdirs, "total_files": $docs_total},
  "llms_txt": {"llms_txt": $has_llms, "llms_full_txt": $has_llms_full},
  "structured_state": {"state_files": $(json_array "${state_files[@]+"${state_files[@]}"}"), "artifact_dirs": $(json_array "${artifact_dirs[@]+"${artifact_dirs[@]}"}")},
  "doc_freshness": {"ci_has_doc_freshness": $ci_doc_fresh, "has_doc_expiry_markers": $has_doc_expiry}
}
EOF
  )
}

# ===========================================================================
# Dim 6: Entropy Management & Garbage Collection
# ===========================================================================

scan_dim6() {
  local repo="$1"

  HAS_QUALITY_SCORE=false
  for name in QUALITY_SCORE.md quality-score.md tech-debt-tracker.json; do
    [ -f "$name" ] || [ -f "docs/$name" ] && HAS_QUALITY_SCORE=true && break
  done

  # Golden principles
  local principle_refs=0
  for pf in AGENTS.md CLAUDE.md CODEX.md docs/PRINCIPLES.md docs/CONVENTIONS.md; do
    if [ -f "$pf" ]; then
      local c
      c=$(grep -ci -E 'principle|golden rule|convention|guideline|must always|never do|prefer .* over' "$pf" 2>/dev/null || echo "0")
      principle_refs=$((principle_refs + c))
    fi
  done

  # Tech debt signals
  local src_ext="--include=*.ts --include=*.js --include=*.py --include=*.go --include=*.rs --include=*.java --include=*.kt --include=*.cs --include=*.rb"
  local todo_f fixme_f hack_f
  todo_f=$(grep -rl $src_ext -E "TODO|todo:" "$repo" 2>/dev/null | wc -l | tr -d ' ')
  fixme_f=$(grep -rl $src_ext -E "FIXME|fixme:" "$repo" 2>/dev/null | wc -l | tr -d ' ')
  hack_f=$(grep -rl $src_ext -E "HACK|WORKAROUND|XXX" "$repo" 2>/dev/null | wc -l | tr -d ' ')
  local tracker_content=false
  for tf in tech-debt-tracker.json QUALITY_SCORE.md quality-score.md docs/QUALITY_SCORE.md; do
    if [ -f "$tf" ]; then
      local sz; sz=$(wc -c < "$tf" | tr -d ' ')
      [ "$sz" -gt 50 ] && tracker_content=true
      break
    fi
  done

  # AI slop detection rules (automated)
  local dead_code=false dup_rules=false
  for cfg in .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs \
    biome.json biome.jsonc ruff.toml pyproject.toml .golangci.yml .golangci.yaml; do
    if [ -f "$cfg" ]; then
      grep -qi "no-unused\|dead.code\|unused\|F401\|F811" "$cfg" 2>/dev/null && dead_code=true
      grep -qi "no-duplicate\|duplicate\|similar\|clone" "$cfg" 2>/dev/null && dup_rules=true
    fi
  done

  # AI slop detection (manual commands / awareness)
  local has_slop_command=false has_slop_policy=false
  for cmd_dir in .opencode/command .claude/commands .cursor/rules; do
    if [ -d "$cmd_dir" ]; then
      local sc
      sc=$(grep -rli 'slop\|rmslop\|remove.*ai\|clean.*ai\|ai.*generated' "$cmd_dir" 2>/dev/null | head -3 | wc -l | tr -d ' ')
      [ "$sc" -gt 0 ] && has_slop_command=true
    fi
  done
  for pf in .github/pull_request_template.md CONTRIBUTING.md AGENTS.md CLAUDE.md CODEX.md; do
    if [ -f "$pf" ]; then
      grep -qi 'ai.*slop\|ai.generated\|no ai\|AI.*wall.*text' "$pf" 2>/dev/null && has_slop_policy=true
    fi
  done

  DIM6_JSON=$(cat <<EOF
{
  "has_quality_score": $HAS_QUALITY_SCORE,
  "golden_principles": {"principle_references": $principle_refs},
  "tech_debt": {"todo_files": $todo_f, "fixme_files": $fixme_f, "hack_files": $hack_f, "has_tracker": $HAS_QUALITY_SCORE, "tracker_has_content": $tracker_content},
  "ai_slop_detection": {"has_dead_code_rules": $dead_code, "has_duplicate_rules": $dup_rules, "has_manual_slop_command": $has_slop_command, "has_slop_policy": $has_slop_policy}
}
EOF
  )
}

# ===========================================================================
# Dim 7: Long-Running Task Support
# ===========================================================================

scan_dim7() {
  HAS_INIT_SCRIPT=false
  for name in init.sh setup.sh Makefile docker-compose.yml docker-compose.yaml devcontainer.json flake.nix shell.nix; do
    [ -f "$name" ] && HAS_INIT_SCRIPT=true && break
  done
  [ -d ".devcontainer" ] && HAS_INIT_SCRIPT=true

  HAS_PROGRESS_TRACKING=false
  for name in progress.txt progress.md progress.json; do
    [ -f "$name" ] && HAS_PROGRESS_TRACKING=true && break
  done
  [ -d "exec-plans" ] || [ -d "docs/exec-plans" ] && HAS_PROGRESS_TRACKING=true

  DIM7_JSON=$(cat <<EOF
{
  "has_init_script": $HAS_INIT_SCRIPT,
  "has_progress_tracking": $HAS_PROGRESS_TRACKING
}
EOF
  )
}

# ===========================================================================
# Dim 8: Safety & Access Control
# ===========================================================================

scan_dim8() {
  HAS_CODEOWNERS=false
  [ -f "CODEOWNERS" ] || [ -f ".github/CODEOWNERS" ] || [ -f "docs/CODEOWNERS" ] && HAS_CODEOWNERS=true

  HAS_SECRET_SCANNING=false; SECRET_SCANNING_TOOLS=()
  for name in .gitleaks.toml gitleaks.toml; do
    [ -f "$name" ] && HAS_SECRET_SCANNING=true && SECRET_SCANNING_TOOLS+=("gitleaks") && break
  done
  for name in .secretlintrc .secretlintrc.json .secretlintrc.yml; do
    [ -f "$name" ] && HAS_SECRET_SCANNING=true && SECRET_SCANNING_TOOLS+=("secretlint") && break
  done
  [ -f ".secrets.baseline" ] && HAS_SECRET_SCANNING=true && SECRET_SCANNING_TOOLS+=("detect-secrets")
  [ -f ".gitguardian.yml" ] && HAS_SECRET_SCANNING=true && SECRET_SCANNING_TOOLS+=("gitguardian")

  HAS_MCP_CONFIG=false; MCP_CONFIG_FILES=()
  for name in .mcp.json mcp.json; do
    [ -f "$name" ] && HAS_MCP_CONFIG=true && MCP_CONFIG_FILES+=("$name")
  done
  [ -f ".cursor/mcp.json" ] && HAS_MCP_CONFIG=true && MCP_CONFIG_FILES+=(".cursor/mcp.json")

  # Release / deploy workflow detection (for 8.3 rollback capability assessment)
  local has_release_workflow=false
  RELEASE_WORKFLOW_FILES=()
  for cf in "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"; do
    [ -f "$cf" ] || continue
    local bn; bn=$(basename "$cf" 2>/dev/null)
    if echo "$bn" | grep -qiE 'publish|release|deploy'; then
      has_release_workflow=true
      RELEASE_WORKFLOW_FILES+=("$cf")
    elif grep -qiE 'gh release|npm publish|cargo publish|docker push|pypi.*upload' "$cf" 2>/dev/null; then
      has_release_workflow=true
      RELEASE_WORKFLOW_FILES+=("$cf")
    fi
  done

  DIM8_JSON=$(cat <<EOF
{
  "has_codeowners": $HAS_CODEOWNERS,
  "has_secret_scanning": $HAS_SECRET_SCANNING,
  "secret_scanning_tools": $(json_array "${SECRET_SCANNING_TOOLS[@]+"${SECRET_SCANNING_TOOLS[@]}"}"),
  "mcp_config": {"has_mcp_config": $HAS_MCP_CONFIG, "files": $(json_array "${MCP_CONFIG_FILES[@]+"${MCP_CONFIG_FILES[@]}"}")},
  "release_workflows": {"has_release_workflow": $has_release_workflow, "files": $(json_array "${RELEASE_WORKFLOW_FILES[@]+"${RELEASE_WORKFLOW_FILES[@]}"}")}
}
EOF
  )
}

# ===========================================================================
# Ecosystem & Monorepo Detection
# ===========================================================================

detect_ecosystem() {
  ECOSYSTEM="unknown"; ECOSYSTEMS_DETECTED=()
  [ -f "package.json" ] && ECOSYSTEM="node" && ECOSYSTEMS_DETECTED+=("node")
  ([ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "Pipfile" ]) && ECOSYSTEM="python" && ECOSYSTEMS_DETECTED+=("python")
  [ -f "go.mod" ] && ECOSYSTEM="go" && ECOSYSTEMS_DETECTED+=("go")
  [ -f "Cargo.toml" ] && ECOSYSTEM="rust" && ECOSYSTEMS_DETECTED+=("rust")
  [ -f "Gemfile" ] && ECOSYSTEM="ruby" && ECOSYSTEMS_DETECTED+=("ruby")
  ([ -f "pom.xml" ] || [ -f "build.gradle" ]) && ECOSYSTEMS_DETECTED+=("java")
  [ -f "build.gradle.kts" ] || [ -f "settings.gradle.kts" ] && {
    if compgen -G "src/**/*.kt" >/dev/null 2>&1 || compgen -G "**/*.kt" >/dev/null 2>&1; then
      ECOSYSTEMS_DETECTED+=("kotlin")
    else
      ECOSYSTEMS_DETECTED+=("java")
    fi
  }
  compgen -G "*.csproj" >/dev/null 2>&1 || compgen -G "*.sln" >/dev/null 2>&1 || [ -f "global.json" ] && ECOSYSTEMS_DETECTED+=("csharp")
  [ -f "Package.swift" ] && ECOSYSTEMS_DETECTED+=("swift")
  [ -f "pubspec.yaml" ] && ECOSYSTEM="dart" && ECOSYSTEMS_DETECTED+=("dart")
  [ -f "composer.json" ] && ECOSYSTEM="php" && ECOSYSTEMS_DETECTED+=("php")

  ECOSYSTEM_JSON=$(cat <<EOF
{"primary": "$ECOSYSTEM", "detected": $(json_array "${ECOSYSTEMS_DETECTED[@]+"${ECOSYSTEMS_DETECTED[@]}"}")}
EOF
  )
}

detect_monorepo() {
  local repo="$1"
  local is_mono=false mono_type="none"
  local packages=()

  if [ -f "pnpm-workspace.yaml" ]; then is_mono=true; mono_type="pnpm"
  elif [ -f "lerna.json" ]; then is_mono=true; mono_type="lerna"
  elif [ -f "nx.json" ]; then is_mono=true; mono_type="nx"
  elif [ -f "turbo.json" ]; then is_mono=true; mono_type="turborepo"
  elif [ -f "package.json" ] && grep -q '"workspaces"' package.json 2>/dev/null; then is_mono=true; mono_type="npm-workspaces"
  elif [ -f "Cargo.toml" ] && grep -q '\[workspace\]' Cargo.toml 2>/dev/null; then is_mono=true; mono_type="cargo-workspace"
  elif [ -f "go.work" ]; then is_mono=true; mono_type="go-workspace"
  fi

  if [ "$is_mono" = true ]; then
    for pdir in packages apps libs services modules crates internal cmd; do
      if [ -d "$pdir" ]; then
        while IFS= read -r d; do
          [ -n "$d" ] && packages+=("$(basename "$d")")
        done < <(find "$pdir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
      fi
    done
  fi

  MONOREPO_JSON=$(cat <<EOF
{"is_monorepo": $is_mono, "type": "$mono_type", "packages": $(json_array "${packages[@]+"${packages[@]}"}")}
EOF
  )
}

# ===========================================================================
# Master Runner
# ===========================================================================

run_all_scans() {
  local repo="$1"
  scan_dim1
  scan_dim2 "$repo"
  scan_dim3 "$repo"
  scan_dim4 "$repo"
  scan_dim5 "$repo"
  scan_dim6 "$repo"
  scan_dim7
  scan_dim8
  detect_ecosystem
  detect_monorepo "$repo"
}
