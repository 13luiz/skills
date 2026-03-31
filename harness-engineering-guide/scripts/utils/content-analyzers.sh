#!/usr/bin/env bash
# content-analyzers.sh — Content-level analysis functions for harness audit
# Sourced by harness-audit.sh to provide deep inspection beyond file existence.
# These functions grep file contents to assess Dim 3 (Observability),
# Dim 5 (Context Engineering), and Dim 6 (Entropy Management).
set -euo pipefail

# ---------------------------------------------------------------------------
# Dim 3: Feedback Loops & Observability
# ---------------------------------------------------------------------------

analyze_structured_logging() {
  local repo="$1"
  local found_frameworks=()
  local node_loggers="winston|pino|bunyan|consola|log4js"
  local python_loggers="loguru|structlog|import logging"
  local go_loggers="go\.uber\.org/zap|logrus|zerolog|log/slog"
  local rust_loggers="tracing::|env_logger|slog"
  local java_loggers="org\.slf4j|ch\.qos\.logback|org\.apache\.logging\.log4j"
  local csharp_loggers="Serilog|NLog|Microsoft\.Extensions\.Logging"
  local ruby_loggers="Rails\.logger|SemanticLogger|Logger\.new"

  local all_patterns="${node_loggers}|${python_loggers}|${go_loggers}|${rust_loggers}|${java_loggers}|${csharp_loggers}|${ruby_loggers}"

  local matches
  matches=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' --include='*.kt' --include='*.cs' --include='*.rb' \
    -E "$all_patterns" "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')

  local has_print_only=false
  if [ "$matches" -eq 0 ]; then
    local print_count
    print_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
      --include='*.rs' --include='*.java' --include='*.kt' --include='*.cs' \
      -E "console\.(log|error|warn)|print\(|fmt\.Print|println!|System\.out\.print" \
      "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')
    [ "$print_count" -gt 0 ] && has_print_only=true
  fi

  echo "{\"logging_framework_files\": $matches, \"print_only\": $has_print_only}"
}

analyze_metrics_tracing() {
  local repo="$1"
  local otel_patterns="opentelemetry|@opentelemetry|go\.opentelemetry\.io|OpenTelemetry"
  local metrics_patterns="prometheus|prom-client|prometheus_client|micrometer|Prometheus\.NET"
  local tracing_patterns="jaeger|zipkin|datadog|newrelic|sentry"

  local otel_count metrics_count tracing_count
  otel_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' --include='*.kt' --include='*.cs' --include='*.toml' \
    --include='*.json' --include='*.yaml' --include='*.yml' \
    -E "$otel_patterns" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')
  metrics_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' --include='*.toml' --include='*.json' \
    -E "$metrics_patterns" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')
  tracing_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.yaml' --include='*.yml' --include='*.json' --include='*.toml' \
    -E "$tracing_patterns" "$repo" 2>/dev/null | head -10 | wc -l | tr -d ' ')

  echo "{\"opentelemetry_files\": $otel_count, \"metrics_files\": $metrics_count, \"tracing_files\": $tracing_count}"
}

analyze_ui_visibility() {
  local repo="$1"
  local patterns="playwright|puppeteer|cypress|@testing-library|chromedp|selenium|capybara"
  local config_files=""
  local dep_count

  for cfg in "playwright.config" "cypress.config" "cypress.json" ".puppeteerrc"; do
    [ -f "$repo/$cfg.ts" ] || [ -f "$repo/$cfg.js" ] || [ -f "$repo/$cfg" ] && config_files="$config_files $cfg"
  done
  [ -d "$repo/e2e" ] && config_files="$config_files e2e/"

  dep_count=$(grep -rl --include='*.json' --include='*.toml' --include='*.txt' --include='*.cfg' \
    -E "$patterns" "$repo" 2>/dev/null | head -5 | wc -l | tr -d ' ')

  echo "{\"e2e_config_files\": \"${config_files# }\", \"e2e_dependency_files\": $dep_count}"
}

analyze_error_context() {
  local repo="$1"
  local structured_errors=0
  local generic_errors=0

  structured_errors=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' \
    -E "class \w+Error|new Error\(|raise \w+Error|errors\.New|anyhow!|thiserror" \
    "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')

  generic_errors=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    -E "catch\s*\(\s*\)|except:|except Exception|recover\(\)" \
    "$repo" 2>/dev/null | head -20 | wc -l | tr -d ' ')

  echo "{\"custom_error_files\": $structured_errors, \"generic_catch_files\": $generic_errors}"
}

# ---------------------------------------------------------------------------
# Dim 5: Context Engineering
# ---------------------------------------------------------------------------

analyze_agent_file_quality() {
  local repo="$1"
  local agent_files=("AGENTS.md" "CLAUDE.md" "CODEX.md")
  local result="{}"

  for af in "${agent_files[@]}"; do
    if [ -f "$repo/$af" ]; then
      local line_count
      line_count=$(wc -l < "$repo/$af" | tr -d ' ')
      local has_links
      has_links=$(grep -c -E '\[.*\]\(.*\)|see |refer to |docs/' "$repo/$af" 2>/dev/null || echo "0")
      local has_commands
      has_commands=$(grep -c -E '^\s*```|npm |yarn |pnpm |pip |cargo |go |make |docker' "$repo/$af" 2>/dev/null || echo "0")
      result="{\"file\": \"$af\", \"line_count\": $line_count, \"doc_links\": $has_links, \"command_refs\": $has_commands}"
      break
    fi
  done

  echo "$result"
}

analyze_docs_structure() {
  local repo="$1"
  local docs_dir="$repo/docs"

  if [ ! -d "$docs_dir" ]; then
    echo "{\"exists\": false, \"has_index\": false, \"subdirs\": 0, \"total_files\": 0}"
    return
  fi

  local has_index=false
  for idx in "index.md" "INDEX.md" "README.md"; do
    [ -f "$docs_dir/$idx" ] && has_index=true && break
  done

  local subdirs
  subdirs=$(find "$docs_dir" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
  local total_files
  total_files=$(find "$docs_dir" -type f -name '*.md' | wc -l | tr -d ' ')

  echo "{\"exists\": true, \"has_index\": $has_index, \"subdirs\": $subdirs, \"total_files\": $total_files}"
}

analyze_llms_txt() {
  local repo="$1"
  local has_llms_txt=false
  local has_llms_full=false
  [ -f "$repo/llms.txt" ] && has_llms_txt=true
  [ -f "$repo/llms-full.txt" ] && has_llms_full=true
  echo "{\"llms_txt\": $has_llms_txt, \"llms_full_txt\": $has_llms_full}"
}

analyze_structured_state() {
  local repo="$1"
  local state_files=()

  for sf in "progress.json" "features.json" "feature-checklist.json" "progress.txt" "progress.md"; do
    [ -f "$repo/$sf" ] && state_files+=("$sf")
  done

  local artifact_dirs=()
  for ad in "reports" "artifacts" "output" ".artifacts"; do
    [ -d "$repo/$ad" ] && artifact_dirs+=("$ad")
  done

  local sf_json="[]"
  local ad_json="[]"
  if [ ${#state_files[@]} -gt 0 ]; then
    sf_json=$(printf '"%s",' "${state_files[@]}" | sed 's/,$//')
    sf_json="[$sf_json]"
  fi
  if [ ${#artifact_dirs[@]} -gt 0 ]; then
    ad_json=$(printf '"%s",' "${artifact_dirs[@]}" | sed 's/,$//')
    ad_json="[$ad_json]"
  fi

  echo "{\"state_files\": $sf_json, \"artifact_dirs\": $ad_json}"
}

# ---------------------------------------------------------------------------
# Dim 6: Entropy Management & Garbage Collection
# ---------------------------------------------------------------------------

analyze_golden_principles() {
  local repo="$1"
  local principle_refs=0

  for pf in "AGENTS.md" "CLAUDE.md" "CODEX.md" "docs/PRINCIPLES.md" "docs/CONVENTIONS.md"; do
    if [ -f "$repo/$pf" ]; then
      local count
      count=$(grep -ci -E 'principle|golden rule|convention|guideline|must always|never do|prefer .* over' \
        "$repo/$pf" 2>/dev/null || echo "0")
      principle_refs=$((principle_refs + count))
    fi
  done

  echo "{\"principle_references\": $principle_refs}"
}

analyze_tech_debt() {
  local repo="$1"

  local todo_count fixme_count hack_count
  todo_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' --include='*.kt' --include='*.cs' --include='*.rb' \
    -E "TODO|todo:" "$repo" 2>/dev/null | wc -l | tr -d ' ')
  fixme_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' \
    -E "FIXME|fixme:" "$repo" 2>/dev/null | wc -l | tr -d ' ')
  hack_count=$(grep -rl --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
    --include='*.rs' --include='*.java' \
    -E "HACK|WORKAROUND|XXX" "$repo" 2>/dev/null | wc -l | tr -d ' ')

  local has_tracker=false
  local tracker_has_content=false
  for tf in "tech-debt-tracker.json" "QUALITY_SCORE.md" "quality-score.md" "docs/QUALITY_SCORE.md"; do
    if [ -f "$repo/$tf" ]; then
      has_tracker=true
      local size
      size=$(wc -c < "$repo/$tf" | tr -d ' ')
      [ "$size" -gt 50 ] && tracker_has_content=true
      break
    fi
  done

  echo "{\"todo_files\": $todo_count, \"fixme_files\": $fixme_count, \"hack_files\": $hack_count, \"has_tracker\": $has_tracker, \"tracker_has_content\": $tracker_has_content}"
}

analyze_ai_slop_detection() {
  local repo="$1"
  local has_dead_code_rules=false
  local has_duplicate_rules=false

  for cfg in ".eslintrc" ".eslintrc.js" ".eslintrc.json" "eslint.config.js" "eslint.config.mjs" \
    "biome.json" "biome.jsonc" "ruff.toml" "pyproject.toml" ".golangci.yml" ".golangci.yaml"; do
    if [ -f "$repo/$cfg" ]; then
      grep -qi "no-unused\|dead.code\|unused\|F401\|F811" "$repo/$cfg" 2>/dev/null && has_dead_code_rules=true
      grep -qi "no-duplicate\|duplicate\|similar\|clone" "$repo/$cfg" 2>/dev/null && has_duplicate_rules=true
    fi
  done

  echo "{\"has_dead_code_rules\": $has_dead_code_rules, \"has_duplicate_rules\": $has_duplicate_rules}"
}

# ---------------------------------------------------------------------------
# Monorepo Detection
# ---------------------------------------------------------------------------

detect_monorepo() {
  local repo="$1"
  local is_monorepo=false
  local monorepo_type="none"
  local packages=()

  if [ -f "$repo/pnpm-workspace.yaml" ]; then
    is_monorepo=true; monorepo_type="pnpm"
  elif [ -f "$repo/lerna.json" ]; then
    is_monorepo=true; monorepo_type="lerna"
  elif [ -f "$repo/nx.json" ]; then
    is_monorepo=true; monorepo_type="nx"
  elif [ -f "$repo/turbo.json" ]; then
    is_monorepo=true; monorepo_type="turborepo"
  elif [ -f "$repo/package.json" ] && grep -q '"workspaces"' "$repo/package.json" 2>/dev/null; then
    is_monorepo=true; monorepo_type="npm-workspaces"
  elif [ -f "$repo/Cargo.toml" ] && grep -q '\[workspace\]' "$repo/Cargo.toml" 2>/dev/null; then
    is_monorepo=true; monorepo_type="cargo-workspace"
  elif [ -f "$repo/go.work" ]; then
    is_monorepo=true; monorepo_type="go-workspace"
  fi

  if [ "$is_monorepo" = true ]; then
    for pdir in "packages" "apps" "libs" "services" "modules" "crates" "internal" "cmd"; do
      if [ -d "$repo/$pdir" ]; then
        while IFS= read -r d; do
          [ -n "$d" ] && packages+=("$(basename "$d")")
        done < <(find "$repo/$pdir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
      fi
    done
  fi

  local pkg_json="[]"
  if [ ${#packages[@]} -gt 0 ]; then
    pkg_json=$(printf '"%s",' "${packages[@]}" | sed 's/,$//')
    pkg_json="[$pkg_json]"
  fi

  echo "{\"is_monorepo\": $is_monorepo, \"type\": \"$monorepo_type\", \"packages\": $pkg_json}"
}

# ---------------------------------------------------------------------------
# Master analysis runner
# ---------------------------------------------------------------------------

run_content_analysis() {
  local repo="$1"
  local dim3_logging dim3_metrics dim3_ui dim3_errors
  local dim5_agent dim5_docs dim5_llms dim5_state
  local dim6_principles dim6_debt dim6_slop
  local monorepo

  dim3_logging=$(analyze_structured_logging "$repo")
  dim3_metrics=$(analyze_metrics_tracing "$repo")
  dim3_ui=$(analyze_ui_visibility "$repo")
  dim3_errors=$(analyze_error_context "$repo")
  dim5_agent=$(analyze_agent_file_quality "$repo")
  dim5_docs=$(analyze_docs_structure "$repo")
  dim5_llms=$(analyze_llms_txt "$repo")
  dim5_state=$(analyze_structured_state "$repo")
  dim6_principles=$(analyze_golden_principles "$repo")
  dim6_debt=$(analyze_tech_debt "$repo")
  dim6_slop=$(analyze_ai_slop_detection "$repo")
  monorepo=$(detect_monorepo "$repo")

  cat <<EOF
{
  "dim3_observability": {
    "structured_logging": $dim3_logging,
    "metrics_tracing": $dim3_metrics,
    "ui_visibility": $dim3_ui,
    "error_context": $dim3_errors
  },
  "dim5_context": {
    "agent_file_quality": $dim5_agent,
    "docs_structure": $dim5_docs,
    "llms_txt": $dim5_llms,
    "structured_state": $dim5_state
  },
  "dim6_entropy": {
    "golden_principles": $dim6_principles,
    "tech_debt": $dim6_debt,
    "ai_slop_detection": $dim6_slop
  },
  "monorepo": $monorepo
}
EOF
}
