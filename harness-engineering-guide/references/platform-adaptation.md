# Platform Adaptation Guide

How agent instruction files and harness configurations differ across AI coding platforms. Read when implementing AGENTS.md (Mode 2) or auditing item 1.1 on a multi-platform team.

---

## Agent Instruction File Mapping

| Platform | Primary File | Alternatives / Notes |
|----------|-------------|---------------------|
| **Claude Code** | `CLAUDE.md` | Convention: single file at repo root. Subdirectory `CLAUDE.md` files supported for local overrides. |
| **Cursor** | `.cursor/rules/*.md` | Multiple rule files with glob-based scope (e.g., `*.ts` rules vs `*.py` rules). Legacy: `.cursorrules` single file still supported. |
| **Codex (OpenAI)** | `AGENTS.md` | Open standard (Agentic AI Foundation). Also reads `CODEX.md`. Subdirectory AGENTS.md files for per-module instructions. OpenAI uses 88+ AGENTS.md files internally. |
| **Windsurf** | `.windsurfrules` | Single file, similar format to `.cursorrules`. |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Lives in `.github/` directory. GitHub ecosystem integration. |
| **OpenClaw** | `AGENTS.md` | Follows the AGENTS.md open standard. |

## Cross-Platform Strategy

For teams using multiple agent platforms simultaneously:

1. **Use AGENTS.md as the canonical source** — it is the broadest-supported standard
2. **Generate platform-specific files from the canonical source** — a simple CI step or pre-commit hook can copy/transform AGENTS.md content into `.cursorrules`, `CLAUDE.md`, etc.
3. **Keep platform-specific files thin** — only platform-unique instructions (e.g., Cursor-specific tool configuration) belong in the platform file; shared content stays in AGENTS.md

## Verification System Differences

For adversarial verification implementation per platform, see `references/adversarial-verification.md` § Platform Implementation Guide, which covers permission isolation and verifier spawning for Claude Code, Cursor, and Codex.

## Audit Item 1.1 Adaptation

When scoring item 1.1 (Agent Instruction File Exists), accept any of the platform-specific filenames listed above. The scoring criteria (line count thresholds, progressive disclosure, content quality) apply equally regardless of filename convention.

If multiple platform files exist, score the **primary** one (the one the team's main agent platform reads) and note the others as context.
