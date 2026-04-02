# Harness Engineering 审计报告: OpenCode v1.3.13

**日期**: 2026-04-02  
**配置**: monorepo | **阶段**: mature  
**生态**: Bun + TypeScript（多工作区）+ SolidJS + Effect + Tauri（桌面）+ Astro/Starlight（文档站点）  
**语言**: 中文 (zh)

## 总评: C (60/100)

## 执行摘要

OpenCode v1.3.13（核心版本见 `packages/opencode/package.json`）在**测试与 CI 门禁**（`bun turbo test`、`bun typecheck`、Playwright E2E 双平台矩阵）和**代理入口文档**（根目录 `AGENTS.md` 128 行，低于 monorepo 动态阈值 245 行）上基础扎实，并具备自定义结构化日志（`packages/opencode/src/util/log.ts`）与可选 AI SDK OpenTelemetry 实验开关。主要短板集中在**机械约束**：工作区核心包**无** ESLint/Biome/Oxlint 在 CI 中强制执行（唯一 `eslint.config.mjs` 位于非工作区的 `sdks/vscode/`），Prettier 虽有根配置但**全部 32 个** GitHub Actions 工作流中**无任何** `prettier`/`eslint`/`oxlint` 检查步骤，直接触发 rubric **2.2 FAIL** 与反模式 **#12（Lint but don't block）** 的变体（核心代码路径上连“可阻断的 lint job”都不存在）。此外缺少根级 `ARCHITECTURE.md`、根 `AGENTS.md` 未链接子包 `AGENTS.md`、文档自动化任务对上游仓库硬编码（`docs-update.yml` 仅 `sst/opencode`），以及覆盖率阈值与正式 ADR 体系缺失，拉低测试与架构维度得分。

## 审计参数

| 参数 | 值 |
|------|-----|
| 配置 | monorepo — 权重: dim1 0.13, dim2 0.22, dim3 0.13, dim4 0.13, dim5 0.12, dim6 0.12, dim7 0.10, dim8 0.05 |
| 阶段 | mature — **45/45** 项全部参与计分 |
| 语言 | 中文 (zh) |
| 跳过项 | 无（monorepo 配置未声明 `skip_items`） |
| 工作区包数量 | **19**（`package.json` 中 `workspaces.packages` 解析：`packages/*`、`packages/console/*`、`packages/sdk/js`、`packages/slack` 下的 `package.json` 成员；**不含** `sdks/vscode/`、`github/`） |
| AGENTS.md 动态阈值 | `min(150 + 5 × 19, 300)` = **245 行**（见根 `package.json` `workspaces`） |
| 已审阅 CI 工作流（32 个，均已打开核对） | `beta.yml`, `close-issues.yml`, `close-stale-prs.yml`, `compliance-close.yml`, `containers.yml`, `daily-issues-recap.yml`, `daily-pr-recap.yml`, `deploy.yml`, `docs-locale-sync.yml`, `docs-update.yml`, `duplicate-issues.yml`, `generate.yml`, `nix-eval.yml`, `nix-hashes.yml`, `notify-discord.yml`, `opencode.yml`, `pr-management.yml`, `pr-standards.yml`, `publish-github-action.yml`, `publish-vscode.yml`, `publish.yml`, `release-github-action.yml`, `review.yml`, `stats.yml`, `storybook.yml`, `sync-zed-extension.yml`, `test.yml`, `triage.yml`, `typecheck.yml`, `vouch-check-issue.yml`, `vouch-check-pr.yml`, `vouch-manage-by-issue.yml` — 全库 `rg -i 'prettier|eslint|oxlint' .github/workflows` **0 命中** |

## 维度评分

| # | 维度 | 项目 | 通过 | 得分 | 权重 | 加权 | 控制环要素 |
|---|------|------|------|------|------|------|------------|
| 1 | 架构文档与知识管理 | 5 | 3.0/5 | 60.0% | 0.13 | 7.80 | 目标状态 |
| 2 | 机械约束 | 7 | 4.0/7 | 57.1% | 0.22 | 12.57 | 执行器 |
| 3 | 反馈回路与可观测性 | 5 | 4.0/5 | 80.0% | 0.13 | 10.40 | 传感器 |
| 4 | 测试与验证 | 7 | 4.0/7 | 57.1% | 0.13 | 7.43 | 传感器+执行器 |
| 5 | 上下文工程 | 5 | 3.0/5 | 60.0% | 0.12 | 7.20 | 目标状态 |
| 6 | 熵管理与垃圾回收 | 4 | 2.5/4 | 62.5% | 0.12 | 7.50 | 反馈回路 |
| 7 | 长期任务支持 | 6 | 2.5/6 | 41.7% | 0.10 | 4.17 | 反馈回路 |
| 8 | 安全护栏 | 6 | 3.0/6 | 50.0% | 0.05 | 2.50 | 执行器（防护） |
| **总计** | | **45** | **26.0/45** | **57.8%**（原始项均值） | **1.00** | **59.57** | |

**加权总分约 59.6/100，四舍五入总评 60/100，等级 C（55-69 区间）。**

> 说明：单项 PASS=1.0、PARTIAL=0.5、FAIL=0；维度得分 =（维度内得分和 ÷ 项数）×100；加权列 = 维度得分 × 对应权重。

## 详细发现

### 1. 架构文档与知识管理

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 1.1 | 代理指令文件 | **PASS** | 根目录 `AGENTS.md` 共 **128 行**（PowerShell `(Get-Content AGENTS.md).Count`），低于 monorepo 阈值 **245**。含风格、测试、类型检查指引。另有多份子包 `AGENTS.md`：`packages/opencode/AGENTS.md`、`packages/app/AGENTS.md`、`packages/desktop/AGENTS.md`、`packages/desktop-electron/AGENTS.md`、`packages/opencode/test/AGENTS.md`、`packages/app/e2e/AGENTS.md`。未发现根级 `CLAUDE.md`、`.cursorrules`、`.cursor/rules/`、`CODEX.md`。 |
| 1.2 | 结构化知识库 | **PASS**（按 v1.3.3 关键规则） | 仓库**无**根级 `docs/`，用户文档源码在 `packages/web/src/content/docs/`（多语言 MDX）。根 `README.md` 明确链接文档入口：「[**head over to our docs**](https://opencode.ai/docs)」及 [agents](https://opencode.ai/docs/agents)，满足「README 直接链接文档入口 + 清晰导航」的 PASS 条件。 |
| 1.3 | 架构文档 | **FAIL** | 未发现 `ARCHITECTURE.md` 或同等单文件架构说明。`CONTRIBUTING.md` 描述各包职责（如 `packages/opencode`、`packages/app`）但缺少系统域边界、依赖方向与分层规则的**集中**架构文档。 |
| 1.4 | 渐进式披露 | **PARTIAL**（按关键规则） | 子包存在多份 `AGENTS.md`，但根 `AGENTS.md` **未**显式链接至上述子包文件，不满足「根代理文件必须显式链接子包代理文件」的 PASS 条件。 |
| 1.5 | 版本化知识制品 | **PARTIAL** | 约定与流程在 `CONTRIBUTING.md`、`.github/` 工作流与 `packages/web/src/content/docs/` 中；**无** `docs/adr/` 或类似 ADR 目录（全库 glob `**/adr/**/*.md` 为 0）。 |

### 2. 机械约束

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 2.1 | CI 管线存在并阻断 | **PASS** | `.github/workflows/test.yml`：`pull_request` 触发，`bun turbo test`（unit 矩阵）+ `packages/app` Playwright E2E。`.github/workflows/typecheck.yml`：`pull_request` 至 `dev` 分支时 `bun typecheck`。另有多条质量相关工作流（如 `nix-eval.yml`、`storybook.yml`、`pr-standards.yml`）。合并是否强制 required check 属 GitHub 分支保护配置（仓库外），但 CI 设计为 PR 门禁型。 |
| 2.2 | Linter 强制执行 | **FAIL**（按关键规则） | 唯一 ESLint 配置在 `sdks/vscode/eslint.config.mjs`（`sdks/vscode/package.json` 的 `lint` 脚本），**不在** Bun `workspaces` 内。工作区核心包无提交级 ESLint/Biome/Oxlint 配置；**所有**工作流文件中无 eslint/biome/oxlint 执行步骤。→ 核心代码路径无 linter 覆盖，**FAIL**。 |
| 2.3 | 格式化强制执行 | **PARTIAL** | 根 `package.json` 配置 `prettier` 与 `script/format.ts`（`bun run prettier --write`），但 CI 中**无** `prettier --check` 或等价步骤；32 个工作流均未引用 prettier。 |
| 2.4 | 类型安全 | **PASS** | `typecheck.yml` 在 CI 执行 `bun typecheck`（根脚本为 `bun turbo typecheck`）。多包 `tsconfig.json` 显式 `"strict": true`（如 `packages/app/tsconfig.json`、`packages/ui/tsconfig.json`）；`packages/web/tsconfig.json` 继承 `astro/tsconfigs/strict`。`packages/opencode` 使用 `tsgo --noEmit`（`packages/opencode/package.json`）与 Effect 语言服务插件。 |
| 2.5 | 依赖方向规则 | **PARTIAL** | `CONTRIBUTING.md` 说明包职责，但无 `dependency-cruiser`、`eslint-plugin-boundaries`、import-linter 等**机械** enforcement；未发现 CI 中的依赖方向检查。 |
| 2.6 | 可修复性错误信息 | **PARTIAL** | PR 标准与部分脚本可给出可操作提示；大量错误依赖 Effect/TSC 默认信息，非全面「带修复指引」的自定义规则。 |
| 2.7 | 结构约定强制 | **PARTIAL**（按关键规则） | `AGENTS.md` 中有命名等约定；`.husky/pre-push` 强制 Bun 版本校验与 `bun typecheck`。`.github/workflows/pr-standards.yml` 对 PR 标题等做约定检查。但**缺少**「至少两种经 lint/CI 机械执行」的强证据（类型检查属 2.4；PR 标题检查算一种，第二种薄弱）。 |

### 3. 反馈回路与可观测性

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 3.1 | 结构化日志 | **PASS** | `packages/opencode/src/util/log.ts`：`Log.Level`、带 `extra` 对象的 `info`/`error`/`warn`/`debug`、`tag`/`clone`、文件日志初始化。 |
| 3.2 | 指标与追踪 | **PARTIAL** | `packages/opencode/src/config/config.ts` 等与 AI SDK 集成的 `experimental.openTelemetry` 可选配置；非全栈 OpenTelemetry/Prometheus 部署。 |
| 3.3 | 代理可查询可观测性 | **PARTIAL** | 日志可写入 `Global.Path.log` 下文件（见 `log.ts`）；无统一查询 API 或文档化「代理如何用 CLI 拉取指标」。 |
| 3.4 | UI 对代理可见 | **PASS** | `test.yml` E2E job：`bun --cwd packages/app test:e2e:local`，Playwright Chromium；`packages/app/e2e/AGENTS.md` 描述本地与 CI 用法。 |
| 3.5 | 诊断错误上下文 | **PASS** | Effect 生态与代码库中广泛使用 `Cause`/`log.error(..., { cause })` 等模式（如 `packages/opencode/src/worktree/index.ts`），较默认 `console.error` 更可诊断。 |

### 4. 测试与验证

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 4.1 | 测试套件 | **PASS** | `packages/opencode/package.json`：`bun test`；`packages/app`：单元与 E2E；Turbo 在 `turbo.json` 中配置 `opencode#test`、`@opencode-ai/app#test`。 |
| 4.2 | CI 测试并阻断 | **PASS** | `test.yml` 在 PR 上运行 `bun turbo test` 与 E2E；失败时上传 Playwright 工件。 |
| 4.3 | 覆盖率阈值 | **FAIL** | `packages/opencode/package.json` 中 `lint` 脚本为 `bun test --coverage`，但属误导性命名且 **CI 未**配置覆盖率阈值或 Codecov 类门控；工作流中无 coverage 报告步骤。 |
| 4.4 | 正式化完成标准 | **FAIL** | 未发现机器可读 feature checklist 作为合并门禁（对比 Harness `feature-checklist.json` 类制品）。 |
| 4.5 | 端到端验证 | **PASS** | 同上 Playwright CI；多平台矩阵（Linux/Windows）。 |
| 4.6 | 不稳定测试管理 | **PARTIAL** | `fail-fast: false`、失败工件上传；无专用 quarantine/重试策略文档或 job。 |
| 4.7 | 对抗性验证 | **PARTIAL** | `.github/workflows/review.yml`：`/review` 触发 OpenCode + Claude 审阅并写 PR 评论；`opencode.yml` 中 `OPENCODE_PERMISSION` 限制 bash。缺乏 checklist 要求的只读隔离 + 结构化「命令执行证据」+ 系统化对抗探针集合。 |

### 5. 上下文工程

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 5.1 | 知识外化 | **PASS** | `CONTRIBUTING.md`、`packages/web/src/content/docs/` 大量 MDX、根 `README` 多语言链接。 |
| 5.2 | 文档新鲜度机制 | **PARTIAL** | `docs-update.yml` 计划用 OpenCode 更新文档，但 `if: github.repository == 'sst/opencode'`，在 **`anomalyco/opencode` 上不执行**。`docs-locale-sync.yml` 中 `if: false`，任务被禁用。 |
| 5.3 | 机器可读参考 | **FAIL** | 未发现根或文档站 `llms.txt`（全库 glob 为 0）。 |
| 5.4 | 技术可组合性 | **PARTIAL**（按关键规则） | 核心逻辑深度使用 **Effect**（`package.json` catalog、`@effect/*`）；按 v1.3.3 说明对 AI 文档/训练数据友好度一般，判 **PARTIAL**。 |
| 5.5 | 缓存友好上下文设计 | **PASS** | 根 `AGENTS.md` 128 行低于阈值；文档按 Starlight 多文件组织（`packages/web/astro.config.mjs` + `src/content/docs`）。 |

### 6. 熵管理与垃圾回收

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 6.1 | 编码化黄金原则 | **PASS** | 根 `AGENTS.md`「Style Guide」与 `CONTRIBUTING.md` 流程（如设计评审要求）。 |
| 6.2 | 周期性清理 | **PARTIAL** | `generate.yml` 在 `dev` 上跑 `./script/generate.ts` 并提交；无通用「清理/还债」排程。 |
| 6.3 | 技术债追踪 | **PARTIAL** | Issue 标签与合规工作流（`compliance-close.yml`）；`.github/VOUCHED.td` 等。无统一 `tech-debt-tracker.json` 类制品。 |
| 6.4 | AI 水文检测 | **PARTIAL**（按关键规则） | `.opencode/command/rmslop.md` 为**手动**命令说明；`packages/opencode/src/session/prompt/gpt.txt` 含避免「AI slop」的提示。**无** linter/CI 自动规则 → 非 PASS。 |

### 7. 长期任务支持

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 7.1 | 任务分解策略 | **FAIL** | 未发现执行计划模板或文档化「大型变更必须拆阶段」的强制约定。 |
| 7.2 | 进度追踪制品 | **PARTIAL** | 主要依赖 git 历史与 issue；无 `progress.json` 类跨会话标准制品。 |
| 7.3 | 交接桥梁 | **PARTIAL** | 多份 `AGENTS.md` 提供局部上下文；根入口未汇总链接，削弱交接效率。 |
| 7.4 | 环境恢复 | **PARTIAL** | `flake.nix` + `nix-eval.yml` 评估 flake；`CONTRIBUTING.md` 有 `bun install`/`bun dev`。无统一 `init.sh` 健康检查入口（Harness 模板见 `templates/init/init.sh`）。 |
| 7.5 | 干净状态纪律 | **PARTIAL** | Pre-push typecheck；未文档化「每会话必须可合并」的强制条款。 |
| 7.6 | 持久执行支持 | **PARTIAL** | 无 checklist 级「checkpoint + 恢复协议」三件套；与 7.2/7.4 同弱。 |

### 8. 安全护栏

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 8.1 | 最小权限凭证 | **PARTIAL** | `opencode.yml`：`OPENCODE_PERMISSION: '{"bash": "deny"}'`；`review.yml` 限制 bash/gh。`deploy.yml` 使用多个 scoped secrets。 |
| 8.2 | 审计日志 | **PARTIAL**（按关键规则） | 依赖 GitHub PR/Issue/Actions 历史；**无**独立应用级审计日志管道 → 非 PASS。 |
| 8.3 | 回滚能力 | **PARTIAL**（按关键规则） | `publish.yml`/`script/version.ts` 与 tag 发布流程支持按版本/tag 回退部署；无单独回滚 runbook → 非 FAIL。 |
| 8.4 | 人工确认门控 | **PARTIAL** | `deploy.yml` 含 `workflow_dispatch`；破坏性操作部分依赖流程与权限，非全面双人/审批门控。 |
| 8.5 | 安全关键路径标记 | **PARTIAL** | `.github/CODEOWNERS` 仅覆盖 `packages/app/`、`packages/desktop/` 等路径；非全仓关键路径。 |
| 8.6 | 工具协议信任边界 | **PARTIAL** | 工作流中显式权限对象；MCP 用户侧配置多样，仓库内无统一「工具输出不可信」的强制审计模板。 |

## 检测到的反模式

| 反模式编号 | 名称 | 状态 | 证据 |
|------------|------|------|------|
| #12 | Lint but don't block | **已检测** | 核心工作区无 CI linter；`sdks/vscode` 的 ESLint 不覆盖 monorepo 主体（`.github/workflows` 中零 lint job）。 |
| #15 | TODO-driven debt management | **部分相关** | 技术债主要靠 issue/标签与零散注释，无集中债务追踪制品。 |
| #18 | No crash recovery | **部分相关** | 缺少标准化 checkpoint + 恢复协议（维度 7 低分）。 |
| #20 | Stateless multi-session | **部分相关** | 无结构化跨会话进度文件；根 `AGENTS.md` 未链接子包指令加剧新会话冷启动成本。 |
| #2 | Agent self-evaluation | **风险** | AI 代码审阅工作流（`review.yml`）缺乏独立、带执行证据的对抗验证闭环。 |
| — | 误导性脚本命名 | **已检测** | `packages/opencode/package.json` 中 `"lint"` 实际执行 `bun test --coverage`，易使贡献者误以为已运行静态 lint。 |

## 改进路线图

### 快速胜利（1 天内实施）

1. **在工作区根引入 Biome 或 ESLint** 并新增 CI job：`bunx biome check` 或 `eslint`，对 `packages/*` 源码失败即退出非零（修复 **2.2 FAIL**、反模式 **#12**）。
2. **增加 `prettier --check`** 至 `typecheck.yml` 或独立 `format.yml`，与根 `package.json` 的 `prettier` 配置对齐（提升 **2.3**）。
3. **更新根 `AGENTS.md`**：增加「子包指令」小节，链接至各 `packages/*/AGENTS.md`（修复 **1.4**）。
4. **修正 `packages/opencode` 的 `lint` 脚本命名**或改为真实静态分析命令，避免与 **4.3** 混淆。
5. **将 `docs-update.yml` 的仓库条件**改为 `anomalyco/opencode`（或表达式兼容 fork），或改为可配置 `vars`，否则文档自动更新永不触发。

### 战略投资（1-4 周）

1. **新增 `ARCHITECTURE.md`（根或 `docs/`）**：描述包图、依赖方向、Effect/CLI/TUI/Web 边界（修复 **1.3**）。
2. **依赖方向机械检查**：引入 `templates/linting/depguard.yml` 或 `import-linter.cfg` 类工具并接入 CI（提升 **2.5**）。
3. **覆盖率门控**：在 `turbo`/`test` CI 中收集覆盖率并设最低阈值（修复 **4.3**）。
4. **引入 `llms.txt` 或文档站 sitemap** 供代理抓取（修复 **5.3**）。
5. **ADR 目录**：`docs/adr/0001-...md` + 索引（提升 **1.5**）。
6. **对抗性验证**：为关键路径增加属性测试或只读 verifier 工作流，输出「命令 + 原始输出 + 结论」结构（提升 **4.7**）。
7. **AI 水文规则入 CI**：将 rmslop 检查点转化为 Biome/自定义脚本在 PR 上失败（提升 **6.4** 至 PASS）。

## 推荐模板

- `harness-engineering-guide/templates/universal/execution-plan.md` — 补齐 **7.1** 任务分解与跨会话记录  
- `harness-engineering-guide/templates/universal/tech-debt-tracker.json` — 显式化技术债（缓解 **#15**）  
- `harness-engineering-guide/templates/ci/github-actions/doc-freshness.yml` — 文档一致性/新鲜度 CI（提升 **5.2**）  
- `harness-engineering-guide/templates/linting/eslint-boundary-rule.js` / `depguard.yml` — 依赖与结构约定（提升 **2.5、2.7**）  
- `harness-engineering-guide/templates/init/init.sh` — 环境恢复与健康检查基线（提升 **7.4**）  
- `harness-engineering-guide/templates/universal/agents-md-scaffold.md` — 渐进式披露 TOC 结构（巩固 **1.4、5.5**）

*审计由 Harness Engineering Guide v1.3.3 生成。*
