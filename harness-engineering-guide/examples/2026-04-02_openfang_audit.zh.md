# Harness Engineering 审计报告: OpenFang v0.5.7

**日期**: 2026-04-02  
**配置**: system-infra | **阶段**: growth  
**生态**: Rust (edition 2021) + Cargo workspace  
**语言**: 中文 (zh)

## 总评: B (73/100)

## 执行摘要

OpenFang 在机械约束（CI、Clippy、格式化、类型检查）与文档/架构可读性上表现扎实，`tracing` 与 API 中间件提供了可观测的请求维度与 `x-request-id` 关联。主要短板集中在测试覆盖率门禁缺失、长期任务分解与进度工件缺席、AI 生成代码治理与部分安全/发布护栏仍依赖人工而非仓库内可执行策略。

## 审计参数

| 参数 | 值 |
|------|-----|
| Profile | system-infra |
| Stage | growth（本报告仅评 29 项活跃项） |
| 工作区 crate 数 | 14（`crates/*` ×13 + `xtask`） |
| Profile skip_items | 3.3, 3.4, 5.3 |
| Growth 活跃项 | 29 项（见用户给定列表） |
| 合并跳过项（不在 growth 活跃集中） | 1.5, 2.6, 3.2, 3.3, 3.4, 4.4, 4.6, 5.3, 5.4, 6.2, 6.3, 7.3, 7.6, 8.2, 8.5, 8.6 |
| 维度权重（growth 覆盖，优先于 profile） | dim1=0.15, dim2=0.22, dim3=0.10, dim4=0.18, dim5=0.10, dim6=0.07, dim7=0.10, dim8=0.08 |
| 审计路径 | `D:\tmp\harness-eval\openfang` |
| 版本一致性说明 | 标签审计对象为 v0.5.7；根 `Cargo.toml` `workspace.package.version` 为 **0.5.5**（需核对发布流程） |

## 维度评分

| 维度 | 本阶段活跃项数 | 得分（仅活跃项） | 权重 |
|------|----------------|------------------|------|
| 1 架构文档与知识 | 4 | 87.5% | 0.15 |
| 2 机械约束 | 6 | 91.7% | 0.22 |
| 3 可观测与反馈 | 2 | 100% | 0.10 |
| 4 测试与验证 | 5 | 60.0% | 0.18 |
| 5 上下文工程 | 3 | 66.7% | 0.10 |
| 6 熵与垃圾回收 | 2 | 50.0% | 0.07 |
| 7 长任务支持 | 4 | 50.0% | 0.10 |
| 8 安全护栏 | 3 | 50.0% | 0.08 |

**加权总分计算**：  
\(0.15×87.5 + 0.22×91.7 + 0.10×100 + 0.18×60 + 0.10×66.7 + 0.07×50 + 0.10×50 + 0.08×50 \approx 73.3\) → **73/100（等级 B）**。

## 详细发现

### 维度 1 — 架构文档与知识管理

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **1.1** Agent 指令文件 | **PASS** | 1.0 | `CLAUDE.md`（约 123 行）存在；含构建/验证流程、强制 live 集成测试步骤、架构约束与常见陷阱，低于 150 行阈值。 |
| **1.2** 结构化知识库 | **PASS** | 1.0 | `docs/` 存在；`docs/README.md` 为索引并链接多份指南。 |
| **1.3** 架构文档 | **PASS** | 1.0 | `docs/architecture.md` 描述 crate 结构、依赖自上而下流向、各 crate 职责与启动序列，满足边界与依赖叙事。 |
| **1.4** 渐进式披露 | **PARTIAL** | 0.5 | `CLAUDE.md` 篇幅合格且信息分层，但**缺少指向 `docs/*.md` 的显式导航链接**（多为源码路径与操作步骤），未达到「入口 TOC + 深链文档」的完整形态。 |

### 维度 2 — 机械约束

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **2.1** CI 存在且作为 PR 门禁设计 | **PASS** | 1.0 | `.github/workflows/ci.yml`：`on.pull_request.branches: [main]`，含 `check` / `test` / `clippy` / `fmt` / `audit` / `secrets` 等 job；按保守口径，**PR 门禁设计为合并前闸门**（分支保护属平台侧）。 |
| **2.2** Linter 强制执行 | **PASS** | 1.0 | 无独立 `clippy.toml`，但 CI 运行 `cargo clippy --workspace -- -D warnings`；**`.github/workflows/ci.yml` 顶层 `env.RUSTFLAGS: "-D warnings"`** 与 Clippy 共同构成 Rust 侧 linter/警告门禁（根 `Cargo.toml` 未再声明 `RUSTFLAGS`）。 |
| **2.3** 格式化强制执行 | **PASS** | 1.0 | `rustfmt.toml`（`max_width = 100`）；CI `cargo fmt --check`。 |
| **2.4** 类型安全 | **PASS** | 1.0 | Rust 内置类型检查；CI `cargo check --workspace`。 |
| **2.5** 依赖方向规则 | **PARTIAL** | 0.5 | `docs/architecture.md` 明确「Dependencies flow downward」与 crate 图；**未发现**在 CI 中强制 crate 依赖方向的自定义 lint/结构测试。 |
| **2.7** 结构约定强制执行 | **PASS** | 1.0 | 至少两项：`cargo fmt --check`、`cargo clippy … -D warnings`，叠加 `RUSTFLAGS=-D warnings`（警告即失败）。 |

**已知不一致**：`CLAUDE.md` 建议 `cargo clippy --workspace --all-targets`，而 **`.github/workflows/ci.yml` 未使用 `--all-targets`**，存在文档与 CI 行为偏差。

### 维度 3 — 可观测与反馈回路

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **3.1** 结构化日志 | **PASS** | 1.0 | `tracing` + `tracing-subscriber`（`Cargo.toml` workspace 依赖含 `json` feature）；`crates/openfang-cli/src/main.rs` 中 `init_tracing_stderr` / `init_tracing_file` 使用 `EnvFilter`（级别）；`crates/openfang-api/src/middleware.rs` 中 `info!(request_id = %request_id, method = %method, path = %uri, status, latency_ms, …)`（上下文字段 + **请求关联 ID**）。满足框架 + 多维度结构化要求。 |
| **3.5** 诊断性错误上下文 | **PASS** | 1.0 | 广泛使用 `thiserror`；例：`crates/openfang-types/src/error.rs` 中带场景说明与部分修复提示（如 `MaxIterationsExceeded` 指向配置路径）。 |

### 维度 4 — 测试与验证

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **4.1** 测试套件存在 | **PASS** | 1.0 | 多个 `tests/` 目录与集成测试文件，例如 `crates/openfang-kernel/tests/*.rs`、`crates/openfang-api/tests/*.rs`、`crates/openfang-channels/tests/*.rs`。 |
| **4.2** CI 中运行测试并阻断 | **PASS** | 1.0 | `.github/workflows/ci.yml` 中 `cargo test --workspace`。 |
| **4.3** 覆盖率阈值 | **FAIL** | 0.0 | 仓库内**无** `cargo-tarpaulin`/`llvm-cov` 等覆盖率配置，亦无 CI 阈值门禁。 |
| **4.5** 端到端验证 | **PASS** | 1.0 | 虽无 Playwright/Cypress，但存在真实 HTTP + 内核启动的集成测试：`crates/openfang-api/tests/api_integration_test.rs`、`daemon_lifecycle_test.rs`、`load_test.rs`；随 `cargo test --workspace` 在 CI 中执行，符合本系统「API/守护进程」E2E 形态。 |
| **4.7** 对抗性验证 | **FAIL** | 0.0 | **未发现**独立 verifier 代理、隔离权限的固定验证脚本与结构化对抗探针报告流程；验证主要依赖常规测试与贡献者自检。 |

### 维度 5 — 上下文工程

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **5.1** 外化知识 | **PASS** | 1.0 | `docs/` 与架构/安全/CLI 等文档齐备；决策可读、可检索。 |
| **5.2** 文档新鲜度机制 | **FAIL** | 0.0 | **无** doc freshness CI、过期元数据或定期 doc gardening 工作流；`.github/dependabot.yml` 仅覆盖 cargo 与 GitHub Actions。 |
| **5.5** 缓存友好上下文设计 | **PASS** | 1.0 | `CLAUDE.md` 低于 150 行；配置与状态外置至 `~/.openfang/` 等（见 `CLAUDE.md` / 文档），符合「短入口 + 外置状态」导向。 |

### 维度 6 — 熵管理

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **6.1** 成文黄金原则 | **PASS** | 1.0 | `CONTRIBUTING.md` 明确构建、测试、PR 流程；`CLAUDE.md` 含「MANDATORY: Live Integration Testing」等硬性工程约束，与代理工作流对齐。 |
| **6.4** AI Slop 检测 | **FAIL** | 0.0 | 全库检索**无**针对 AI 生成模式/重复工具函数的专用 lint 或 CI 规则；依赖通用 Clippy/审查。 |

### 维度 7 — 长任务支持

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **7.1** 任务分解策略 | **FAIL** | 0.0 | 清单要求类 `docs/exec-plans/`、`EXECUTION_PLAN.md` 等模式；仓库内**不存在**对应目录/文件（definitive 口径）。 |
| **7.2** 进度跟踪工件 | **FAIL** | 0.0 | 无 `progress.md` / `progress.json` 等约定工件；存在源码 `crates/openfang-cli/src/progress.rs`（终端进度 UI），**不满足**清单对跨会话进度文件的定义。 |
| **7.4** 环境恢复 | **PASS** | 1.0 | `docker-compose.yml`、`scripts/install.sh`、`scripts/install.ps1`、`rust-toolchain.toml`、`flake.nix` 等多轨恢复路径。 |
| **7.5** 干净状态纪律 | **PASS** | 1.0 | `CONTRIBUTING.md` 要求合并前测试通过；`.github/pull_request_template.md` 含测试与安全自检勾选，形成可传播的「干净合并」期望。 |

### 维度 8 — 安全护栏

| 项 | 判定 | 得分 | 证据与说明 |
|----|------|------|------------|
| **8.1** 最小权限凭证 | **PARTIAL** | 0.5 | `docs/security.md` 等与实现体现纵深防御、能力模型与密钥通过环境变量注入；**未**在仓库层面对「代理/自动化令牌最小权限矩阵」作单独、可审计的规范条目，故保守给部分分。 |
| **8.3** 回滚能力 | **PARTIAL** | 0.5 | `.github/workflows/release.yml` 与 `docs/production-checklist.md` 描述发布与验证；**缺少**明确的回滚/runbook 章节（如坏版本撤回、镜像标签策略、桌面自动更新降级步骤的标准操作文档）。 |
| **8.4** 人工确认闸门 | **PARTIAL** | 0.5 | PR 模板提供人工勾选清单；CI **未**对破坏性操作配置 GitHub Environments / 必需审批等硬闸门，主要依赖流程与审查文化。 |

---

## 检测到的反模式

| 反模式 | 严重度 | 证据 |
|--------|--------|------|
| 发布版本与标签漂移 | 中 | `Cargo.toml` `workspace.package.version = "0.5.5"` vs 审计标签 v0.5.7 |
| 文档与 CI 命令不一致 | 低 | `CLAUDE.md`：`clippy --all-targets` vs `ci.yml`：无 `--all-targets` |
| 占位/空心自动化 | 低 | `xtask/src/main.rs` 仅打印「no tasks defined yet」，与 `docs/architecture.md` 对 xtask 的描述期望不符 |
| 关键路径无 CODEOWNERS | 中 | 无 `.github/CODEOWNERS`（growth 未评 8.5，但影响安全审查基线） |
| 无覆盖率门禁 | 中 | 质量信号依赖测试数量与 Clippy，无覆盖阈值 |
| 长期任务工件缺失 | 中 | 无 exec-plan / progress 工件，多会话协作可重复成本高 |

## 改进路线图

### 快速胜利（1 天内实施）

- 统一 **Clippy 调用**：在 `.github/workflows/ci.yml` 增加 `--all-targets` 或与 `CLAUDE.md` 对齐并注明差异原因。  
- 修正 **`workspace.package.version`** 与发布标签/CHANGELOG 一致，避免消费者与供应链扫描混淆。  
- 在 `CLAUDE.md` 顶部增加 **指向 `docs/README.md` / `docs/architecture.md` 的短链**，满足渐进式披露。  
- 补充 **`.github/CODEOWNERS`**（至少 `crates/openfang-api/`、`openfang-kernel/`、`openfang-runtime/`）。

### 战略投资（1–4 周）

- 引入 **`cargo llvm-cov` 或 `tarpaulin`**，在 CI 设定合理阈值并分阶段上调。  
- 增加 **`docs/exec-plans/` 模板** 与可选 `progress.json` 约定，支撑 growth 阶段长任务治理。  
- 为 crate 依赖方向添加 **可执行检查**（如 `cargo-deny` 策略或自定义测试扫描 `Cargo.toml` 边）。  
- 建立 **AI 贡献护栏**（例如自定义 Clippy lint 组合、重复工具检测脚本、PR 标签策略）。  
- 编写 **发布回滚 runbook**（GitHub Release 回退、`latest.json`、容器 tag、桌面更新失败场景）。  
- 充实 **`xtask`**：将常用发布/校验任务从文档迁入可重复命令。

## 推荐模板

- **CI 工作流**：`harness-engineering-guide/templates/ci/github-actions/standard-pipeline.yml`（按需融合 coverage 与 doc freshness）。  
- **功能/完成度跟踪**：`harness-engineering-guide/templates/universal/feature-checklist.json`。  
- **技术债跟踪**：`harness-engineering-guide/templates/universal/tech-debt-tracker.json`。  
- **执行计划骨架**：`harness-engineering-guide/templates/universal/execution-plan.md`。  
- **Clippy 工作区约定**：`harness-engineering-guide/templates/linting/clippy-workspace.toml`（若采用独立 Clippy 配置）。

*审计由 Harness Engineering Guide v1.5.4 生成。*
