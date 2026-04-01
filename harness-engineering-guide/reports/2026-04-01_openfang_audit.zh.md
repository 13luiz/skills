# Harness Engineering 审计报告: OpenFang v0.5.7

**日期**: 2026-04-01
**配置**: system-infra | **阶段**: growth
**生态**: Rust (edition 2021) + Cargo workspace (14 crates)
**语言**: 中文 (zh)

## 总评: B (75.3/100)

## 执行摘要

OpenFang v0.5.7 是一个 Rust 多 crate 系统级项目（14 个工作区成员），展现出扎实的机械约束基础（91.7%）：CI 在三平台矩阵上运行 cargo check/test/clippy/fmt/audit/secret-scan，`RUSTFLAGS="-D warnings"` 将所有警告升格为错误。架构文档体系完备（100%）——`CLAUDE.md` 精炼（124 行）、`docs/architecture.md` 含详尽 TOC、`docs/README.md` 作为文档枢纽。结构化日志使用 `tracing` 生态（含 TraceLayer、request_id 中间件）。主要差距在于测试与验证（60%）：无覆盖率阈值、无对抗性验证。长期任务支持（37.5%）是最薄弱环节——`xtask` 仍是空壳、无任务分解策略。上下文工程（50%）因缺乏文档新鲜度机制和超长 `architecture.md` 而受影响。

## 审计参数

| 参数 | 值 |
|------|-----|
| 配置 | system-infra — 基础权重: dim2 0.25, dim4 0.22, dim8 0.10 |
| 阶段 | growth — 29/45 项激活（跳过高级实践项） |
| 权重覆盖 | growth 阶段覆盖: dim1 0.15, dim2 0.22, dim3 0.10, dim4 0.18, dim5 0.10, dim6 0.07, dim7 0.10, dim8 0.08 |
| 语言 | 中文 (zh) |
| 跳过项（配置） | 3.3 代理可查询可观测性, 3.4 UI 可见性, 5.3 机器可读参考 |
| 跳过项（阶段） | 1.5, 2.6, 3.2, 3.3, 3.4, 4.4, 4.6, 5.3, 5.4, 6.2, 6.3, 7.3, 7.6, 8.2, 8.5, 8.6 |
| Crate 数量 | 14（openfang-types/memory/runtime/wire/api/kernel/cli/channels/migrate/skills/desktop/hands/extensions + xtask） |

## 维度评分

| # | 维度 | 项目 | 通过 | 得分 | 权重 | 加权 | 控制环要素 |
|---|------|------|------|------|------|------|-----------|
| 1 | 架构文档与知识管理 | 4 | 4.0/4 | 100.0% | 15% | 15.00 | 目标状态 |
| 2 | 机械约束 | 6 | 5.5/6 | 91.7% | 22% | 20.17 | 执行器 |
| 3 | 反馈回路与可观测性 | 2 | 2.0/2 | 100.0% | 10% | 10.00 | 传感器 |
| 4 | 测试与验证 | 5 | 3.0/5 | 60.0% | 18% | 10.80 | 传感器+执行器 |
| 5 | 上下文工程 | 3 | 1.5/3 | 50.0% | 10% | 5.00 | 目标状态 |
| 6 | 熵管理与垃圾回收 | 2 | 1.5/2 | 75.0% | 7% | 5.25 | 反馈回路 |
| 7 | 长期任务支持 | 4 | 1.5/4 | 37.5% | 10% | 3.75 | 反馈回路 |
| 8 | 安全护栏 | 3 | 2.0/3 | 66.7% | 8% | 5.33 | 执行器（防护） |
| **总计** | | **29** | **21.0/29** | | | **75.30** | |

**评级: B (75.3/100)**

## 详细发现

### 1. 架构文档与知识管理 (100.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 1.1 | 代理指令文件 | **PASS** (1.0) | `CLAUDE.md` 存在于仓库根目录，124 行——低于 150 行默认阈值。包含构建/验证步骤、架构概述、集成测试强制要求和常见陷阱。无 AGENTS.md 或 .cursorrules。 |
| 1.2 | 结构化知识库 | **PASS** (1.0) | `docs/` 目录含 22 个文件，涵盖入门指南、配置、CLI 参考、故障排查、架构、代理模板、工作流、安全、通道适配器、提供商、技能开发、MCP/A2A、API 参考、桌面端、生产清单、发布路线图等。 |
| 1.3 | 架构文档 | **PASS** [exemplary] (1.0) | `docs/architecture.md` 为长篇综合架构文档，含 TOC 链接到各节（crate 结构、启动流程、生命周期、内存、LLM、安全、通道、技能、MCP/A2A、协议、桌面端、架构图）。 |
| 1.4 | 渐进式披露 | **PASS** (1.0) | `docs/README.md` 作为文档枢纽，含表格链接到各主题指南（渐进式跨文档 TOC）。`architecture.md` 内部 TOC 提供节内导航。 |

### 2. 机械约束 (91.7%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 2.1 | CI 管线阻断 | **PASS** [exemplary] (1.0) | `.github/workflows/ci.yml` 触发于 push/PR 至 `main`。7 个并行 job：`check`（三平台矩阵 `cargo check --workspace`）、`test`（三平台 `cargo test --workspace`）、`clippy`、`fmt`、`audit`（cargo-audit）、`secrets`（TruffleHog 文件系统扫描）、`install-smoke`（安装脚本语法检查）。`release.yml` 处理 tag 触发的 Tauri 桌面 + CLI 跨平台编译 + Docker GHCR 推送。 |
| 2.2 | Linter 强制执行 | **PASS** (1.0) | CI 运行 `cargo clippy --workspace -- -D warnings`。`rust-toolchain.toml` 确保 `clippy` 组件可用。`RUSTFLAGS="-D warnings"` 在 check job 中将所有警告升格为错误。 |
| 2.3 | 格式化强制执行 | **PASS** (1.0) | CI 运行 `cargo fmt --check`。`rustfmt.toml` 配置 `max_width = 100`。`rust-toolchain.toml` 确保 `rustfmt` 组件可用。 |
| 2.4 | 类型安全 | **PASS** [exemplary] (1.0) | Rust 类型系统固有强类型。`edition = "2021"`，`rust-version = "1.75"`，`resolver = "2"`。`RUSTFLAGS="-D warnings"` 确保零警告编译。`cargo check --workspace` 在三平台矩阵上运行。 |
| 2.5 | 依赖方向规则 | **PARTIAL** (0.5) | `docs/architecture.md` 文档化了 "Dependencies flow downward" 层级规则。但无 `cargo-deny`（无 `deny.toml`）、无自动化依赖方向检测。依赖层级仅靠约定维护。 |
| 2.7 | 结构约定强制 | **PASS** (1.0) | CI 机械强制多项约定：Clippy（代码约定）、rustfmt（格式约定）、cargo-audit（依赖安全约定）、TruffleHog（秘密检测约定）。`CONTRIBUTING.md` 文档化风格规范（doc comments、`thiserror`、禁止库代码中 `unwrap`）。 |

### 3. 反馈回路与可观测性 (100.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 3.1 | 结构化日志 | **PASS** [exemplary] (1.0) | `tracing` 作为工作区依赖，广泛使用于所有 crate（runtime、api、wire 等）。`tracing-subscriber` + `EnvFilter` 初始化。`tower_http::trace::TraceLayer` 在 API 服务器中。`middleware.rs` 使用 `tracing::info!` 记录 request_id、method、path、status、latency。手工 Prometheus 文本指标通过 HTTP 路由暴露（gauges: uptime, agent counts, token/tool usage）。 |
| 3.5 | 诊断错误上下文 | **PASS** (1.0) | `OpenFangError`（`crates/openfang-types/src/error.rs`）包含可操作文本（如 "max iterations" 指向 `agent.toml [autonomous] max_iterations`）。API 层添加 request_id。`llm_errors.rs` 含 LLM 错误分类体系。路径安全错误含具体拒绝原因（`tool_runner.rs`、`workspace_sandbox.rs`）。 |

### 4. 测试与验证 (60.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 4.1 | 测试套件 | **PASS** [exemplary] (1.0) | 跨 crate 全面测试：API 集成（`api_integration_test.rs`、`daemon_lifecycle_test.rs`、`load_test.rs`）、内核集成（`integration_test.rs`、`multi_agent_test.rs`、`wasm_agent_integration_test.rs`、`workflow_integration_test.rs`）、通道桥接（`bridge_integration_test.rs`）、迁移（4 个测试文件）。 |
| 4.2 | 测试 CI 阻断 | **PASS** (1.0) | `cargo test --workspace` 在三平台矩阵上运行（ubuntu/macos/windows），触发于 PR 至 `main`。 |
| 4.3 | 覆盖率阈值 | **FAIL** (0.0) | 无 tarpaulin、llvm-cov 或 Codecov 配置。CI 工作流中无覆盖率收集或门控步骤。 |
| 4.5 | 端到端验证 | **PASS** (1.0) | 多 crate 集成测试覆盖完整调用栈（API → 内核 → 运行时 → 工作流）。`api_integration_test.rs` 和 `daemon_lifecycle_test.rs` 测试端到端场景。CI 中运行。`test_vertex_e2e.py` 存在（Vertex AI E2E）但未集成到 CI。 |
| 4.7 | 对抗性验证 | **FAIL** (0.0) | 无 cargo-fuzz 或属性测试框架。无专用对抗性验证代理/步骤。`scan_prompt_content()` 是产品安全特性而非开发 harness。 |

### 5. 上下文工程 (50.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 5.1 | 知识外化 | **PASS** (1.0) | 丰富的 `docs/` 目录（22 个文件）、`CLAUDE.md`、`CONTRIBUTING.md`（含架构表格）、`SECURITY.md`、`CHANGELOG.md`、`MIGRATION.md`。关键决策和约定均在仓库内。 |
| 5.2 | 文档新鲜度机制 | **FAIL** (0.0) | 无自动化文档过期检查。发现不一致：`docs/README.md` 声称 "Tests \| 967" vs `README.md`/`CONTRIBUTING.md` 声称 "1,767+"/"1,744+" 测试——数据冲突未被机械检测。 |
| 5.5 | 缓存友好设计 | **PARTIAL** (0.5) | `docs/README.md` 索引和 `architecture.md` TOC 有助于导航。但 `architecture.md` 约 900+ 行——对代理上下文窗口而言偏大。`CLAUDE.md` 精炼（124 行）。 |

### 6. 熵管理与垃圾回收 (75.0%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 6.1 | 编码化黄金原则 | **PASS** (1.0) | `docs/architecture.md` 含稳定性指南。`CONTRIBUTING.md` 含详细风格规范：doc comments 风格、`thiserror` 错误处理、禁止库代码 `unwrap`、`tracing` 日志约定。`prompt_builder.rs` 中的静态操作指南。 |
| 6.4 | AI 水文检测 | **PARTIAL** (0.5) | Clippy 能捕获部分通用代码质量问题。无专门的 AI 生成代码检测规则。提示注入扫描（`scan_prompt_content()`）是产品功能，非开发 harness。 |

### 7. 长期任务支持 (37.5%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 7.1 | 任务分解策略 | **FAIL** (0.0) | `xtask` crate 作为工作区成员声明，但 `xtask/src/main.rs` 仅打印 "xtask: no tasks defined yet"——空壳。无文档化的任务分解模板或策略。 |
| 7.2 | 进度追踪制品 | **PARTIAL** (0.5) | `CHANGELOG.md`、`docs/launch-roadmap.md`、`docs/production-checklist.md` 提供叙事/清单式进度。非结构化代理任务状态文件。 |
| 7.4 | 环境恢复 | **PARTIAL** (0.5) | `docs/troubleshooting.md` 和 `CONTRIBUTING.md` 文档化了 doctor 命令和开发设置。无专用 `init.sh` 或自动化环境恢复脚本。 |
| 7.5 | 清洁状态纪律 | **PARTIAL** (0.5) | 测试使用 `tempfile` 和随机端口（`CONTRIBUTING.md`）。CI 使用全新 runner。隐式维护但未正式文档化。 |

### 8. 安全护栏 (66.7%)

| ID | 项目 | 评分 | 证据 |
|----|------|------|------|
| 8.1 | 最小权限凭证 | **PARTIAL** (0.5) | 环境变量管理 API 密钥。`Zeroizing` 依赖确保内存中密钥清零。扩展 crate 使用 AES-GCM 保险箱。CI 运行 TruffleHog + cargo audit。但 `test_vertex_e2e.py` 含硬编码 Windows 服务账户路径——负面示例。 |
| 8.3 | 回滚能力 | **PARTIAL** (0.5) | 技能/文档中提及回滚概念。Release 通过 tag 触发，可通过 git 回溯。但无首要的回滚命令、剧本或自动化脚本用于项目自身。 |
| 8.4 | 人工确认门控 | **PASS** (1.0) | 能力/RBAC 模型和路径遍历检查（`middleware.rs` 环回关闭检查、路径拒绝字符串）。Release 通过 tag 触发（有意操作）。`WASM sandbox` 限制扩展能力。 |

## 检测到的反模式

| 反模式 | 状态 | 证据 |
|--------|------|------|
| Clippy 参数漂移 | **已检测** | `CLAUDE.md`/`CONTRIBUTING.md` 使用 `cargo clippy --workspace --all-targets`，但 CI 仅使用 `cargo clippy --workspace`（缺少 `--all-targets`）。可能导致测试/示例代码未被 lint。 |
| xtask 空壳 | **已检测** | `xtask` 声明为工作区成员但仅打印"no tasks defined yet"。占用工作区位置但无功能。 |
| 硬编码凭证路径 | **已检测** | `test_vertex_e2e.py` 含硬编码 Windows 服务账户路径。应使用环境变量。 |
| 版本字符串漂移 | **已检测** | `Cargo.toml` workspace version 为 "0.5.5"，但 git tag 为 v0.5.7。版本号不一致。 |
| 测试数量不一致 | **已检测** | `docs/README.md` 声称 "Tests \| 967"；`README.md` 声称 "1,767+"；`CONTRIBUTING.md` 声称 "1,744+"。文档间数据冲突。 |

## 维度 < 50% 升级建议

> *维度 7（长期任务支持）得分 37.5%。建议执行完整审计以识别具体差距并生成详细改进路线图。*

## 改进路线图

### 快速胜利（1 天内实施）
1. **实现 xtask 或删除空壳**：要么在 `xtask/src/main.rs` 中实现有用的自动化任务（格式检查、依赖审查），要么从工作区中移除空壳（修复 7.1 FAIL 的前置条件）。
2. **添加覆盖率收集**：在 CI 中集成 `cargo tarpaulin` 或 `cargo llvm-cov`，设置最低阈值（修复 4.3 FAIL）。
3. **对齐 Clippy 参数**：统一 CLAUDE.md/CONTRIBUTING 和 CI 中的 clippy 命令为 `--workspace --all-targets`。
4. **修复测试数量不一致**：统一 docs/README.md、README.md、CONTRIBUTING.md 中的测试计数。
5. **移除硬编码路径**：将 `test_vertex_e2e.py` 中的服务账户路径改为环境变量。

### 战略投资（1-4 周）
1. **添加 cargo-deny**：创建 `deny.toml` 配置依赖许可证审查、禁止不安全依赖、强制依赖方向（提升 2.5）。
2. **添加文档新鲜度检查**：在 CI 中添加文档一致性验证（如测试数量自动提取与文档对比）（修复 5.2 FAIL）。
3. **建立任务分解标准**：文档化代理开发工作流的任务分解策略，创建执行计划模板（修复 7.1 FAIL）。
4. **拆分 architecture.md**：将 ~900 行的架构文档拆分为多个聚焦文档，由 architecture.md 作为 TOC 链接（提升 5.5）。
5. **添加对抗性验证**：引入 cargo-fuzz 或 proptest 进行属性测试（修复 4.7 FAIL）。
6. **添加 AI 水文检测规则**：配置自定义 Clippy lint 或 CI 脚本检测常见 AI 生成模式（提升 6.4）。

## 推荐模板
- `templates/universal/execution-plan.md` — 用于任务分解和 xtask 实现
- `templates/universal/tech-debt-tracker.json` — 为成熟阶段准备的债务追踪器
- `templates/universal/doc-gardening-prompt.md` — 用于文档新鲜度自动化
