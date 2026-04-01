# Harness 工程审计报告: OpenClaw

**日期**: 2026-04-01
**项目类型**: Monorepo | **生命周期阶段**: 成熟期 (50k+ LOC)
**技术生态**: Node.js / TypeScript (pnpm workspace)
**语言**: 中文 (zh)

## 总评等级: B (70.6/100)

## 执行摘要

OpenClaw 展现出**强大的机械约束层**——CI、代码检查、格式化、类型安全和依赖边界强制执行均为业界领先水平并良好集成。测试多层且全面。然而，**长期运行任务的反馈循环尚不完善**（无进度跟踪、无持久化执行、无环境恢复脚本），**上下文工程存在缺口**（无 `llms.txt`、无机器可读参考文档）。解决长期运行任务维度并增加结构化的 Agent 上下文工件，将使该项目从 B 级提升至 A 级。

## 审计参数

| 参数 | 值 |
|------|-----|
| 项目类型 | Monorepo — 权重调整 (dim2=22%, dim5=12%, dim6=12%) |
| 生命周期阶段 | 成熟期 — 45 项中 45 项激活 |
| 语言 | 中文 (zh) |
| 跳过项目 | 无（成熟期全部 45 项激活） |
| 关键项目（类型配置） | 2.5 依赖方向、2.7 结构约定、5.5 缓存友好设计、6.2 周期性清理 |

## 维度评分

| # | 维度 | 项目数 | 通过 | 得分 | 权重 | 加权分 | 控制环节 |
|---|------|--------|------|------|------|--------|----------|
| 1 | 架构文档与知识管理 | 5 | 4.5/5 | 90.0% | 13% | 11.70 | 目标状态 |
| 2 | 机械约束 | 7 | 6.5/7 | 92.9% | 22% | 20.43 | 执行器 |
| 3 | 反馈与可观测性 | 5 | 3.0/5 | 60.0% | 13% | 7.80 | 传感器 |
| 4 | 测试与验证 | 7 | 5.0/7 | 71.4% | 13% | 9.29 | 传感器+执行器 |
| 5 | 上下文工程 | 5 | 2.5/5 | 50.0% | 12% | 6.00 | 目标状态 |
| 6 | 熵管理 | 4 | 2.5/4 | 62.5% | 12% | 7.50 | 反馈循环 |
| 7 | 长期运行任务支持 | 6 | 2.0/6 | 33.3% | 10% | 3.33 | 反馈循环 |
| 8 | 安全护栏 | 6 | 5.5/6 | 91.7% | 5% | 4.58 | 执行器(保护) |
| **总计** | | **45** | **31.5/45** | | **100%** | **70.63** | |

## 详细发现

### 1. 架构文档与知识管理 (90.0%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **1.1** Agent 指令文件 | **通过** [高级] | 根目录 `AGENTS.md`（285 行），在 monorepo 上限（300 行）以内。作为全面的导航图：项目结构、架构边界、构建/测试/开发命令、编码风格、安全路径。`CLAUDE.md` 作为指针存在。Copilot 指令位于 `.github/instructions/copilot.instructions.md`。 |
| **1.2** 结构化知识库 | **通过** [高级] | `docs/` 目录采用 Mintlify 驱动的结构：`concepts/`、`install/`、`gateway/`、`plugins/`、`reference/`、`zh-CN/` 镜像。`docs/docs.json` 作为索引。CI 通过 `check-docs` 作业强制执行文档质量。 |
| **1.3** 架构文档 | **通过** | `docs/concepts/architecture.md` 描述 WebSocket 网关架构、组件和客户端流程。`docs/plugins/architecture.md` 涵盖插件系统。内容在文档层级中组织良好。 |
| **1.4** 渐进式披露 | **通过** [高级] | 根 `AGENTS.md` 是简洁的目录，指向深层文档。10 个子 `AGENTS.md` 文件分布在领域特定目录中（`src/plugin-sdk/`、`extensions/`、`src/channels/`、`src/gateway/protocol/` 等），每个 20-150 行。从通用到专用的清晰导航。 |
| **1.5** 版本化知识工件 | **部分** | 设计文档和架构文档存在于仓库内（`docs/`）。未发现正式的 ADR（架构决策记录）目录。部分设计决策记录在代码注释和 AGENTS.md 中，但缺乏专用的决策日志格式。 |

### 2. 机械约束 (92.9%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **2.1** CI 流水线阻断 | **通过** [卓越] | `.github/workflows/ci.yml`（约1000行），在所有 PR 上运行。动态矩阵通过 `preflight` 作业 + `ci-write-manifest-outputs.mjs` 实现。必需检查名称由 `planner.mjs` 程序化管理。合并脚本通过 `gh pr checks --required` 强制执行。并发组取消过时运行。 |
| **2.2** 代码检查强制执行 | **通过** [卓越] | oxlint 类型感知模式，`.oxlintrc.json` 已提交（插件: unicorn, typescript, oxc；类别: correctness, perf, suspicious = error）。在 `pnpm check`（CI）和 pre-commit 钩子中运行。`check-additional` 作业运行领域特定的检查脚本。`no-explicit-any: error`。 |
| **2.3** 格式化强制执行 | **通过** [高级] | oxfmt 在 CI（`pnpm format` 检查）和 pre-commit 中运行。SwiftFormat + SwiftLint 用于 Swift 代码。markdownlint-cli2 用于文档。多语言格式化覆盖。 |
| **2.4** 类型安全 | **通过** [卓越] | `tsconfig.json` 配置 `"strict": true`，target ES2023，NodeNext 模块解析。`pnpm tsgo`（TypeScript native preview）包含在 `pnpm check` 中。CI 运行类型检查。`noEmitOnError: true`。 |
| **2.5** 依赖方向规则 | **通过** [卓越] | 自定义边界强制执行脚本：`check-plugin-extension-import-boundary.mjs`、`task-registry-import-boundary.test.ts`。CI `check-additional` 作业强制执行：`lint:webhook:no-low-level-body-read`、`lint:auth:no-pairing-store-group`、`lint:auth:pairing-account-scope`、`lint:ui:no-raw-window-open`。违规被聚合并导致作业失败。 |
| **2.6** 修复提示错误消息 | **部分** | AGENTS.md 定义了门控术语和预期命令。自定义检查脚本具有描述性名称。但 oxlint 和边界检查的错误消息未系统性地包含面向 Agent 的修复指令。 |
| **2.7** 结构约定强制执行 | **通过** [高级] | `check:no-conflict-markers`、`check:host-env-policy:swift`、jscpd 重复代码检测（`--min-lines 12 --min-tokens 80`）、knip 死代码检测（`deadcode:knip`、`deadcode:ci`）、扩展命名约定通过检查脚本强制执行。4+ 项约定被机械检查。 |

### 3. 反馈循环与可观测性 (60.0%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **3.1** 结构化日志 | **通过** [高级] | `tslog` 库，按子系统创建子日志器（canvas、discovery、tailscale、channels、health、cron、reload、hooks、plugins、ws、secrets）。`PinoLikeLogger` 类型确保一致的 API。文件和控制台传输。 |
| **3.2** 指标与追踪 | **通过** [高级] | `extensions/diagnostics-otel/` 实现完整 OpenTelemetry 栈：`@opentelemetry/sdk-node`，trace/metric/log 导出器（OTLP proto），`ParentBasedSampler`，`TraceIdRatioBasedSampler`。通过 `diagnostics.otel.*` 配置表面。 |
| **3.3** Agent 可查询的可观测性 | **部分** | 日志基于文件（Agent 可读取）。OTel 导出到外部收集器。没有专用 CLI 命令供 Agent 直接查询日志/指标/追踪。Agent 必须访问日志文件或外部仪表板。 |
| **3.4** Agent 的 UI 可见性 | **部分** | Vitest 浏览器测试已配置（`@vitest/browser-playwright`，Chromium，headless）。Agent 可运行这些测试。但没有专用的 Agent 截图/检查工作流用于编码会话中的临时 UI 验证。 |
| **3.5** 诊断性错误上下文 | **部分** | 配置审计记录包含丰富上下文（timestamp、source、event、result、configPath、pid、ppid、cwd、argv）。子日志器提供子系统上下文。但错误未系统性地包含建议修复或诊断指南。 |

### 4. 测试与验证 (71.4%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **4.1** 测试套件 | **通过** [卓越] | 8+ Vitest 配置：default、unit、e2e、contracts、channels、extensions、gateway、live。UI 浏览器测试通过 Vitest + Playwright。集成测试（19+ 个文件）。Swift 测试（XCTest）。Android JUnit 测试。Python pytest 用于 skills。 |
| **4.2** CI 中的测试阻断 | **通过** [卓越] | 测试在多个 CI 作业中运行（`checks`、`checks-fast`、`check-additional`、`skills-python`、`checks-windows`、`macos-swift`、`android`）。必需检查名称通过 `planner.mjs` 管理。合并通过 `gh pr checks --required` 门控。 |
| **4.3** 覆盖率阈值 | **通过** [高级] | `vitest.config.ts`：lines 70%、functions 70%、statements 70%、branches 55%。V8 provider + lcov reporter。`pnpm test:coverage` 命令。注意：AGENTS.md 声明 branches 70%，但配置为 55%。 |
| **4.4** 形式化完成标准 | **部分** | `planner.mjs` 中的 `requiredCheckNames` 是机器可读的 CI 门控列表。PR 模板定义结构化范围。但没有功能级别的验收标准文件（DONE.json/YAML）。 |
| **4.5** 端到端验证 | **通过** [高级] | `vitest.e2e.config.ts` + `*.e2e.test.ts` 文件。`scripts/e2e/` 下的 Shell/Docker E2E 脚本。UI 浏览器测试使用 Playwright。沙箱 Dockerfile 用于隔离 E2E。CI 在多平台运行 E2E。 |
| **4.6** 测试不稳定管理 | **部分** | Swift 构建/测试重试（3 次尝试，含退避）。Windows CI worker=1 调优。`OPENCLAW_TEST_ISOLATE=1` 用于 channels。网关测试辅助工具记录避免不稳定模式。但没有正式的隔离系统、不稳定测试仪表板或 JS 测试重试框架。 |
| **4.7** 对抗性验证 | **未通过** | `security-fast` 作业运行 detect-private-key、zizmor、pnpm-audit-prod。这些是安全扫描，不是对抗性验证（没有带权限隔离的独立验证者，没有结构化证据报告，没有针对边界值/并发/幂等性的对抗性探测）。 |

### 5. 上下文工程 (50.0%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **5.1** 外部化知识 | **通过** | 关键决策记录在仓库内：AGENTS.md（架构边界、编码风格）、docs/（架构、网关、插件、安全）、PR 模板（结构化范围）、copilot 指令。 |
| **5.2** 文档新鲜度机制 | **部分** | CI `check-docs` 作业验证格式、链接、i18n 术语表。`stale.yml` 管理过期 issues/PRs。但文档页面没有过期日期、没有自动文档维护 Agent、没有新鲜度 TTL 机制。 |
| **5.3** 机器可读参考 | **未通过** | 没有 `llms.txt` 文件。没有策划的依赖参考快照。Copilot 指令存在但精简（20 行）。Agent 必须在没有本地指导的情况下获取外部文档。 |
| **5.4** 技术可组合性 | **通过** | Node.js、TypeScript、Express、Hono、Vitest、Playwright、Zod、tslog——均为文档完善、广为人知的技术。部分自定义抽象（插件 SDK、网关协议）但在仓库内有良好文档。 |
| **5.5** 缓存友好的上下文设计 | **部分** | 根 AGENTS.md 285 行（在 300 行 monorepo 上限以内）。子 AGENTS.md 文件支持针对性加载。但没有结构化状态文件（JSON/YAML）用于 Agent 跟踪，没有指定的 Agent 输出工件目录。 |

### 6. 熵管理与垃圾回收 (62.5%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **6.1** 编码化核心原则 | **通过** | AGENTS.md 编码了：架构边界（插件 SDK 仅通过 barrel 导出）、编码风格（oxlint 规则，禁止 explicit any）、门控纪律（local/landing/CI）、安全规则（CODEOWNERS 路径受限）。从 Agent 指令入口点引用。 |
| **6.2** 周期性清理流程 | **通过** [高级] | jscpd 用于重复代码检测（`dup:check`），knip 用于死代码检测（`deadcode:knip`、`deadcode:ci`）。dependabot 用于依赖更新（npm、GitHub Actions、Swift、Gradle、Docker）。`stale.yml` 机器人用于 issue/PR 维护。系统化多工具清理。 |
| **6.3** 技术债务跟踪 | **未通过** | 没有质量评分、技术债务跟踪器或类似的维护工件。没有 TODO 跟踪的证据（除了个别代码注释外）。没有技术债务仪表板或定期质量评估。 |
| **6.4** AI 低质量代码检测 | **部分** | jscpd 捕获重复工具函数。knip 捕获死代码。这些解决了常见的 AI 生成模式，但是通用工具，未专门针对 AI 低质量模式（过度抽象、幻觉导入、冗余包装器）。 |

### 7. 长期运行任务支持 (33.3%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **7.1** 任务分解策略 | **部分** | AGENTS.md 定义三级门控（local dev、landing、CI）。PR 模板结构化范围。但没有执行计划模板、没有冲刺合约格式、没有将复杂任务分解为 Agent 可处理大小的文档化策略。 |
| **7.2** 进度跟踪工件 | **未通过** | 未发现 `progress.txt`、执行计划日志或结构化进度文件。Git 提交消息是会话间唯一的进度记录。 |
| **7.3** 交接桥梁 | **部分** | PR 模板包含摘要、范围边界、证据部分，用于人类交接。AGENTS.md 提供导向。但没有结构化进度日志、没有功能状态跟踪、没有会话到会话的交接协议。 |
| **7.4** 环境恢复 | **部分** | 没有根目录 `init.sh` 或设置脚本。Docker 设置脚本存在于 `scripts/docker/` 下。README 有安装说明。`pnpm install && pnpm build` 可恢复构建。但没有启动健康检查、没有自动化环境验证。 |
| **7.5** 干净状态纪律 | **通过** | AGENTS.md 明确定义 landing gate："推送 main 之前的更高标准——`pnpm check`、`pnpm test`、`pnpm build`"。Pre-commit 钩子运行 `pnpm check`。CI 在合并前强制执行干净状态。有文档化的干净、已测试代码期望。 |
| **7.6** 持久化执行支持 | **未通过** | 没有结构化检查点文件（progress.json、执行计划）。没有恢复脚本。没有文档化的中断 Agent 会话恢复协议。 |

### 8. 安全护栏 (91.7%)

| 项目 | 评分 | 证据 |
|------|------|------|
| **8.1** 最小权限凭证 | **通过** [高级] | CI 默认 `permissions: contents: read`。Dependabot 使用范围化 NPM 令牌（`secrets.NPM_NPMJS_TOKEN`）。发布工作流使用 GitHub Environments 并配置范围化权限。CODEOWNERS 限制安全路径变更。 |
| **8.2** 审计日志 | **通过** | `config-audit.jsonl` 结构化记录：timestamp、source、event、result、configPath、pid、ppid、cwd、argv。追加写入，权限 `0o600`。命令日志钩子（`src/hooks/bundled/command-logger/`）。 |
| **8.3** 回滚能力 | **通过** | 记录在 `docs/install/updating.md`：固定 npm 版本、固定 git 提交、`plugins.deny` 用于紧急插件回滚。不是单一自动化回滚脚本，但有清晰的文档化程序。 |
| **8.4** 人工确认门控 | **通过** [高级] | GitHub Environments（`npm-release`、`docker-release`）在发布工作流上配置审批门控。所有发布工作流使用手动 `workflow_dispatch` 触发。`approve_manual_backfill` 作业带有显式门控注释。 |
| **8.5** 安全关键路径标记 | **通过** [高级] | `.github/CODEOWNERS`（54 行）：secops 审查 `src/security/`、`src/secrets/`、工作流、`SECURITY.md`、`dependabot.yml`、`codeql/`。AGENTS.md 警告："除非列出的所有者明确要求，否则不要编辑受安全关注 CODEOWNERS 规则覆盖的文件。" |
| **8.6** 工具协议信任边界 | **部分** | MCP 集成存在于产品中（`.mcp.json` bundles、secrets 测试中的 `mcpServers`）。AGENTS.md 提到受限表面。但没有专用的 MCP 范围化策略文件用于 Agent 工具访问，没有针对 Agent 工具的显式信任边界文档。 |

## 改进路线图

### 快速收益（1 天内实施）

1. **添加 `llms.txt`**（修复 5.3）— 创建根目录 `llms.txt`，包含项目描述、关键入口点和文档链接。为关键依赖添加策划的参考片段。
2. **添加 `init.sh`**（修复 7.4）— 创建根目录设置/恢复脚本，运行 `pnpm install`、`pnpm build`、健康检查和环境验证。在会话开始时自动运行。
3. **为自定义检查添加修复提示**（修复 2.6）— 增强 `check-plugin-extension-import-boundary.mjs` 和其他自定义检查脚本，在错误消息中包含特定的修复指令。
4. **对齐覆盖率阈值**（文档债务）— AGENTS.md 声明 branches 70%，但配置为 55%。统一为单一事实来源。

### 战略性投资（1-4 周）

1. **实施持久化执行支持**（修复 7.2、7.6）— 添加执行计划模板、`progress.json` 检查点文件和恢复协议。在 AGENTS.md 中记录会话交接工作流。
2. **添加对抗性验证步骤**（修复 4.7）— 创建具有只读权限的 CI 作业或 Agent 工作流，通过结构化证据报告独立验证实现（命令 + 输出 + 判定）。包含针对边界值和并发的对抗性探测。
3. **实施技术债务跟踪**（修复 6.3）— 维护由 CI 生成的质量评分工件（如 `quality-report.json`）。跟踪趋势。在文档中展示。
4. **添加 Agent 可查询的可观测性**（改进 3.3）— 创建查询最近日志、指标和追踪的 CLI 命令。允许 Agent 以编程方式检查运行时状态，无需外部仪表板。
5. **加强文档新鲜度**（改进 5.2）— 在文档中添加 frontmatter `expires` 日期。创建 CI 检查，标记过期文档（如上次更新超过 90 天且无显式续期）。

## 推荐模板

根据发现的差距，以下 harness 工程工具包中的模板最有价值：

- **`templates/init/`** — 环境恢复脚本模板（用于 7.4）
- **`templates/universal/`** — 进度跟踪和执行计划模板（用于 7.2、7.6）
- **`templates/linting/`** — 带修复提示的检查规则模式（用于 2.6）
