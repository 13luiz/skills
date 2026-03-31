# Harness 工程审计报告: OpenClaw

**日期**: 2026-04-01
**Profile**: monorepo | **Stage**: mature (50k+ LOC, 生产级产品, 20+ 维护者)
**生态系统**: TypeScript (ESM) + pnpm workspaces + Swift (macOS/iOS) + Kotlin (Android)
**仓库**: https://github.com/openclaw/openclaw

## 总评: A (85.8/100)

## 执行摘要

OpenClaw 是迄今审计过的 harness 成熟度最高的开源仓库之一。它在机械约束 (Dim 2)、架构文档 (Dim 1) 和反馈循环 (Dim 3) 方面表现卓越，拥有 14+ 自定义边界 lint 规则、覆盖 Linux/macOS/Windows 的多平台 CI、70% 覆盖率阈值、以及精心设计的渐进式知识披露体系。主要改进空间集中在：**AGENTS.md 过长** (286 行 vs 建议的 <100 行)、**缺乏正式的对抗性验证**、以及**长周期任务的检查点/恢复机制**。

## 审计参数

| 参数 | 值 |
|------|---|
| Profile | monorepo — 权重调整: dim2↑22%, dim5↑12%, dim6↑12% |
| Stage | mature — 44 项全部激活 |
| 跳过项 | 无 |
| 关键项 (monorepo) | 2.5 依赖方向, 2.7 结构约定, 5.5 缓存友好, 6.2 清理流程 |

## 维度得分

| # | 维度 | 项数 | 通过 | 得分 | 权重 | 加权分 | 控制元素 |
|---|------|------|------|------|------|--------|---------|
| 1 | 架构文档与知识管理 | 5 | 4.5 | 90.0% | 13% | 11.70 | 目标状态 |
| 2 | 机械约束 | 7 | 6.5 | 92.9% | 22% | 20.43 | 执行器 |
| 3 | 反馈循环与可观测性 | 5 | 4.5 | 90.0% | 13% | 11.70 | 传感器 |
| 4 | 测试与验证 | 7 | 5.5 | 78.6% | 13% | 10.21 | 传感器+执行器 |
| 5 | 上下文工程 | 5 | 4.0 | 80.0% | 12% | 9.60 | 目标状态 |
| 6 | 熵管理与垃圾回收 | 4 | 3.5 | 87.5% | 12% | 10.50 | 反馈循环 |
| 7 | 长周期任务支持 | 6 | 4.5 | 75.0% | 10% | 7.50 | 反馈循环 |
| 8 | 安全护栏 | 6 | 5.0 | 83.3% | 5% | 4.17 | 保护性执行器 |
| | **总计** | **45** | **38** | | **100%** | **85.81** | |

## 详细发现

### 1. 架构文档与知识管理 (90%)

| 项 | 评级 | 证据 |
|----|------|------|
| 1.1 Agent 指令文件 | **PARTIAL** | `AGENTS.md` (286 行) + `CLAUDE.md` 符号链接。内容极为全面但超出 <100 行建议的 2.8 倍。5 个子目录 AGENTS.md 用于渐进披露。 |
| 1.2 结构化知识库 | **PASS** | `docs/` 含 25+ 子目录 (channels, cli, concepts, gateway, plugins, providers, security 等)，含 i18n (zh-CN, ja-JP)，Mintlify 托管。 |
| 1.3 架构文档 | **PASS** | AGENTS.md 含 6 大架构边界定义：Plugin、Channel、Provider/Model、Gateway Protocol、Bundled Plugin Contract、Extension Test。 |
| 1.4 渐进式披露 | **PASS** | 根 AGENTS.md → `src/plugin-sdk/AGENTS.md`、`src/channels/AGENTS.md`、`src/plugins/AGENTS.md`、`src/gateway/protocol/AGENTS.md`、`src/gateway/server-methods/AGENTS.md`。有明确的 "Progressive disclosure lives in local boundary guides" 章节。 |
| 1.5 版本化知识制品 | **PASS** | VISION.md、CONTRIBUTING.md、SECURITY.md、CHANGELOG.md、`.agents/skills/` 含 8+ 专业化工作流技能，均在版本控制中。 |

### 2. 机械约束 (92.9%)

| 项 | 评级 | 证据 |
|----|------|------|
| 2.1 CI 流水线阻断 | **PASS** | `.github/workflows/ci.yml` 含 12+ 作业 (preflight, security-fast, checks, check, check-additional, build-smoke 等)，覆盖 Linux/macOS/Windows，PR 触发并阻断合并。 |
| 2.2 Linter 强制执行 | **PASS** | Oxlint (type-aware, `no-explicit-any: error`)、15+ 自定义 lint 脚本、SwiftLint、ktlint、Ruff (Python)、Shellcheck、Actionlint、zizmor (Actions 安全审计)。 |
| 2.3 Formatter 强制执行 | **PASS** | oxfmt CI 阻断 + pre-commit hook、SwiftFormat、markdownlint。 |
| 2.4 类型安全 | **PASS** | `tsconfig.json strict: true`、`no-explicit-any: error`、`pnpm tsgo` + `pnpm build:strict-smoke` 在 CI 阻断、Swift 类型安全、Kotlin 类型安全。 |
| 2.5 依赖方向规则 | **PASS** | 14+ 自定义边界 lint 在 CI 中执行 (plugin-extension-boundary、no-src-outside-plugin-sdk、no-plugin-sdk-internal、no-relative-outside-package、no-extension-src-imports、web-search-provider-boundaries 等)。 |
| 2.6 修复感知错误消息 | **PARTIAL** | 自定义 lint 脚本存在但未逐一验证含修复指引。AGENTS.md 提供了全面的常见违规修复指导。 |
| 2.7 结构约定强制执行 | **PASS** | LOC 检查 (`check:loc --max 500`)、jscpd 重复检测、knip 死代码检测、命名约定文档化、`canon:check` 规范校验。 |

### 3. 反馈循环与可观测性 (90%)

| 项 | 评级 | 证据 |
|----|------|------|
| 3.1 结构化日志 | **PASS** | tslog 框架、专用 `src/logging/` 模块、`osc-progress` CLI 进度指示器。 |
| 3.2 指标与追踪 | **PASS** | `extensions/diagnostics-otel` OpenTelemetry 扩展、指标集成。 |
| 3.3 Agent 可查询的可观测性 | **PASS** | `openclaw status --json`、`openclaw channels status --probe`、`scripts/clawlog.sh` macOS 统一日志查询。 |
| 3.4 UI 可见性 | **PARTIAL** | playwright-core 为依赖，用于 E2E 测试，但非 Agent 会话中的实时截图/检查工具。 |
| 3.5 诊断错误上下文 | **PASS** | `Result<T,E>` 风格、闭合错误码联合类型、zod 边界校验、详细错误诊断。 |

### 4. 测试与验证 (78.6%)

| 项 | 评级 | 证据 |
|----|------|------|
| 4.1 测试套件 | **PASS** | 多层测试：unit (Vitest)、E2E、live、Docker、gateway、channels、contracts、extensions、Android (JUnit)、Swift (XCTest)。 |
| 4.2 CI 测试阻断 | **PASS** | 测试在 CI 3 平台运行并阻断合并。 |
| 4.3 覆盖率阈值 | **PASS** | V8 coverage：lines 70%、functions 70%、branches 55%、statements 70%。 |
| 4.4 形式化完成标准 | **PARTIAL** | "gate" 定义完整 (local dev gate、landing gate、CI gate、hard gate)，但非 JSON/YAML 机器可读格式。 |
| 4.5 端到端验证 | **PASS** | vitest.e2e.config.ts、10+ Docker E2E 测试套件、install-smoke、Parallels 跨平台测试。 |
| 4.6 测试 Flake 管理 | **PARTIAL** | 性能预算 (`test:perf:budget`)、内存热点追踪、CI 重试 (Swift 3 次)，但无正式隔离/监控系统。 |
| 4.7 对抗性验证 | **PARTIAL** | Codex review 在 CONTRIBUTING.md 中推荐、`.agents/skills/` 含专业化技能，但无权限隔离或结构化证据报告。 |

### 5. 上下文工程 (80%)

| 项 | 评级 | 证据 |
|----|------|------|
| 5.1 外部化知识 | **PASS** | 关键决策全部在仓库：AGENTS.md、CONTRIBUTING.md、VISION.md、完整的 docs/ 体系。 |
| 5.2 文档新鲜度 | **PASS** | CI 验证：`docs:check-links`、`docs:check-i18n-glossary`、`config:docs:check`、`plugin-sdk:api:check` 漂移检测。 |
| 5.3 机器可读引用 | **PARTIAL** | 丰富的内部引用但无 `llms.txt` 或策展的依赖文档快照。 |
| 5.4 技术可组合性 | **PASS** | 标准栈：TypeScript/Node/Vitest/pnpm/Swift/Kotlin，文档完善。 |
| 5.5 缓存友好设计 | **PARTIAL** | 渐进披露优秀，但根 AGENTS.md 286 行超出缓存友好阈值。`.artifacts/`、`docs/.generated/` 结构化输出目录存在。 |

### 6. 熵管理与垃圾回收 (87.5%)

| 项 | 评级 | 证据 |
|----|------|------|
| 6.1 编码化黄金原则 | **PASS** | AGENTS.md 含详细编码原则：严格类型、避免 any、zod 边界校验、判别联合、文件大小指引。 |
| 6.2 定期清理流程 | **PASS** | `deadcode:knip`、`deadcode:ts-prune`、`deadcode:ts-unused`、`dup:check` (jscpd)、`stale.yml` workflow。 |
| 6.3 技术债追踪 | **PARTIAL** | 工具存在 (knip, jscpd, deadcode reports) 但无正式 tech-debt-tracker.json 制品。 |
| 6.4 AI 垃圾检测 | **PASS** | jscpd 重复检测、knip 死代码、strict no-explicit-any、CONTRIBUTING.md 要求 AI PR 透明度和 Codex review。 |

### 7. 长周期任务支持 (75%)

| 项 | 评级 | 证据 |
|----|------|------|
| 7.1 任务分解策略 | **PARTIAL** | `.agents/skills/` 含工作流分解 (release、GHSA、PR 维护等)，但无通用执行计划模板。 |
| 7.2 进度追踪制品 | **PARTIAL** | Git 提交 + 技能引用，无结构化 progress.json。 |
| 7.3 交接桥 | **PASS** | 多 Agent 安全规则、`scripts/committer` 范围化提交、会话日志 `~/.openclaw/agents/`。 |
| 7.4 环境恢复 | **PASS** | `pnpm install`、Docker (Dockerfile + docker-compose.yml)、`prepare` hook、AGENTS.md 恢复指引。 |
| 7.5 干净状态纪律 | **PASS** | AGENTS.md 明确禁止带失败检查的落地、pre-commit 强制、多 Agent 安全规则。 |
| 7.6 持久执行支持 | **PARTIAL** | Agent 技能提供工作流结构，但无正式检查点文件或崩溃恢复协议。 |

### 8. 安全护栏 (83.3%)

| 项 | 评级 | 证据 |
|----|------|------|
| 8.1 最小权限凭证 | **PASS** | CI：`permissions: contents: read`、`persist-credentials: false`、Token 范围化。 |
| 8.2 审计日志 | **PASS** | GitHub PR/部署日志、`audit:seams` 脚本、detect-secrets 基线、zizmor 工作流安全审计。 |
| 8.3 回滚能力 | **PARTIAL** | Git 回滚可行、Docker 版本化，但无文档化的回滚剧本。 |
| 8.4 人工确认门 | **PASS** | 发布需操作者明确同意、npm publish 需许可、版本变更需审批。 |
| 8.5 安全关键路径标记 | **PASS** | 全面的 CODEOWNERS：`@openclaw/secops` 覆盖 30+ 安全敏感路径 (secrets、auth、security docs 等)。 |
| 8.6 工具协议信任边界 | **PARTIAL** | AGENTS.md 提及工具输出审慎处理，但无正式 MCP 最小权限作用域策略。 |

## 改进路线图

### 快速收益 (1 天内实施)

1. **瘦身 AGENTS.md** (1.1 → PASS, 5.5 → PASS)
   - 将根 AGENTS.md 从 286 行精简到 <100 行的目录/索引
   - 将 "Coding Style & Naming Conventions"、"Testing Guidelines"、"Commit & PR Guidelines" 等章节拆分到 `docs/dev/` 或子目录 AGENTS.md
   - 保留顶层结构指引和命令速查，深度内容用指针引用

2. **添加 tech-debt-tracker.json** (6.3 → PASS)
   - 创建结构化的技术债追踪文件，记录已知债务项、优先级、负责人

3. **添加 rollback playbook** (8.3 → PASS)
   - 在 `docs/reference/` 创建回滚文档，覆盖 npm 发布回滚、Docker 回滚、数据库迁移回滚场景

4. **创建 llms.txt** (5.3 → PASS)
   - 在根目录创建 `llms.txt` 或 `docs/llms.txt`，为 Agent 列出关键依赖文档引用

### 战略投资 (1-4 周)

1. **对抗性验证系统** (4.7 → PASS, 预计 +2.6 分)
   - 实现三层验证：实现前顾问、实现后对抗性验证器 (只读、结构化证据)、计划级完成验证
   - 验证器使用权限隔离 (程序化移除写工具)
   - 反合理化提示嵌入验证器系统提示

2. **正式的 Flake 管理** (4.6 → PASS)
   - 实现 flaky test 隔离/标记机制
   - 追踪 flake 频率和修复状态
   - 在 CI 中集成重试 + 监控

3. **执行计划模板 + 检查点机制** (7.1, 7.2, 7.6 → PASS, 预计 +2.5 分)
   - 创建 `docs/dev/execution-plan-template.md`
   - 实现结构化检查点文件 (`progress.json`) 用于长任务
   - 添加崩溃恢复协议文档

4. **修复感知错误消息** (2.6 → PASS)
   - 审查 14+ 自定义边界 lint 脚本，确保每个违规输出含修复步骤
   - 格式："错误：你从 X 导入了 Y。应该使用 Z，因为……"

### 预期收益

完成快速收益后：**~88 分** (A)
完成所有投资后：**~94 分** (A+)

## 特别亮点

这个仓库有几个**值得作为行业标杆**的实践：

1. **14+ 自定义边界 lint 规则** — 机械化地强制执行架构边界，而非依赖文档约定
2. **多平台 CI 覆盖** — Linux + macOS + Windows，含 sharding 和智能变更检测
3. **多 Agent 安全规则** — AGENTS.md 明确记录了多 Agent 并行工作的安全协议（不创建 stash、不切换分支、范围化提交）
4. **配置/SDK 漂移检测** — `config:docs:check` 和 `plugin-sdk:api:check` 确保文档与代码同步
5. **渐进式 AGENTS.md 体系** — 根文件 + 5 个子目录 AGENTS.md 的分层知识架构

## 观察到的反模式

1. **AGENTS.md 超过 100 行** — 根指令文件 286 行，存在缓存淘汰和上下文溢出风险。渐进披露结构缓解了这一问题，但根文件仍应精简。
2. **无机器可读完成标准** — Gate 定义在散文中有良好文档，但未以 JSON/YAML 格式提供给 Agent 程序化验证。
3. **验证缺少对抗性探测** — Codex review 存在但缺乏结构化证据格式和对抗性边界值测试。

---

*审计使用 Harness Engineering Guide 技能 v1.0 执行。Profile: monorepo (应用了权重覆盖)。Stage: mature (44/44 项激活)。全部 8 个维度均含文件级证据评分。*
