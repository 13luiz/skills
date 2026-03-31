#!/usr/bin/env bash
# harness-audit.sh — Scan a repository for harness engineering readiness
# Usage: bash harness-audit.sh [repo_root]
# Output: JSON object with discovered harness artifacts
set -euo pipefail

REPO="${1:-.}"
cd "$REPO"

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
for name in init.sh setup.sh Makefile docker-compose.yml docker-compose.yaml; do
  [ -f "$name" ] && HAS_INIT_SCRIPT=true && break
done

HAS_PROGRESS_TRACKING=false
for name in progress.txt progress.md; do
  [ -f "$name" ] && HAS_PROGRESS_TRACKING=true && break
done
[ -d "exec-plans" ] || [ -d "docs/exec-plans" ] && HAS_PROGRESS_TRACKING=true

# --- Dimension 8: Safety ---
HAS_CODEOWNERS=false
[ -f "CODEOWNERS" ] || [ -f ".github/CODEOWNERS" ] || [ -f "docs/CODEOWNERS" ] && HAS_CODEOWNERS=true

# --- Package Ecosystem ---
ECOSYSTEM="unknown"
[ -f "package.json" ] && ECOSYSTEM="node"
[ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ] && ECOSYSTEM="python"
[ -f "go.mod" ] && ECOSYSTEM="go"
[ -f "Cargo.toml" ] && ECOSYSTEM="rust"
[ -f "Gemfile" ] && ECOSYSTEM="ruby"

# --- Output JSON ---
cat <<EOF
{
  "repo_root": "$(pwd)",
  "ecosystem": "$ECOSYSTEM",
  "dimensions": {
    "1_architecture_docs": {
      "agent_instruction_files": $(json_array "${AGENT_FILES[@]+"${AGENT_FILES[@]}"}"),
      "docs_exists": $DOCS_EXISTS,
      "docs_has_index": $DOCS_HAS_INDEX,
      "docs_has_architecture": $DOCS_HAS_ARCH
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
  "summary": {
    "agent_files_count": ${#AGENT_FILES[@]},
    "ci_configs_count": ${#CI_CONFIGS[@]},
    "linter_configs_count": ${#LINTER_CONFIGS[@]},
    "type_configs_count": ${#TYPE_CONFIGS[@]},
    "test_dirs_count": ${#TEST_DIRS[@]},
    "test_files_count": $TEST_FILES_COUNT,
    "quick_assessment": "$(
      score=0
      [ ${#AGENT_FILES[@]} -gt 0 ] && score=$((score + 1))
      [ ${#CI_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
      [ ${#LINTER_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
      [ ${#TYPE_CONFIGS[@]} -gt 0 ] && score=$((score + 1))
      [ ${#TEST_DIRS[@]} -gt 0 ] && score=$((score + 1))
      [ "$DOCS_EXISTS" = true ] && score=$((score + 1))
      if [ $score -ge 5 ]; then echo "Good foundation — proceed to detailed audit"
      elif [ $score -ge 3 ]; then echo "Partial harness — significant gaps likely"
      else echo "Minimal harness — expect low scores across most dimensions"
      fi
    )"
  }
}
EOF
