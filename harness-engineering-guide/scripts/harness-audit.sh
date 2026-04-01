#!/usr/bin/env bash
# harness-audit.sh — Enhanced harness engineering audit scanner
# Usage: bash harness-audit.sh [repo_root] [options]
# Options:
#   --quick             Quick Audit mode: scan only 15 vital-sign items across all 8 dimensions
#   --profile <type>    Project type profile (see data/profiles.json)
#   --stage <stage>     Lifecycle stage: bootstrap | growth | mature
#   --monorepo          Enable monorepo detection (discovers packages; per-package audit requires agent iteration)
#   --output <dir>      Output directory for reports (default: stdout)
#   --format <fmt>      Output format: json (default) | markdown
#   --blueprint         Generate actionable blueprint with gap analysis and template recommendations
#   --persist           Generate blueprint and save to harness-system/MASTER.md in the repo
# Output: JSON, Markdown scan report, or Markdown blueprint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

# Source content analyzers
source "$SCRIPT_DIR/utils/content-analyzers.sh"

# --- Parse arguments ---
REPO=""
PROFILE=""
STAGE=""
MONOREPO_MODE=false
QUICK_MODE=false
OUTPUT_DIR=""
OUTPUT_FORMAT="json"
BLUEPRINT_MODE=false
PERSIST_MODE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --quick) QUICK_MODE=true; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --monorepo) MONOREPO_MODE=true; shift ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --format) OUTPUT_FORMAT="$2"; shift 2 ;;
    --blueprint) BLUEPRINT_MODE=true; OUTPUT_FORMAT="markdown"; shift ;;
    --persist) PERSIST_MODE=true; BLUEPRINT_MODE=true; OUTPUT_FORMAT="markdown"; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) REPO="$1"; shift ;;
  esac
done

REPO="${REPO:-.}"
cd "$REPO"
REPO_ABS="$(pwd)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"

# --- Helper functions ---
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

# --- Dimension 1: Agent Instruction Files ---
AGENT_FILES=()
for name in AGENTS.md CLAUDE.md CODEX.md .cursorrules; do
  while IFS= read -r f; do
    [ -n "$f" ] && AGENT_FILES+=("$f")
  done < <(find_files "$name")
done
while IFS= read -r f; do
  [ -n "$f" ] && AGENT_FILES+=("$f")
done < <(find . -maxdepth 4 -path "*/.cursor/rules/*.md" -print 2>/dev/null | sed 's|^\./||' | sort)

# --- Dimension 1: Docs Structure ---
DOCS_EXISTS=false
DOCS_HAS_INDEX=false
DOCS_HAS_ARCH=false
if [ -d "docs" ]; then
  DOCS_EXISTS=true
  for idx in docs/index.md docs/INDEX.md docs/README.md; do
    [ -f "$idx" ] && DOCS_HAS_INDEX=true && break
  done
  for arch in docs/ARCHITECTURE.md ARCHITECTURE.md; do
    [ -f "$arch" ] && DOCS_HAS_ARCH=true && break
  done
fi

# Check for ADR/design doc directories
HAS_DESIGN_DOCS=false
for dd in docs/design-docs docs/adr docs/adrs docs/decisions docs/exec-plans; do
  [ -d "$dd" ] && HAS_DESIGN_DOCS=true && break
done

# --- Dimension 2: CI Configs ---
CI_CONFIGS=()
while IFS= read -r f; do
  [ -n "$f" ] && CI_CONFIGS+=("$f")
done < <(find . -maxdepth 4 -path "./.git" -prune -o \( \
  -path "*/.github/workflows/*.yml" -o \
  -path "*/.github/workflows/*.yaml" -o \
  -name ".gitlab-ci.yml" -o \
  -name "Jenkinsfile" -o \
  -name "azure-pipelines.yml" -o \
  -name ".circleci/config.yml" \
  \) -print 2>/dev/null | sed 's|^\./||' | sort)

# --- Dimension 2: Linter/Formatter Configs ---
LINTER_CONFIGS=()
for name in .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml eslint.config.js eslint.config.mjs \
  .prettierrc .prettierrc.json .prettierrc.yml prettier.config.js \
  biome.json biome.jsonc \
  ruff.toml .flake8 .pylintrc \
  .golangci.yml .golangci.yaml \
  clippy.toml .clippy.toml \
  .rubocop.yml \
  checkstyle.xml \
  .swiftlint.yml \
  analysis_options.yaml \
  detekt.yml \
  .editorconfig; do
  while IFS= read -r f; do
    [ -n "$f" ] && LINTER_CONFIGS+=("$f")
  done < <(find_files "$name")
done

# --- Dimension 2: Type Checking ---
TYPE_CONFIGS=()
for name in tsconfig.json mypy.ini .mypy.ini pyrightconfig.json; do
  while IFS= read -r f; do
    [ -n "$f" ] && TYPE_CONFIGS+=("$f")
  done < <(find_files "$name")
done
if [ -f "pyproject.toml" ] && grep -q "\[tool\.mypy\]\|\[tool\.pyright\]" pyproject.toml 2>/dev/null; then
  TYPE_CONFIGS+=("pyproject.toml (type config)")
fi

# --- Dimension 4: Test Directories ---
TEST_DIRS=()
for name in tests __tests__ test spec; do
  while IFS= read -r d; do
    [ -n "$d" ] && TEST_DIRS+=("$d")
  done < <(find_dirs "$name")
done
TEST_FILES_COUNT=$(find . -maxdepth 5 -path "./.git" -prune -o \( \
  -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \
  \) -print 2>/dev/null | wc -l | tr -d ' ')

# --- Dimension 6: Golden Principles / Tech Debt ---
HAS_QUALITY_SCORE=false
for name in QUALITY_SCORE.md quality-score.md tech-debt-tracker.json; do
  [ -f "$name" ] || [ -f "docs/$name" ] && HAS_QUALITY_SCORE=true && break
done

# --- Dimension 7: Long-Running Support ---
HAS_INIT_SCRIPT=false
for name in init.sh setup.sh Makefile docker-compose.yml docker-compose.yaml devcontainer.json; do
  [ -f "$name" ] && HAS_INIT_SCRIPT=true && break
done
[ -d ".devcontainer" ] && HAS_INIT_SCRIPT=true

HAS_PROGRESS_TRACKING=false
for name in progress.txt progress.md progress.json; do
  [ -f "$name" ] && HAS_PROGRESS_TRACKING=true && break
done
[ -d "exec-plans" ] || [ -d "docs/exec-plans" ] && HAS_PROGRESS_TRACKING=true

# --- Dimension 8: Safety ---
HAS_CODEOWNERS=false
[ -f "CODEOWNERS" ] || [ -f ".github/CODEOWNERS" ] || [ -f "docs/CODEOWNERS" ] && HAS_CODEOWNERS=true

# --- Package Ecosystem ---
ECOSYSTEM="unknown"
ECOSYSTEMS_DETECTED=()
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

# --- Content Analysis (new deep inspection) ---
CONTENT_ANALYSIS=$(run_content_analysis "$REPO_ABS")

# --- Quick Assessment ---
score=0
[ ${#AGENT_FILES[@]} -gt 0 ] && score=$((score + 1))
[ ${#CI_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#LINTER_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#TYPE_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#TEST_DIRS[@]} -gt 0 ] && score=$((score + 1))
[ "$DOCS_EXISTS" = true ] && score=$((score + 1))

if [ $score -ge 5 ]; then
  QUICK_ASSESSMENT="Good foundation — proceed to detailed audit"
elif [ $score -ge 3 ]; then
  QUICK_ASSESSMENT="Partial harness — significant gaps likely"
else
  QUICK_ASSESSMENT="Minimal harness — expect low scores across most dimensions"
fi

AUDIT_MODE="full"
[ "$QUICK_MODE" = true ] && AUDIT_MODE="quick"

# --- Build JSON output ---
JSON_OUTPUT=$(cat <<EOF
{
  "repo_root": "$REPO_ABS",
  "timestamp": "$TIMESTAMP",
  "ecosystem": "$ECOSYSTEM",
  "ecosystems_detected": $(json_array "${ECOSYSTEMS_DETECTED[@]+"${ECOSYSTEMS_DETECTED[@]}"}"),
  "audit_mode": "$AUDIT_MODE",
  "profile": "${PROFILE:-auto}",
  "stage": "${STAGE:-auto}",
  "monorepo_mode": $MONOREPO_MODE,
  "dimensions": {
    "1_architecture_docs": {
      "agent_instruction_files": $(json_array "${AGENT_FILES[@]+"${AGENT_FILES[@]}"}"),
      "docs_exists": $DOCS_EXISTS,
      "docs_has_index": $DOCS_HAS_INDEX,
      "docs_has_architecture": $DOCS_HAS_ARCH,
      "has_design_docs": $HAS_DESIGN_DOCS
    },
    "2_mechanical_constraints": {
      "ci_configs": $(json_array "${CI_CONFIGS[@]+"${CI_CONFIGS[@]}"}"),
      "linter_configs": $(json_array "${LINTER_CONFIGS[@]+"${LINTER_CONFIGS[@]}"}"),
      "type_configs": $(json_array "${TYPE_CONFIGS[@]+"${TYPE_CONFIGS[@]}"}")
    },
    "4_testing": {
      "test_dirs": $(json_array "${TEST_DIRS[@]+"${TEST_DIRS[@]}"}"),
      "test_files_count": $TEST_FILES_COUNT
    },
    "6_entropy_management": {
      "has_quality_score": $HAS_QUALITY_SCORE
    },
    "7_long_running": {
      "has_init_script": $HAS_INIT_SCRIPT,
      "has_progress_tracking": $HAS_PROGRESS_TRACKING
    },
    "8_safety": {
      "has_codeowners": $HAS_CODEOWNERS
    }
  },
  "content_analysis": $CONTENT_ANALYSIS,
  "summary": {
    "agent_files_count": ${#AGENT_FILES[@]},
    "ci_configs_count": ${#CI_CONFIGS[@]},
    "linter_configs_count": ${#LINTER_CONFIGS[@]},
    "type_configs_count": ${#TYPE_CONFIGS[@]},
    "test_dirs_count": ${#TEST_DIRS[@]},
    "test_files_count": $TEST_FILES_COUNT,
    "quick_assessment": "$QUICK_ASSESSMENT"
  }
}
EOF
)

# --- Gap analysis for blueprint/markdown ---
generate_gaps() {
  local gaps=()
  [ ${#AGENT_FILES[@]} -eq 0 ] && gaps+=("NO_AGENT_FILE")
  [ "$DOCS_EXISTS" = false ] && gaps+=("NO_DOCS_DIR")
  [ "$DOCS_HAS_ARCH" = false ] && gaps+=("NO_ARCHITECTURE_DOC")
  [ "$HAS_DESIGN_DOCS" = false ] && gaps+=("NO_DESIGN_DOCS")
  [ ${#CI_CONFIGS[@]} -eq 0 ] && gaps+=("NO_CI_PIPELINE")
  [ ${#LINTER_CONFIGS[@]} -eq 0 ] && gaps+=("NO_LINTER")
  [ ${#TYPE_CONFIGS[@]} -eq 0 ] && gaps+=("NO_TYPE_CHECKER")
  [ ${#TEST_DIRS[@]} -eq 0 ] && gaps+=("NO_TESTS")
  [ "$HAS_QUALITY_SCORE" = false ] && gaps+=("NO_TECH_DEBT_TRACKING")
  [ "$HAS_INIT_SCRIPT" = false ] && gaps+=("NO_ENV_RECOVERY")
  [ "$HAS_PROGRESS_TRACKING" = false ] && gaps+=("NO_PROGRESS_TRACKING")
  [ "$HAS_CODEOWNERS" = false ] && gaps+=("NO_CODEOWNERS")
  echo "${gaps[@]}"
}

generate_markdown() {
  local REPO_NAME
  REPO_NAME=$(basename "$REPO_ABS")
  local GAPS
  GAPS=$(generate_gaps)

  local TITLE_PREFIX="Harness Audit"
  [ "$QUICK_MODE" = true ] && TITLE_PREFIX="Quick Harness Audit"
  cat <<MDEOF
# ${TITLE_PREFIX}: $REPO_NAME

**Date**: $TIMESTAMP
**Mode**: $([ "$QUICK_MODE" = true ] && echo "Quick Audit (15 vital-sign items)" || echo "Full Audit")
**Profile**: ${PROFILE:-auto} | **Stage**: ${STAGE:-auto} | **Ecosystem**: $ECOSYSTEM
**Assessment**: $QUICK_ASSESSMENT

## Scan Results

| Dimension | Finding | Status |
|-----------|---------|--------|
| Agent instruction files | ${#AGENT_FILES[@]} found | $([ ${#AGENT_FILES[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |
| docs/ directory | $([ "$DOCS_EXISTS" = true ] && echo "exists" || echo "missing") | $([ "$DOCS_EXISTS" = true ] && echo "PASS" || echo "FAIL") |
| ARCHITECTURE.md | $([ "$DOCS_HAS_ARCH" = true ] && echo "exists" || echo "missing") | $([ "$DOCS_HAS_ARCH" = true ] && echo "PASS" || echo "FAIL") |
| CI configs | ${#CI_CONFIGS[@]} found | $([ ${#CI_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |
| Linter configs | ${#LINTER_CONFIGS[@]} found | $([ ${#LINTER_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |
| Type checker configs | ${#TYPE_CONFIGS[@]} found | $([ ${#TYPE_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |
| Test directories | ${#TEST_DIRS[@]} found ($TEST_FILES_COUNT test files) | $([ ${#TEST_DIRS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |
| Tech debt tracking | $([ "$HAS_QUALITY_SCORE" = true ] && echo "exists" || echo "missing") | $([ "$HAS_QUALITY_SCORE" = true ] && echo "PASS" || echo "FAIL") |
| Environment recovery | $([ "$HAS_INIT_SCRIPT" = true ] && echo "exists" || echo "missing") | $([ "$HAS_INIT_SCRIPT" = true ] && echo "PASS" || echo "FAIL") |
| Progress tracking | $([ "$HAS_PROGRESS_TRACKING" = true ] && echo "exists" || echo "missing") | $([ "$HAS_PROGRESS_TRACKING" = true ] && echo "PASS" || echo "FAIL") |
| CODEOWNERS | $([ "$HAS_CODEOWNERS" = true ] && echo "exists" || echo "missing") | $([ "$HAS_CODEOWNERS" = true ] && echo "PASS" || echo "FAIL") |

## Detected Files

$([ ${#AGENT_FILES[@]} -gt 0 ] && printf '**Agent files**: %s\n' "$(IFS=', '; echo "${AGENT_FILES[*]}")" || echo "**Agent files**: none")
$([ ${#CI_CONFIGS[@]} -gt 0 ] && printf '**CI configs**: %s\n' "$(IFS=', '; echo "${CI_CONFIGS[*]}")" || echo "**CI configs**: none")
$([ ${#LINTER_CONFIGS[@]} -gt 0 ] && printf '**Linter configs**: %s\n' "$(IFS=', '; echo "${LINTER_CONFIGS[*]}")" || echo "**Linter configs**: none")
$([ ${#TYPE_CONFIGS[@]} -gt 0 ] && printf '**Type configs**: %s\n' "$(IFS=', '; echo "${TYPE_CONFIGS[*]}")" || echo "**Type configs**: none")
$([ ${#TEST_DIRS[@]} -gt 0 ] && printf '**Test dirs**: %s\n' "$(IFS=', '; echo "${TEST_DIRS[*]}")" || echo "**Test dirs**: none")
MDEOF
}

generate_blueprint() {
  local REPO_NAME
  REPO_NAME=$(basename "$REPO_ABS")
  local GAPS
  GAPS=$(generate_gaps)

  generate_markdown

  cat <<BPEOF

---

## Gap Analysis & Recommendations

BPEOF

  # Map each gap to a recommendation
  for gap in $GAPS; do
    case "$gap" in
      NO_AGENT_FILE)
        cat <<'REC'
### Missing: Agent Instruction File (Dim 1)
- **Impact**: Agents have no project-specific guidance — they guess at conventions
- **Fix**: Create AGENTS.md using `templates/universal/agents-md-scaffold.md`
- **Effort**: 30 min | **Priority**: HIGH

REC
        ;;
      NO_DOCS_DIR)
        cat <<'REC'
### Missing: Structured docs/ Directory (Dim 1)
- **Impact**: No organized knowledge base for agents to reference
- **Fix**: Create `docs/` with an `index.md` and at least architecture + conventions subdocs
- **Effort**: 1-2 hours | **Priority**: MEDIUM

REC
        ;;
      NO_ARCHITECTURE_DOC)
        cat <<'REC'
### Missing: Architecture Documentation (Dim 1)
- **Impact**: Agents cannot understand domain boundaries or dependency rules
- **Fix**: Create `ARCHITECTURE.md` with module boundaries, dependency directions, and key abstractions
- **Effort**: 1-2 hours | **Priority**: HIGH

REC
        ;;
      NO_CI_PIPELINE)
        cat <<'REC'
### Missing: CI Pipeline (Dim 2)
- **Impact**: No mechanical enforcement — agents can merge broken code
- **Fix**: Add CI using `templates/ci/github-actions/standard-pipeline.yml` (or gitlab-ci.yml / azure-pipelines.yml)
- **Effort**: 1 hour | **Priority**: CRITICAL

REC
        ;;
      NO_LINTER)
        cat <<'REC'
### Missing: Linter Configuration (Dim 2)
- **Impact**: No style or correctness enforcement on agent-generated code
- **Fix**: Add linter config for your ecosystem (see `data/ecosystems.json` for recommendations)
- **Effort**: 30 min | **Priority**: CRITICAL

REC
        ;;
      NO_TYPE_CHECKER)
        cat <<'REC'
### Missing: Type Checker (Dim 2)
- **Impact**: Agent can produce type-unsafe code that passes CI
- **Fix**: Add type checking in strict mode (see `data/ecosystems.json` for ecosystem-specific setup)
- **Effort**: 1 hour | **Priority**: CRITICAL

REC
        ;;
      NO_TESTS)
        cat <<'REC'
### Missing: Test Suite (Dim 4)
- **Impact**: No regression detection — agent changes may silently break features
- **Fix**: Create test directory and add initial tests for core modules
- **Effort**: 2-4 hours | **Priority**: CRITICAL

REC
        ;;
      NO_TECH_DEBT_TRACKING)
        cat <<'REC'
### Missing: Tech Debt Tracking (Dim 6)
- **Impact**: Quality degradation invisible until crisis
- **Fix**: Add `templates/universal/tech-debt-tracker.json` to track quality scores per module
- **Effort**: 15 min | **Priority**: LOW

REC
        ;;
      NO_ENV_RECOVERY)
        cat <<'REC'
### Missing: Environment Recovery Script (Dim 7)
- **Impact**: Agents cannot reliably bootstrap development environment
- **Fix**: Create init script using `templates/init/init.sh` or `templates/init/init.ps1`
- **Effort**: 30 min | **Priority**: MEDIUM

REC
        ;;
      NO_PROGRESS_TRACKING)
        cat <<'REC'
### Missing: Progress Tracking (Dim 7)
- **Impact**: No structured handoff between agent sessions
- **Fix**: Add execution plan template from `templates/universal/execution-plan.md`
- **Effort**: 15 min | **Priority**: LOW

REC
        ;;
      NO_CODEOWNERS)
        cat <<'REC'
### Missing: CODEOWNERS (Dim 8)
- **Impact**: No enforced review for security-critical paths
- **Fix**: Create `.github/CODEOWNERS` mapping critical paths to reviewers
- **Effort**: 15 min | **Priority**: MEDIUM

REC
        ;;
    esac
  done

  # Quick wins section
  cat <<QWEOF
## Quick Wins (implement today)

QWEOF

  local win_num=1
  for gap in $GAPS; do
    case "$gap" in
      NO_AGENT_FILE) echo "$win_num. Create AGENTS.md from scaffold template"; win_num=$((win_num+1)) ;;
      NO_CI_PIPELINE) echo "$win_num. Add CI pipeline from templates/ci/"; win_num=$((win_num+1)) ;;
      NO_LINTER) echo "$win_num. Add linter config for $ECOSYSTEM ecosystem"; win_num=$((win_num+1)) ;;
      NO_TYPE_CHECKER) echo "$win_num. Enable type checking in strict mode"; win_num=$((win_num+1)) ;;
      NO_TESTS) echo "$win_num. Create initial test suite with CI integration"; win_num=$((win_num+1)) ;;
    esac
  done
  [ $win_num -eq 1 ] && echo "No critical gaps found — focus on deepening existing checks."
  echo ""

  # Recommended templates section
  cat <<TMEOF
## Recommended Templates

| Gap | Template Path |
|-----|---------------|
TMEOF

  for gap in $GAPS; do
    case "$gap" in
      NO_AGENT_FILE)      echo "| Agent instruction file | \`templates/universal/agents-md-scaffold.md\` |" ;;
      NO_CI_PIPELINE)     echo "| CI pipeline (GitHub) | \`templates/ci/github-actions/standard-pipeline.yml\` |" ;;
      NO_TECH_DEBT_TRACKING) echo "| Tech debt tracker | \`templates/universal/tech-debt-tracker.json\` |" ;;
      NO_ENV_RECOVERY)    echo "| Environment recovery | \`templates/init/init.sh\` / \`templates/init/init.ps1\` |" ;;
      NO_PROGRESS_TRACKING) echo "| Task decomposition | \`templates/universal/execution-plan.md\` |" ;;
    esac
  done
  echo ""

  # Ecosystem-specific CI commands
  cat <<CIEOF
## Ecosystem CI Commands ($ECOSYSTEM)

Populate your CI pipeline with these commands (from \`data/ecosystems.json\`):

CIEOF

  case "$ECOSYSTEM" in
    node)
      cat <<'NODEEOF'
| Step | Command |
|------|---------|
| Install | `npm ci --silent` |
| Lint | `npx eslint . && npx biome check .` |
| Typecheck | `npx tsc --noEmit` |
| Test | `npx vitest run --coverage` |
| Build | `npm run build` |
| Format check | `npx biome format --check . \|\| npx prettier --check .` |
NODEEOF
      ;;
    python)
      cat <<'PYEOF'
| Step | Command |
|------|---------|
| Install | `pip install -e '.[dev]' \|\| pip install -r requirements.txt` |
| Lint | `ruff check .` |
| Typecheck | `mypy src/` |
| Test | `pytest --cov=src --cov-fail-under=80` |
| Format check | `ruff format --check .` |
PYEOF
      ;;
    go)
      cat <<'GOEOF'
| Step | Command |
|------|---------|
| Install | `go mod download` |
| Lint | `golangci-lint run` |
| Typecheck | `go vet ./...` |
| Test | `go test -race -coverprofile=coverage.out ./...` |
| Build | `go build ./...` |
| Format check | `gofmt -l . \| (! grep .)` |
GOEOF
      ;;
    rust)
      cat <<'RUSTEOF'
| Step | Command |
|------|---------|
| Install | `cargo fetch` |
| Lint | `cargo clippy -- -D warnings` |
| Typecheck | `cargo check` |
| Test | `cargo test` |
| Build | `cargo build --release` |
| Format check | `cargo fmt --check` |
RUSTEOF
      ;;
    *)
      echo "See \`data/ecosystems.json\` for $ECOSYSTEM-specific commands."
      ;;
  esac

  cat <<NEOF

---

*Blueprint generated by harness-audit.sh. For full scoring, run the agent-led audit (Mode 1 in SKILL.md). Use --quick for a 15-item vital-sign check.*
*Profile and stage weight tables are in \`data/profiles.json\` and \`data/stages.json\`.*
NEOF
}

# --- Write output ---
REPO_NAME=$(basename "$REPO_ABS")
DATE_STR=$(date +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

if [ "$BLUEPRINT_MODE" = true ]; then
  FINAL_OUTPUT=$(generate_blueprint)
elif [ "$OUTPUT_FORMAT" = "markdown" ]; then
  FINAL_OUTPUT=$(generate_markdown)
else
  FINAL_OUTPUT="$JSON_OUTPUT"
fi

if [ "$PERSIST_MODE" = true ]; then
  HARNESS_DIR="$REPO_ABS/harness-system"
  mkdir -p "$HARNESS_DIR/modules"
  echo "$FINAL_OUTPUT" > "$HARNESS_DIR/MASTER.md"
  echo "Harness blueprint persisted to $HARNESS_DIR/MASTER.md" >&2
  echo "Add module overrides in $HARNESS_DIR/modules/ (e.g. ci.md, testing.md)" >&2
elif [ -n "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
  if [ "$OUTPUT_FORMAT" = "markdown" ] || [ "$BLUEPRINT_MODE" = true ]; then
    EXT="md"
    if [ "$BLUEPRINT_MODE" = true ]; then
      SUFFIX="blueprint"
    elif [ "$QUICK_MODE" = true ]; then
      SUFFIX="quick-audit"
    else
      SUFFIX="audit"
    fi
  else
    EXT="json"
    SUFFIX=$([ "$QUICK_MODE" = true ] && echo "quick-audit" || echo "audit")
  fi
  FILENAME="${DATE_STR}_${REPO_NAME}_${SUFFIX}.${EXT}"
  echo "$FINAL_OUTPUT" > "$OUTPUT_DIR/${FILENAME}"
  echo "Output written to $OUTPUT_DIR/${FILENAME}" >&2
else
  echo "$FINAL_OUTPUT"
fi
