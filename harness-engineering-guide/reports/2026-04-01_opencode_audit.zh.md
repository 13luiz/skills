# Harness Engineering 审计报告: OpenCode v1.3.13

**日期**: 2026-04-01
**配置**: monorepo | **阶段**: mature
**生态**: TypeScript/Bun + Turborepo（多包工作区）
**语言**: 中文 (zh)

## 总评: C+ (68.4/100)

## 执行摘要

OpenCode v1.3.13 是一个高度 AI 感知的 Bun + Turbo 单仓项目（19 个工作区包），拥有业界罕见的 32 个 CI 工作流、AI 代码审查（review.yml）、AI 水文清除命令（rmslop）和全面的 PR 合规自动化。其架构文档体系强（多层 AGENTS.md + Mintlify/Starlight 文档），熵管理出色（自动清理过期 PR/Issue、AI slop 检测）。主要短板集中在机械约束层（57.1%）：核心包缺少独立 linter，Prettier 未在 CI 中强制执行，无显式依赖方向强制。长期任务支持（41.7%）是最薄弱环节——无持久执行引擎、无正式会话交接协议、无环境恢复脚本。

## 审计参数

| 参数 | 值 |
|------|-----|
| 配置 | monorepo — 权重: dim1 0.13, dim2 0.22, dim3 0.13, dim4 0.13, dim5 0.12, dim6 0.12, dim7 0.10, dim8 0.05 |
| 阶段 | mature — 45/45 项全部激活 |
| 语言 | 中文 (zh) |
| 跳过项 | 无 |
| 包数量 | 19 个工作区包 + sdks/vscode + github/ 子项目 |
| AGENTS.md 阈值 | 245 行 (150 + 5×19 = 245，未触及 300 上限) |

## 维度评分

| # | 维度 | 项目 | 通过 | 得分 | 权重 | 加权 | 控制环要素 |
|---|------|------|------|------|------|------|-----------|
| 1 | 架构文档与知识管理 | 5 | 4.0/5 | 80.0% | 13% | 10.40 | 目标状态 |
| 2 | 机械约束 | 7 | 4.0/7 | 57.1% | 22% | 12.57 | 执行器 |
| 3 | 反馈回路与可观测性 | 5 | 3.5/5 | 70.0% | 13% | 9.10 | 传感器 |
| 4 | 测试与验证 | 7 | 5.5/7 | 78.6% | 13% | 10.21 | 传感器+执行器 |
| 5 | 上下文工程 | 5 | 4.0/5 | 80.0% | 12% | 9.60 | 目标状态 |
| 6 | 熵管理与垃圾回收 | 4 | 3.0/4 | 75.0% | 12% | 9.00 | 反馈回路 |
| 7 | 长期任务支持 | 6 | 2.5/6 | 41.7% | 10% | 4.17 | 反馈回路 |
| 8 | 安全护栏 | 6 | 4.0/6 | 66.7% | 5% | 3.33 | 执行器（防护） |
| **总计** | | **45** | **30.5/45** | | | **68.38** | |

**评级: C+ (68.4/100)**

## 详细发现

### 1. 架构文档与知识管理 (80.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 1.1 | 代理指令文件 | **PASS** (1.0) | 根 `AGENTS.md` 128 行，远低于 19 包单仓阈值（245 行）。另有 5 个子包级 AGENTS.md（`packages/opencode/`、`packages/app/`、`packages/app/e2e/`、`packages/desktop/`、`packages/desktop-electron/`），实现渐进式披露。 |
| 1.2 | 结构化知识库 | **PASS** (1.0) | `packages/docs/`（Mintlify 文档站，`docs.json` 导航结构）+ `packages/web/src/content/docs/`（Starlight/Astro 多语言用户文档）。OpenAPI 规范位于 `packages/sdk/openapi.json`。 |
| 1.3 | 架构文档 | **PARTIAL** (0.5) | `CONTRIBUTING.md` 含核心包映射和开发流程；`specs/project.md` 含 API/会话设计草案。无独立 `ARCHITECTURE.md` 文件描述系统域边界和依赖方向。 |
| 1.4 | 渐进式披露 | **PASS** (1.0) | `packages/docs/docs.json` 定义导航结构（tabs/groups/pages）；根 `AGENTS.md` 作为 TOC 指向各包 AGENTS.md；`.opencode/` 目录含代理配置/命令/术语表。 |
| 1.5 | 版本化知识 | **PARTIAL** (0.5) | `script/changelog.ts` 生成变更日志；`.opencode/command/changelog.md` 定义变更记录命令。无 `docs/adr/` 目录或 ADR 索引。 |

### 2. 机械约束 (57.1%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 2.1 | CI 管线阻断 | **PASS** [exemplary] (1.0) | 32 个 GitHub Actions 工作流。`typecheck.yml` + `test.yml` 在所有 PR 上运行。`pr-standards.yml` 强制规范标题、关联 Issue、模板合规。`compliance-close.yml` 2 小时后自动关闭不合规项。`vouch-check-pr.yml` 验证作者资格。 |
| 2.2 | Linter 强制执行 | **FAIL** (0.0) | 核心工作区包无 linter 配置。ESLint 仅存在于 `sdks/vscode/`（独立子项目，不在工作区列表中，有自己的 `bun.lock`）。Biome/OxLint 均未配置。CI 中无 lint 步骤。 |
| 2.3 | 格式化强制执行 | **FAIL** (0.0) | Prettier 在根 `package.json` 中配置（`"semi": false, "printWidth": 120`），`script/format.ts` 可手动运行。但 **CI 中无 `prettier --check`**——未设置任何格式化检查工作流。 |
| 2.4 | 类型安全 | **PASS** [exemplary] (1.0) | 多包 `tsconfig.json` 设置 `"strict": true`（opencode、app、util、ui、storybook、enterprise、desktop 等）。`typecheck.yml` 在 CI 中执行 `bun typecheck`。`packages/web` 继承 `astro/tsconfigs/strict`。 |
| 2.5 | 依赖方向规则 | **PARTIAL** (0.5) | 工作区 `package.json` 声明的依赖关系隐式阻止非法导入（Bun/npm 工作区机制）。Turbo 任务图定义构建依赖。但无自定义 import 限制规则、无 eslint-plugin-import、无 Nx 风格边界检测。 |
| 2.6 | 修复感知错误消息 | **PARTIAL** (0.5) | `pr-standards.yml` 提供具体 PR 修复指导（标签 `needs:conventional-title`、`needs:compliance` 等）。但核心代码层面无自定义 lint 规则含修复建议。 |
| 2.7 | 结构约定强制 | **PASS** [advanced] (1.0) | `bunfig.toml` 的 `[test] root = "./do-not-run-tests-from-root"` 防止根目录误跑测试。`pr-standards.yml` 强制 Conventional Commit 标题和模板合规。`compliance-close.yml` 自动关闭不合规项。Husky pre-commit hooks（`"prepare": "husky"`）。 |

### 3. 反馈回路与可观测性 (70.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 3.1 | 结构化日志 | **PASS** (1.0) | 自定义 `Log` 命名空间（`packages/opencode/src/util/log.ts`）：Zod 校验的日志级别枚举、标签化 logger（`name` 前缀）、可选文件输出（`Global.Path.log`）、`time()` 助手、`Record<string, unknown>` 结构化 extras。 |
| 3.2 | 指标与追踪 | **PARTIAL** (0.5) | AI SDK 提供可选 OpenTelemetry 遥测集成（`packages/opencode/src/config/config.ts`）。无完整 OTel/Prometheus 基础设施跨仓库部署。 |
| 3.3 | 代理可查询可观测性 | **PARTIAL** (0.5) | 日志写入 `Global.Path.log` 下的文件，代理可通过文件系统读取。无专用查询 API 或 CLI 工具用于日志/指标检索。 |
| 3.4 | 代理 UI 可见性 | **PASS** (1.0) | Playwright 在 `packages/app` 中配置（`playwright.config.ts`、`@playwright/test`）。CI `test.yml` 运行 e2e 测试（`bun --cwd packages/app test:e2e:local`），含截图/视频/trace 采集。 |
| 3.5 | 诊断错误上下文 | **PARTIAL** (0.5) | Effect 风格的结构化错误类型存在于部分代码中。无仓库级统一错误诊断标准文档。 |

### 4. 测试与验证 (78.6%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 4.1 | 测试套件 | **PASS** (1.0) | Bun test 跨多包（`packages/opencode/test/`、`packages/app` 单元测试 + Happy DOM）；Playwright e2e 在 `packages/app/e2e/`。 |
| 4.2 | 测试 CI 阻断 | **PASS** (1.0) | `test.yml` 在所有 `pull_request` 事件上运行 `bun turbo test`（Linux/Windows 矩阵）+ Playwright e2e。 |
| 4.3 | 覆盖率阈值 | **PARTIAL** (0.5) | `packages/opencode` 的 `lint` 脚本运行 `bun test --coverage`（误导性命名）。未配置覆盖率阈值（`bunfig.toml` 中无 `coverageThreshold`）。 |
| 4.4 | 形式化完成标准 | **PARTIAL** (0.5) | PR 模板含检查清单，`pr-standards.yml` 验证结构，`compliance-close.yml` 机械化强制。但非 JSON/YAML 格式的机器可读完成状态。 |
| 4.5 | 端到端验证 | **PASS** (1.0) | Playwright e2e 套件在 CI 运行，含 API 密钥集成测试，30 分钟超时。 |
| 4.6 | 闪烁测试管理 | **PASS** (1.0) | Playwright CI 重试 2 次（`retries: process.env.CI ? 2 : 0`）、首次重试 trace、失败截图/视频。单元测试矩阵 `fail-fast: false`。 |
| 4.7 | 对抗性验证 | **PARTIAL** (0.5) | `review.yml` 支持维护者触发的 OpenCode+Claude AI 代码审查，发布 `gh` 行级评论——独立于 PR 作者。但无权限隔离或结构化证据报告。 |

### 5. 上下文工程 (80.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 5.1 | 知识外化 | **PASS** (1.0) | AGENTS.md（根+包级）、CONTRIBUTING.md、README（含多语言版）、SECURITY.md、`specs/project.md`、`.opencode/`（代理/命令/术语表）。 |
| 5.2 | 文档新鲜度机制 | **PASS** (1.0) | `docs-update.yml`（12 小时 cron，OpenCode 驱动更新）。`generate.yml`（`dev` 推送时自动重新生成并提交制品）。 |
| 5.3 | 机器可读参考 | **FAIL** (0.0) | 无 `llms.txt` 文件。 |
| 5.4 | 技术可组合性 | **PASS** (1.0) | Bun/TypeScript/Turbo 成熟生态。OpenAPI 规范。Mintlify + Starlight 文档。 |
| 5.5 | 缓存友好设计 | **PASS** (1.0) | 分层 AGENTS.md 按包分布上下文。根 AGENTS.md 128 行，远低于 245 行阈值。`.opencode/` 目录隔离代理配置。 |

### 6. 熵管理与垃圾回收 (75.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 6.1 | 编码化黄金原则 | **PASS** (1.0) | `AGENTS.md` 包含详细风格/命名/测试/类型检查规则（单词命名、early return、Drizzle snake_case 等）。`CONTRIBUTING.md` 含过程和语气守则（"No AI-generated walls of text"）。 |
| 6.2 | 定期清理 | **PASS** (1.0) | `close-stale-prs.yml`（每日 cron）、`close-issues.yml`（每日 cron）、`compliance-close.yml`（30 分钟 cron，2h 后关闭）、`stats.yml`（每日提交 STATS.md）、`beta.yml`（每小时同步）。 |
| 6.3 | 技术债务追踪 | **FAIL** (0.0) | 无专用技术债务登记册（无 `TECH_DEBT.md`、无 ADR 债务区域、无结构化追踪器）。仅有零散 TODO 注释。 |
| 6.4 | AI 水文检测 | **PASS** (1.0) | `.opencode/command/rmslop.md`——专用命令用于从 diff 中清除 AI 生成的水文。`CONTRIBUTING.md` 明确反对 AI 生成的长篇大论 PR。 |

### 7. 长期任务支持 (41.7%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 7.1 | 任务分解策略 | **PARTIAL** (0.5) | Turbo 定义任务依赖图。`specs/project.md` 分解 API 特性。但无针对代理开发工作流的文档化分解策略。 |
| 7.2 | 进度追踪制品 | **PARTIAL** (0.5) | GitHub Issue/PR 为主要进度记录。`stats.yml` 每日自动提交 STATS.md。无会话级进度文件（如 progress.txt）。 |
| 7.3 | 交接桥梁 | **PARTIAL** (0.5) | CONTRIBUTING.md 和 AGENTS.md 提供开发方向。`.opencode/` 含代理上下文。但无正式 HANDOFF.md 或跨会话交接模板。 |
| 7.4 | 环境恢复 | **PARTIAL** (0.5) | CONTRIBUTING.md 文档化了 `bun install`、`bun dev` 等命令。`.github/actions/setup-bun` 可复用 CI action。无专用 `init.sh` 或环境健康检查脚本。 |
| 7.5 | 清洁状态纪律 | **PARTIAL** (0.5) | `generate.yml` 提交生成制品。`dev` 分支并发规则限制噪音。隐式预期但未正式文档化。 |
| 7.6 | 持久化执行 | **FAIL** (0.0) | 无 Temporal/Step Function 风格的持久化工作流引擎。无检查点文件或恢复协议。 |

### 8. 安全护栏 (66.7%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 8.1 | 最小权限凭证 | **PASS** (1.0) | 工作流按 job 设置作用域权限（如 `contents: read`、`pull-requests: write`）。Secrets 通过 GitHub Actions 标准机制管理。 |
| 8.2 | 审计日志 | **PASS** (1.0) | GitHub 原生提供完整审计跟踪：PR 历史、工作流运行记录、配置变更（git 历史）。 |
| 8.3 | 回滚能力 | **FAIL** (0.0) | SST 部署无回滚文档。无回滚剧本或自动化脚本。 |
| 8.4 | 人工确认门控 | **PASS** (1.0) | 部署工作流（`deploy.yml`）需 `workflow_dispatch` 手动触发。发布需标签推送（有意操作）。 |
| 8.5 | 安全关键路径标记 | **PARTIAL** (0.5) | `.github/CODEOWNERS` 存在但覆盖有限（仅 `packages/app`、`packages/tauri/`、`packages/desktop*`）。`packages/tauri/` 引用可能已过时。 |
| 8.6 | 工具协议信任边界 | **PARTIAL** (0.5) | `SECURITY.md` 明确将 MCP 服务器行为标记为"超出信任边界"（用户自行配置）。无权限作用域或调用审计。 |

## 检测到的反模式

| 反模式 | 状态 | 证据 |
|--------|------|------|
| 百科全书式 AGENTS.md | **未触发** | 根 AGENTS.md 128 行 < 245 行阈值（19 包单仓）；子包级文件分散详细内容。 |
| "lint" 脚本名误导 | **已检测** | `packages/opencode/package.json` 的 `"lint"` 脚本实际运行 `bun test --coverage`，非 linter。 |
| 格式化器配置但未强制 | **已检测** | Prettier 在 `package.json` 配置 + `script/format.ts` 可用，但 CI 无 `prettier --check` 步骤。 |
| 过时的 CODEOWNERS 引用 | **已检测** | `.github/CODEOWNERS` 引用 `packages/tauri/` 路径，该目录可能不再存在（不在工作区 `package.json` 列表中）。 |

## 改进路线图

### 快速胜利（1 天内实施）
1. **添加 Prettier CI 检查**：在 `typecheck.yml` 或新工作流中添加 `bun run prettier --check .` 步骤（修复 2.3 FAIL）——最具影响力的单项修复。
2. **创建 `llms.txt`**：在仓库根目录添加机器可读文档路由（修复 5.3 FAIL）。
3. **添加技术债务追踪器**：创建 `TECH_DEBT.md` 或 `tech-debt-tracker.json`（修复 6.3 FAIL）。
4. **修复 "lint" 脚本命名**：将 `packages/opencode` 的 `lint` 脚本重命名为 `test:coverage` 以反映实际行为。

### 战略投资（1-4 周）
1. **引入 Biome 或 ESLint**：为核心包配置并在 CI 中强制执行 linter（修复 2.2 FAIL）。
2. **添加依赖方向强制**：使用 eslint-plugin-import 或自定义脚本强制包间导入规则（提升 2.5）。
3. **创建 ARCHITECTURE.md**：独立架构文档描述系统域边界、包依赖方向和关键抽象（提升 1.3）。
4. **建立代理交接协议**：创建 HANDOFF.md 模板和任务分解标准（提升 7.1、7.3）。
5. **添加回滚剧本**：为 SST 部署编写回滚文档和脚本（修复 8.3 FAIL）。
6. **强制覆盖率阈值**：在 CI 中配置 `bun test --coverage` 的最低阈值（提升 4.3）。

## 推荐模板
- `templates/universal/execution-plan.md` — 用于任务分解标准
- `templates/universal/tech-debt-tracker.json` — 用于结构化债务追踪
- `templates/universal/doc-gardening-prompt.md` — 增强现有文档管线
