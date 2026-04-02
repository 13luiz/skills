# Harness Engineering 审计报告: OpenCode v1.3.13

**日期**: 2026-04-02  
**配置**: monorepo | **阶段**: mature  
**生态**: Bun + TypeScript（多工作区）+ SolidJS + Effect + Tauri（桌面）+ Astro/Starlight（文档站点）  
**语言**: 中文 (zh)

## 总评: C (57/100)

## 执行摘要

OpenCode 在 CI（`test.yml` / `typecheck.yml`）、Playwright E2E、结构化日志与多份 `AGENTS.md` 上表现扎实，但机械约束维度薄弱：工作区内无 ESLint 入 CI、无格式化门禁，且缺少 `llms.txt`、正式完成功能清单与长期任务的进度/执行计划工件。安全与运维侧依赖 GitHub 平台能力较多，CODEOWNERS 覆盖范围较窄。

## 审计参数

| 参数 | 值 |
|------|-----|
| Profile | monorepo |
| Stage | mature（45 项全部启用） |
| 跳过项 | 无 |
| 工作区包数量（用于动态阈值） | 19 |
| AGENTS.md 动态阈值 | min(150+5×19, 300) = **245 行** |
| 权重 dim1…dim8 | 0.13, 0.22, 0.13, 0.13, 0.12, 0.12, 0.10, 0.05 |

**已审阅的 32 个 GitHub Actions 工作流**（`.github/workflows/`，按字母序）：`beta.yml`、`close-issues.yml`、`close-stale-prs.yml`、`compliance-close.yml`、`containers.yml`、`daily-issues-recap.yml`、`daily-pr-recap.yml`、`deploy.yml`、`docs-locale-sync.yml`、`docs-update.yml`、`duplicate-issues.yml`、`generate.yml`、`nix-eval.yml`、`nix-hashes.yml`、`notify-discord.yml`、`opencode.yml`、`pr-management.yml`、`pr-standards.yml`、`publish-github-action.yml`、`publish-vscode.yml`、`publish.yml`、`release-github-action.yml`、`review.yml`、`stats.yml`、`storybook.yml`、`sync-zed-extension.yml`、`test.yml`、`triage.yml`、`typecheck.yml`、`vouch-check-issue.yml`、`vouch-check-pr.yml`、`vouch-manage-by-issue.yml`。

## 维度评分

| 维度 | 项数 | 原始分 (0–1 均值×100) | 权重 | 加权贡献 |
|------|------|------------------------|------|----------|
| 1 架构文档与知识 | 5 | 60.0 | 0.13 | 7.80 |
| 2 机械约束 | 7 | 42.9 | 0.22 | 9.43 |
| 3 可观测性与反馈 | 5 | 70.0 | 0.13 | 9.10 |
| 4 测试与验证 | 7 | 71.4 | 0.13 | 9.29 |
| 5 上下文工程 | 5 | 60.0 | 0.12 | 7.20 |
| 6 熵与治理 | 4 | 62.5 | 0.12 | 7.50 |
| 7 长任务支持 | 6 | 33.3 | 0.10 | 3.33 |
| 8 安全护栏 | 6 | 58.3 | 0.05 | 2.92 |
| **合计** | **45** | — | **1.00** | **56.57 → 约 57/100** |

**等级映射**：A=85–100，B=70–84，C=55–69，D=40–54，F=0–39 → **C**。

---

## 详细发现

### 维度 1 — 架构文档与知识管理

| 项 | 判定 | 得分 | 证据（路径） |
|----|------|------|----------------|
| **1.1** Agent 指令文件 | **PASS** | 1.0 | 根目录 `AGENTS.md`（约 129 行，低于动态阈值 245）；另有 `packages/opencode/AGENTS.md`、`packages/app/AGENTS.md`、`packages/desktop/AGENTS.md`、`packages/desktop-electron/AGENTS.md`、`packages/app/e2e/AGENTS.md`、`packages/opencode/test/AGENTS.md`（共 7 份）。 |
| **1.2** 结构化知识库 | **PASS** | 1.0 | 根目录无 `docs/`，但 `README.md`「Documentation」明确链接 `https://opencode.ai/docs`；源码文档树在 `packages/web/src/content/docs/`（含多语言 `index.mdx`）。 |
| **1.3** 架构文档 | **PARTIAL** | 0.5 | 无 `ARCHITECTURE.md`；`CONTRIBUTING.md`「Core pieces」描述包边界（如 `packages/opencode`、`packages/app`、`packages/desktop`），缺独立架构/依赖规则专文。 |
| **1.4** 渐进式披露 | **PARTIAL** | 0.5 | `AGENTS.md` 分节清晰但未链接至子包 `AGENTS.md` 或 `packages/web/src/content/docs/` 深链。 |
| **1.5** 版本化知识工件 | **FAIL** | 0.0 | 未发现 `docs/adr/`、`docs/design-docs/`、`docs/decisions/`、`docs/exec-plans/` 等约定目录。 |

**维度 1 得分**：(1+1+0.5+0.5+0)/5×100 = **60.0**

---

### 维度 2 — 机械约束

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **2.1** CI 存在且阻断 | **PASS** | 1.0 | 32 个工作流；`test.yml`、`typecheck.yml` 均含 `pull_request`（及 `dev` 分支 `push`）。 |
| **2.2** Lint 强制 | **FAIL** | 0.0 | 工作流全文检索无 `eslint`/`lint` 任务；`sdks/vscode/eslint.config.mjs` 不在 workspace；核心包无 CI lint。 |
| **2.3** 格式化强制 | **PARTIAL** | 0.5 | 根 `package.json` 含 `prettier` 字段；`.editorconfig` 存在；**无** CI 中的 `prettier --check` 或等价步骤。 |
| **2.4** 类型安全 | **PARTIAL** | 0.5 | `typecheck.yml` 运行 `bun typecheck`；`packages/opencode/tsconfig.json` 继承 `@tsconfig/bun` 且 `noUncheckedIndexedAccess: false`，未达到「严格模式全覆盖」意义上的 PASS。 |
| **2.5** 依赖方向规则 | **PARTIAL** | 0.5 | 使用 Bun workspace；无 `eslint-plugin-boundaries` / import-linter 等在 CI 中强制依赖方向。 |
| **2.6** 可修复的错误信息 | **FAIL** | 0.0 | 无工作区自定义 lint 规则及带修复指引的消息。 |
| **2.7** 结构约定强制 | **PARTIAL** | 0.5 | `AGENTS.md` 约定命名/控制流等，但非 CI/lint 强制执行。 |

**维度 2 得分**：3/7×100 ≈ **42.9**

---

### 维度 3 — 可观测性

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **3.1** 结构化日志 | **PASS** | 1.0 | `packages/opencode/src/util/log.ts`：`Log.Level`、`Logger`、`build()` 键值对、ISO 时间戳、文件落盘与 `formatError` 因果链。 |
| **3.2** 指标与追踪 | **FAIL** | 0.0 | 未发现应用内 OpenTelemetry/Prometheus 管线；`packages/opencode/src/config/config.ts` 等仅有 AI SDK `experimental_telemetry` 配置描述，不构成平台级 metrics/tracing。 |
| **3.3** Agent 可查询的可观测性 | **PARTIAL** | 0.5 | 日志可写文件（`Global.Path.log`）；无统一「CLI 查指标」接口，属半程序化。 |
| **3.4** UI 对 Agent 可见性 | **PASS** | 1.0 | `packages/app/playwright.config.ts`；`test.yml` 中 `bun --cwd packages/app test:e2e:local` 与 Chromium 安装。 |
| **3.5** 诊断性错误上下文 | **PARTIAL** | 0.5 | `log.ts` 中 `formatError` 与 Effect/业务错误模式并存，非全库统一「建议修复步骤」级别。 |

**维度 3 得分**：3.5/5×100 = **70.0**

---

### 维度 4 — 测试与验证

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **4.1** 测试套件 | **PASS** | 1.0 | 多包测试目录与大量 `*.test.*`（脚本摘要 253 个测试文件级证据）。 |
| **4.2** CI 测试阻断 | **PASS** | 1.0 | `test.yml`：`bun turbo test`；E2E job 带失败 artifact 上传。 |
| **4.3** 覆盖率阈值 | **PARTIAL** | 0.5 | `packages/opencode/package.json` 中 `"lint"` 实为 `bun test --coverage`，**无** `fail-under` 类阈值；CI 未声明覆盖率门禁。 |
| **4.4** 正式完成标准 | **FAIL** | 0.0 | 无 `features.json` / `feature-checklist.json`（definitive 项）。 |
| **4.5** E2E 验证 | **PASS** | 1.0 | 同上 Playwright + `test.yml`。 |
| **4.6** 测试不稳定管理 | **PASS** | 1.0 | `playwright.config.ts`：`retries: process.env.CI ? 2 : 0`，`trace`/`screenshot`/`video` 策略；失败上传 `e2e/test-results` 与 report。 |
| **4.7** 对抗式验证 | **PARTIAL** | 0.5 | `.github/workflows/review.yml`：`/review` 触发 OpenCode + 受限 `OPENCODE_PERMISSION`；非独立只读验证代理 + 结构化裁决模板的全套模式。 |

**维度 4 得分**：5/7×100 ≈ **71.4**

---

### 维度 5 — 上下文工程

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **5.1** 外显知识 | **PASS** | 1.0 | 根 `AGENTS.md`、`CONTRIBUTING.md`、托管文档 + `packages/web/src/content/docs/`。 |
| **5.2** 文档新鲜度机制 | **PARTIAL** | 0.5 | `docs-update.yml` 定时 + Agent 更新文档，但 `if: github.repository == 'sst/opencode'` 与当前 fork 元数据 `anomalyco/opencode` 可能不一致；另存在 `docs-locale-sync.yml`。 |
| **5.3** 机器可读参考 | **FAIL** | 0.0 | 仓库内无 `llms.txt` / `llms-full.txt` / `docs/references/`（definitive 项）。 |
| **5.4** 技术可组合性 | **PARTIAL** | 0.5 | Bun/TS/Solid 主流；Effect 生态较专，但文档与语言服务齐全；整体「Agent 推理成本」中等。 |
| **5.5** 缓存友好上下文 | **PASS** | 1.0 | 根 `AGENTS.md` 低于 245 行阈值；多包子文档拆分。 |

**维度 5 得分**：3/5×100 = **60.0**

---

### 维度 6 — 熵管理

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **6.1** 黄金原则成文化 | **PASS** | 1.0 | `AGENTS.md` Style Guide；`packages/opencode/src/session/prompt/gpt.txt` 工程行为准则。 |
| **6.2** 周期性清理 | **PARTIAL** | 0.5 | `.github/workflows/close-stale-prs.yml` 定时关闭陈旧 PR；非全面「代码质量重构」日程。 |
| **6.3** 技术债跟踪 | **PARTIAL** | 0.5 | 无 `tech-debt-tracker.json` / `QUALITY_SCORE.md`；存在大量 TODO/HACK 散落（脚本层摘要）。 |
| **6.4** AI Slop 检测 | **PARTIAL** | 0.5 | `.opencode/command/rmslop.md` 手动命令；`gpt.txt` 第 49 行起避免「AI slop」布局；**无** 自动化 lint 规则。 |

**维度 6 得分**：2.5/4×100 = **62.5**

---

### 维度 7 — 长任务支持

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **7.1** 任务分解策略 | **FAIL** | 0.0 | 无 `docs/exec-plans/`、`EXECUTION_PLAN.md`（definitive）。 |
| **7.2** 进度跟踪工件 | **FAIL** | 0.0 | 无 `progress.txt`/`progress.json`（definitive）。 |
| **7.3** 交接桥梁 | **PARTIAL** | 0.5 | Git 历史 + `CONTRIBUTING.md` 导航；无统一 feature 状态文件。 |
| **7.4** 环境恢复 | **PARTIAL** | 0.5 | `flake.nix` 提供 `devShell` 与包构建；**无** `init.sh`/`docker-compose` 及脚本内健康检查。 |
| **7.5** 干净状态纪律 | **PARTIAL** | 0.5 | `AGENTS.md` 强调自动化与类型检查；`pre-push` 有 typecheck；未书面要求「每会话必提交干净树」。 |
| **7.6** 持久执行支持 | **PARTIAL** | 0.5 | 缺结构化 checkpoint + 文档化恢复协议；与 7.1/7.2 联动不足。 |

**维度 7 得分**：2/6×100 ≈ **33.3**

---

### 维度 8 — 安全护栏

| 项 | 判定 | 得分 | 证据 |
|----|------|------|------|
| **8.1** 最小权限凭据 | **PARTIAL** | 0.5 | 仓库未文档化「Agent token 范围策略」；产品向密钥通过 GitHub Secrets 注入。 |
| **8.2** 审计日志 | **PARTIAL** | 0.5 | 依赖 GitHub Actions / PR 历史；无独立审计日志架构说明。 |
| **8.3** 回滚能力 | **PARTIAL** | 0.5 | `publish.yml` 等发布流；无显式 `ROLLBACK.md` 或自动化回滚脚本。 |
| **8.4** 人工确认门 | **PARTIAL** | 0.5 | `deploy.yml` 对 `dev`/`production` 分支 `push` 即部署；未见 `environment: production` 审批门；`workflow_dispatch` 存在。 |
| **8.5** 安全关键路径标记 | **PASS** | 1.0 | `.github/CODEOWNERS` 存在（definitive：文件存在）；当前仅覆盖 `packages/app/`、`packages/tauri/`、`packages/desktop*` 部分路径。 |
| **8.6** 工具协议边界 | **FAIL** | 0.0 | 未发现 MCP 服务端配置与「工具输出不可信」的成文策略。 |

**维度 8 得分**：3.5/6×100 ≈ **58.3**

---

## 检测到的反模式

| 反模式 | 说明 | 涉及路径/工作流 |
|--------|------|------------------|
| Lint 脚本名实不符 | `packages/opencode` 的 `lint` 实为覆盖率测试 | `packages/opencode/package.json` |
| 文档自动化仓库条件漂移 | `docs-update.yml` 固定 `sst/opencode` | `.github/workflows/docs-update.yml` |
| 格式化仅本地 | Prettier 配置未进 PR 必过检查 | 根 `package.json`、各 workflow |
| 核心包无 CODEOWNERS | `packages/opencode` 未列入 | `.github/CODEOWNERS` |
| 类型严格度缺口 | `noUncheckedIndexedAccess: false` | `packages/opencode/tsconfig.json` |

---

## 改进路线图

### 快速胜利（1 天内可实施）

- 在 `test.yml` 或新 job 增加 `prettier --check`（根目录）及（可选）将 `sdks/vscode` ESLint 或 Biome 接入 turbo 并在 CI 运行。
- 在仓库根添加 `llms.txt`（链接 Starlight 文档与关键包 README）。
- 将 `packages/opencode` 核心路径加入 `.github/CODEOWNERS`。
- 重命名 `packages/opencode` 的 `lint` 脚本为 `test:coverage` 或拆分真实 lint。

### 战略投资（1–4 周）

- 引入 `docs/adr/` 或 `docs/exec-plans/` 模板，并与 `AGENTS.md` 互链。
- 增加覆盖率阈值（如 `--coverage-reporter=lcov` + `coverageThreshold` 或 Bun 等价）并纳入 CI。
- 评估 Effect 友好 import 边界（dep-cruiser / 自定义脚本）并在 CI 阻断违规依赖。
- 为 `deploy.yml` 配置 GitHub Environments 审批与回滚 Runbook。
- 统一 `docs-update.yml` 的 `github.repository` 条件与实际上游仓库。

---

## 推荐模板

- `harness-engineering-guide/templates/universal/feature-checklist.json`（对应项 4.4）
- `harness-engineering-guide/templates/universal/execution-plan.md`（对应项 7.1）
- `harness-engineering-guide/templates/universal/agents-md-scaffold.md`（强化 1.4 深链）

---

*审计由 Harness Engineering Guide v1.5.4 生成。*
