#!/usr/bin/env bash
# harness-audit.sh -- Harness engineering audit scanner
# Responsibility: CLI argument parsing, scoring, output formatting (JSON/Markdown/Blueprint).
# All detection logic lives in dimension-scanners.sh.
#
# Usage: bash harness-audit.sh [repo_root] [options]
# Options:
#   --quick             Quick Audit mode: scan only 15 vital-sign items
#   --profile <type>    Project type profile (see data/profiles.json)
#   --stage <stage>     Lifecycle stage: bootstrap | growth | mature
#   --monorepo          Enable monorepo detection
#   --output <dir>      Output directory for reports (default: stdout)
#   --format <fmt>      Output format: json (default) | markdown
#   --blueprint         Generate actionable blueprint with gap analysis
#   --persist           Save blueprint to harness-system/MASTER.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dimension-scanners.sh"

# ===== Parse arguments =====
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

# ===== Run all dimension scans =====
run_all_scans "$REPO_ABS"

# ===== Quick Assessment =====
score=0
[ ${#AGENT_FILES[@]} -gt 0 ] && score=$((score + 1))
[ ${#CI_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#LINTER_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#TYPE_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
[ ${#TEST_DIRS[@]} -gt 0 ] && score=$((score + 1))
[ "$DOCS_EXISTS" = true ] && score=$((score + 1))

if [ $score -ge 5 ]; then
  QUICK_ASSESSMENT="Good foundation ? proceed to detailed audit"
elif [ $score -ge 3 ]; then
  QUICK_ASSESSMENT="Partial harness ? significant gaps likely"
else
  QUICK_ASSESSMENT="Minimal harness ? expect low scores across most dimensions"
fi

AUDIT_MODE="full"
[ "$QUICK_MODE" = true ] && AUDIT_MODE="quick"

# ===== JSON Output =====
JSON_OUTPUT=$(cat <<EOF
{
  "repo_root": "$REPO_ABS",
  "timestamp": "$TIMESTAMP",
  "ecosystem": $ECOSYSTEM_JSON,
  "audit_mode": "$AUDIT_MODE",
  "profile": "${PROFILE:-auto}",
  "stage": "${STAGE:-auto}",
  "monorepo_mode": $MONOREPO_MODE,
  "dimensions": {
    "1_architecture_docs": $DIM1_JSON,
    "2_mechanical_constraints": $DIM2_JSON,
    "3_observability": $DIM3_JSON,
    "4_testing": $DIM4_JSON,
    "5_context_engineering": $DIM5_JSON,
    "6_entropy_management": $DIM6_JSON,
    "7_long_running": $DIM7_JSON,
    "8_safety": $DIM8_JSON
  },
  "monorepo": $MONOREPO_JSON,
  "summary": {
    "agent_files_count": ${#AGENT_FILES[@]},
    "ci_configs_count": ${#CI_CONFIGS[@]},
    "linter_configs_count": ${#LINTER_CONFIGS[@]},
    "formatter_configs_count": ${#FORMATTER_CONFIGS[@]},
    "type_configs_count": ${#TYPE_CONFIGS[@]},
    "has_precommit": $HAS_PRECOMMIT,
    "test_dirs_count": ${#TEST_DIRS[@]},
    "test_files_count": $TEST_FILES_COUNT,
    "has_feature_tracker": $HAS_FEATURE_TRACKER,
    "has_secret_scanning": $HAS_SECRET_SCANNING,
    "has_mcp_config": $HAS_MCP_CONFIG,
    "quick_assessment": "$QUICK_ASSESSMENT"
  }
}
EOF
)

# ===== Gap Analysis =====
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

# ===== Markdown Report =====
generate_markdown() {
  local REPO_NAME
  REPO_NAME=$(basename "$REPO_ABS")

  local TITLE_PREFIX="Harness Audit"
  [ "$QUICK_MODE" = true ] && TITLE_PREFIX="Quick Harness Audit"

  local precommit_detail="none"
  [ "$HAS_PRECOMMIT" = true ] && precommit_detail="$(IFS=', '; echo "${PRECOMMIT_TOOLS[*]}")"
  local secret_detail="none"
  [ "$HAS_SECRET_SCANNING" = true ] && secret_detail="$(IFS=', '; echo "${SECRET_SCANNING_TOOLS[*]}")"
  local mcp_detail="none"
  [ "$HAS_MCP_CONFIG" = true ] && mcp_detail="$(IFS=', '; echo "${MCP_CONFIG_FILES[*]}")"

  local md=""
  md+="# ${TITLE_PREFIX}: $REPO_NAME"
  md+=$'\n'
  md+=$'\n'"**Date**: $TIMESTAMP"
  md+=$'\n'"**Mode**: $([ "$QUICK_MODE" = true ] && echo "Quick Audit (15 vital-sign items)" || echo "Full Audit")"
  md+=$'\n'"**Profile**: ${PROFILE:-auto} | **Stage**: ${STAGE:-auto} | **Ecosystem**: $ECOSYSTEM"
  md+=$'\n'"**Assessment**: $QUICK_ASSESSMENT"
  md+=$'\n'
  md+=$'\n'"## Scan Results"
  md+=$'\n'
  md+=$'\n'"| Dimension | Finding | Status |"
  md+=$'\n'"|-----------|---------|--------|"
  md+=$'\n'"| Agent instruction files | ${#AGENT_FILES[@]} found | $([ ${#AGENT_FILES[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| docs/ directory | $([ "$DOCS_EXISTS" = true ] && echo "exists" || echo "missing") | $([ "$DOCS_EXISTS" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| ARCHITECTURE.md | $([ "$DOCS_HAS_ARCH" = true ] && echo "exists" || echo "missing") | $([ "$DOCS_HAS_ARCH" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| CI configs | ${#CI_CONFIGS[@]} found | $([ ${#CI_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Linter configs | ${#LINTER_CONFIGS[@]} found | $([ ${#LINTER_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Formatter configs | ${#FORMATTER_CONFIGS[@]} found | $([ ${#FORMATTER_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Type checker configs | ${#TYPE_CONFIGS[@]} found | $([ ${#TYPE_CONFIGS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Pre-commit hooks | $precommit_detail | $([ "$HAS_PRECOMMIT" = true ] && echo "PASS" || echo "INFO") |"
  md+=$'\n'"| Test directories | ${#TEST_DIRS[@]} found ($TEST_FILES_COUNT test files) | $([ ${#TEST_DIRS[@]} -gt 0 ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Feature tracker | $([ "$HAS_FEATURE_TRACKER" = true ] && echo "exists" || echo "none") | $([ "$HAS_FEATURE_TRACKER" = true ] && echo "PASS" || echo "INFO") |"
  md+=$'\n'"| Tech debt tracking | $([ "$HAS_QUALITY_SCORE" = true ] && echo "exists" || echo "missing") | $([ "$HAS_QUALITY_SCORE" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Environment recovery | $([ "$HAS_INIT_SCRIPT" = true ] && echo "exists" || echo "missing") | $([ "$HAS_INIT_SCRIPT" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Progress tracking | $([ "$HAS_PROGRESS_TRACKING" = true ] && echo "exists" || echo "missing") | $([ "$HAS_PROGRESS_TRACKING" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| CODEOWNERS | $([ "$HAS_CODEOWNERS" = true ] && echo "exists" || echo "missing") | $([ "$HAS_CODEOWNERS" = true ] && echo "PASS" || echo "FAIL") |"
  md+=$'\n'"| Secret scanning | $secret_detail | $([ "$HAS_SECRET_SCANNING" = true ] && echo "PASS" || echo "INFO") |"
  md+=$'\n'"| MCP config | $mcp_detail | $([ "$HAS_MCP_CONFIG" = true ] && echo "PASS" || echo "INFO") |"
  md+=$'\n'
  md+=$'\n'"## Detected Files"
  md+=$'\n'
  md+=$'\n'"$([ ${#AGENT_FILES[@]} -gt 0 ] && printf '**Agent files**: %s' "$(IFS=', '; echo "${AGENT_FILES[*]}")" || echo "**Agent files**: none")"
  md+=$'\n'"$([ ${#CI_CONFIGS[@]} -gt 0 ] && printf '**CI configs**: %s' "$(IFS=', '; echo "${CI_CONFIGS[*]}")" || echo "**CI configs**: none")"
  md+=$'\n'"$([ ${#LINTER_CONFIGS[@]} -gt 0 ] && printf '**Linter configs**: %s' "$(IFS=', '; echo "${LINTER_CONFIGS[*]}")" || echo "**Linter configs**: none")"
  md+=$'\n'"$([ ${#FORMATTER_CONFIGS[@]} -gt 0 ] && printf '**Formatter configs**: %s' "$(IFS=', '; echo "${FORMATTER_CONFIGS[*]}")" || echo "**Formatter configs**: none")"
  md+=$'\n'"$([ ${#TYPE_CONFIGS[@]} -gt 0 ] && printf '**Type configs**: %s' "$(IFS=', '; echo "${TYPE_CONFIGS[*]}")" || echo "**Type configs**: none")"
  md+=$'\n'"$([ ${#TEST_DIRS[@]} -gt 0 ] && printf '**Test dirs**: %s' "$(IFS=', '; echo "${TEST_DIRS[*]}")" || echo "**Test dirs**: none")"

  echo "$md"
}

# ===== Blueprint Report =====
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

  for gap in $GAPS; do
    case "$gap" in
      NO_AGENT_FILE)
        cat <<'REC'
### Missing: Agent Instruction File (Dim 1)
- **Impact**: Agents have no project-specific guidance ? they guess at conventions
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
- **Impact**: No mechanical enforcement ? agents can merge broken code
- **Fix**: Add CI using `templates/ci/github-actions/standard-pipeline.yml`
- **Effort**: 1 hour | **Priority**: CRITICAL

REC
        ;;
      NO_LINTER)
        cat <<'REC'
### Missing: Linter Configuration (Dim 2)
- **Impact**: No style or correctness enforcement on agent-generated code
- **Fix**: Add linter config for your ecosystem (see `data/ecosystems.json`)
- **Effort**: 30 min | **Priority**: CRITICAL

REC
        ;;
      NO_TYPE_CHECKER)
        cat <<'REC'
### Missing: Type Checker (Dim 2)
- **Impact**: Agent can produce type-unsafe code that passes CI
- **Fix**: Add type checking in strict mode (see `data/ecosystems.json`)
- **Effort**: 1 hour | **Priority**: CRITICAL

REC
        ;;
      NO_TESTS)
        cat <<'REC'
### Missing: Test Suite (Dim 4)
- **Impact**: No regression detection ? agent changes may silently break features
- **Fix**: Create test directory and add initial tests for core modules
- **Effort**: 2-4 hours | **Priority**: CRITICAL

REC
        ;;
      NO_TECH_DEBT_TRACKING)
        cat <<'REC'
### Missing: Tech Debt Tracking (Dim 6)
- **Impact**: Quality degradation invisible until crisis
- **Fix**: Add `templates/universal/tech-debt-tracker.json` to track quality scores
- **Effort**: 15 min | **Priority**: LOW

REC
        ;;
      NO_ENV_RECOVERY)
        cat <<'REC'
### Missing: Environment Recovery Script (Dim 7)
- **Impact**: Agents cannot reliably bootstrap development environment
- **Fix**: Create init script using `templates/init/init.sh` or `init.ps1`
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
  [ $win_num -eq 1 ] && echo "No critical gaps found ? focus on deepening existing checks."
  echo ""

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

# ===== Write Output =====
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
    if [ "$BLUEPRINT_MODE" = true ]; then SUFFIX="blueprint"
    elif [ "$QUICK_MODE" = true ]; then SUFFIX="quick-audit"
    else SUFFIX="audit"; fi
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
