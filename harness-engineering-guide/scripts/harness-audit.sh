#!/usr/bin/env bash
# harness-audit.sh — Enhanced harness engineering audit scanner
# Usage: bash harness-audit.sh [repo_root] [options]
# Options:
#   --profile <type>    Project type profile (see data/profiles.json)
#   --stage <stage>     Lifecycle stage: bootstrap | growth | mature
#   --monorepo          Enable monorepo detection (discovers packages; per-package audit requires agent iteration)
#   --output <dir>      Output directory for reports (default: stdout)
#   --format <fmt>      Output format: json (default). Note: markdown generation requires agent post-processing.
# Output: JSON object with discovered harness artifacts and content analysis
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
OUTPUT_DIR=""
OUTPUT_FORMAT="json"

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --monorepo) MONOREPO_MODE=true; shift ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --format) OUTPUT_FORMAT="$2"; shift 2 ;;
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

# --- Output JSON ---
OUTPUT=$(cat <<EOF
{
  "repo_root": "$REPO_ABS",
  "timestamp": "$TIMESTAMP",
  "ecosystem": "$ECOSYSTEM",
  "ecosystems_detected": $(json_array "${ECOSYSTEMS_DETECTED[@]+"${ECOSYSTEMS_DETECTED[@]}"}"),
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

# --- Write output ---
if [ -n "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
  REPO_NAME=$(basename "$REPO_ABS")
  DATE_STR=$(date +%Y-%m-%d)
  FILENAME="${DATE_STR}_${REPO_NAME}_audit"
  echo "$OUTPUT" > "$OUTPUT_DIR/${FILENAME}.json"
  echo "Audit JSON written to $OUTPUT_DIR/${FILENAME}.json"
  if [ "$OUTPUT_FORMAT" = "markdown" ]; then
    echo "Note: Markdown report generation requires agent post-processing of the JSON output."
    echo "See examples/sample-audit-report.md for the expected report format."
  fi
else
  echo "$OUTPUT"
fi
