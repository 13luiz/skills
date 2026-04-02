# Harness Engineering Guide 技能升级差异分析

**日期**: 2026-04-02
**对比版本**: v1.2.0 (2026-04-01) → v1.3.3 (2026-04-02)
**审计对象**: OpenCode v1.3.13 (monorepo/mature), OpenFang v0.5.7 (system-infra/growth)
**语言**: 中文 (zh)

---

## 一、总评对比

| 项目 | v1.2.0 评分 | v1.2.0 等级 | v1.3.3 评分 | v1.3.3 等级 | 变化 |
|------|-----------|-----------|-----------|-----------|------|
| OpenCode | 68.4 | C+ | 60.0 | C | -8.4 |
| OpenFang | 75.3 | B | 65.0 | C | -10.3 |

两个项目均出现显著下降。仓库代码未变（同一 tag），差异完全源自技能升级。

---

## 二、OpenCode 逐项差异（19 项变化）

### 2.1 评分降低项（14 项，共 -7.0 分）

| 项目 | v1.2.0 | v1.3.3 | 差异原因 | 可归因于 |
|------|--------|--------|---------|---------|
| 1.3 架构文档 | PARTIAL (0.5) | FAIL (0.0) | v1.3.3 判定无独立 ARCHITECTURE.md 等同 FAIL | 审计员差异 |
| 1.4 渐进式披露 | PASS (1.0) | PARTIAL (0.5) | **新规则 §1.4**: 根 AGENTS.md 未链接子包 → PARTIAL | 新消歧规则 |
| 2.7 结构约定 | PASS (1.0) | PARTIAL (0.5) | **新规则 §2.7**: 需≥2 机械执行机制 | 新消歧规则 |
| 4.3 覆盖率阈值 | PARTIAL (0.5) | FAIL (0.0) | v1.3.3 认为无阈值配置 = FAIL | 审计员差异 |
| 4.4 形式化完成标准 | PARTIAL (0.5) | FAIL (0.0) | v1.3.3 认为 PR 模板非机器可读 = FAIL | 审计员差异 |
| 4.6 闪烁测试 | PASS (1.0) | PARTIAL (0.5) | v1.3.3 认为缺少 quarantine 策略文档 | 审计员差异 |
| 5.2 文档新鲜度 | PASS (1.0) | PARTIAL (0.5) | 发现 docs-update.yml 在 anomalyco/opencode 上不触发 | 审计质量提升 |
| 5.4 技术可组合性 | PASS (1.0) | PARTIAL (0.5) | Effect 框架 AI 不友好，evals 预设此发现 | 新评估标准 |
| 6.2 周期性清理 | PASS (1.0) | PARTIAL (0.5) | v1.3.3 未充分识别 close-stale-prs/close-issues 等 cron | 审计员遗漏 |
| 6.4 AI 水文检测 | PASS (1.0) | PARTIAL (0.5) | **新规则 §6.4**: rmslop 手动命令 = PARTIAL | 新消歧规则 |
| 7.1 任务分解 | PARTIAL (0.5) | FAIL (0.0) | v1.3.3 未识别 Turbo 任务图 + specs/project.md | 审计员遗漏 |
| 8.1 最小权限 | PASS (1.0) | PARTIAL (0.5) | v1.3.3 对 workflow permissions 判断偏保守 | 审计员差异 |
| 8.2 审计日志 | PASS (1.0) | PARTIAL (0.5) | **新规则 §8.2**: GitHub 原生历史 = PARTIAL | 新消歧规则 |
| 8.4 人工确认 | PASS (1.0) | PARTIAL (0.5) | v1.3.3 认为非全面双人审批 | 审计员差异 |

### 2.2 评分升高项（5 项，共 +2.5 分）

| 项目 | v1.2.0 | v1.3.3 | 差异原因 | 可归因于 |
|------|--------|--------|---------|---------|
| 2.3 格式化 | FAIL (0.0) | PARTIAL (0.5) | v1.2.0 过严；Prettier 已配置但未 CI 强制 = PARTIAL | v1.2.0 评分错误 |
| 3.5 诊断错误 | PARTIAL (0.5) | PASS (1.0) | Effect Cause 模式达到最低证据标准（≥2/3） | 新最低证据规则 |
| 6.3 债务追踪 | FAIL (0.0) | PARTIAL (0.5) | Issue 标签 + VOUCHED.td 提供部分追踪 | 审计质量提升 |
| 7.6 持久执行 | FAIL (0.0) | PARTIAL (0.5) | 识别到部分进度机制 | 审计员差异 |
| 8.3 回滚能力 | FAIL (0.0) | PARTIAL (0.5) | **新规则 §8.3**: git tag 发布 = PARTIAL | 新消歧规则 |

### 2.3 评分不变项（26 项）

1.1, 1.2, 2.1, 2.2, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.5, 4.7, 5.1, 5.3, 5.5, 6.1, 7.2, 7.3, 7.4, 7.5, 8.5, 8.6 — 共 25 项 + 1.2 = 26 项

---

## 三、OpenFang 逐项差异（13 项变化）

### 3.1 评分降低项（9 项，共 -4.5 分）

| 项目 | v1.2.0 | v1.3.3 | 差异原因 | 可归因于 |
|------|--------|--------|---------|---------|
| 1.1 代理指令 | PASS (1.0) | PARTIAL (0.5) | **新最低证据规则**: CLAUDE.md 未链接 docs/ | 新消歧规则 |
| 1.4 渐进式披露 | PASS (1.0) | PARTIAL (0.5) | **新规则 §1.4**: CLAUDE.md 无 TOC 指向文档 | 新消歧规则 |
| 2.1 CI 阻断 | PASS (1.0) | PARTIAL (0.5) | 无法在仓库内验证 branch protection | 审计员差异（偏保守） |
| 2.7 结构约定 | PASS (1.0) | PARTIAL (0.5) | **新规则 §2.7**: clippy/fmt 为通用工具，非项目级结构约定 | 新消歧规则 |
| 3.1 结构化日志 | PASS (1.0) | PARTIAL (0.5) | 默认输出为人类可读文本非 JSON | 审计员差异（偏严格） |
| 4.2 CI 测试阻断 | PASS (1.0) | PARTIAL (0.5) | 同 2.1，无法验证 branch protection | 审计员差异（偏保守） |
| 6.1 黄金原则 | PASS (1.0) | PARTIAL (0.5) | **新最低证据规则**: CLAUDE.md 未引用 CONTRIBUTING.md | 新消歧规则 |
| 6.4 AI 水文检测 | PARTIAL (0.5) | FAIL (0.0) | **新规则 §6.4**: Clippy 非 AI 特定检测 = FAIL | 新消歧规则 |
| 8.4 人工确认 | PASS (1.0) | PARTIAL (0.5) | v1.3.3 认为 tag 触发不等同全面确认门控 | 审计员差异 |

### 3.2 评分升高项（4 项，共 +2.0 分）

| 项目 | v1.2.0 | v1.3.3 | 差异原因 | 可归因于 |
|------|--------|--------|---------|---------|
| 5.2 文档新鲜度 | FAIL (0.0) | PARTIAL (0.5) | 识别到 PR 审查作为部分机制 | 审计员差异 |
| 5.5 缓存友好 | PARTIAL (0.5) | PASS (1.0) | CLAUDE.md 精炼 + docs/ 按主题拆分 | 审计质量提升 |
| 7.1 任务分解 | FAIL (0.0) | PARTIAL (0.5) | CONTRIBUTING.md 含分步指导 | 审计质量提升 |
| 7.4 环境恢复 | PARTIAL (0.5) | PASS (1.0) | 发现 scripts/install.sh + install.ps1 | 审计质量提升 |

### 3.3 评分不变项（16 项）

1.2, 1.3, 2.2, 2.3, 2.4, 2.5, 3.5, 4.1, 4.3, 4.5, 4.7, 5.1, 7.2, 7.5, 8.1, 8.3

---

## 四、差异根因分类

| 类别 | OpenCode | OpenFang | 合计 |
|------|---------|---------|------|
| **新消歧规则** (rubric 变更) | 5 项 (1.4, 2.7, 6.4, 8.2, 8.3) | 6 项 (1.1, 1.4, 2.7, 6.1, 6.4, +8.3不变) | 10 项（去重） |
| **新最低证据规则** | 1 项 (3.5) | 2 项 (1.1, 6.1) | 3 项 |
| **审计质量提升**（发现更多/更少证据） | 3 项 (5.2, 6.3, 2.3修正) | 3 项 (5.5, 7.1, 7.4) | 6 项 |
| **审计员差异**（主观判断偏移） | 10 项 | 4 项 | 14 项 |

---

## 五、逐项合理性评估

### 5.1 由新消歧规则引起的变化

#### §1.4 渐进式披露（OpenCode & OpenFang）

- **正确性**: ★★★★★ — 根文件不链接子文件，代理确实无法通过单一入口发现所有指导，PARTIAL 合理
- **必要性**: ★★★★★ — v1.2.0 中两个项目都给了 PASS 但理由薄弱（子文件存在≠可发现），消歧必要
- **简洁性**: ★★★★☆ — 规则清晰（"读根文件能否找到所有子文件？"），可稍精简措辞

#### §6.4 AI 水文检测（OpenCode & OpenFang）

- **正确性**: ★★★★★ — rmslop 是手动命令（非自动化），Clippy 无 AI 特定规则，区分合理
- **必要性**: ★★★★★ — v1.2.0 将手动命令评为 PASS 混淆了"意识"和"自动化"的界限
- **简洁性**: ★★★★★ — "手动调用 = PARTIAL，自动规则 = PASS" 判断标准简明

#### §8.2 审计日志（OpenCode）

- **正确性**: ★★★★☆ — GitHub 原生历史提供可追溯性但非目的性审计系统，PARTIAL 合理；但对开源项目略严
- **必要性**: ★★★★☆ — 区分"平台默认"和"专用系统"有价值，但主要影响企业级项目
- **简洁性**: ★★★★★ — 规则清晰

#### §8.3 回滚能力（OpenCode）

- **正确性**: ★★★★★ — git tag 确实支持临时回退（非 FAIL），但无文档化剧本（非 PASS）
- **必要性**: ★★★★★ — v1.2.0 的 FAIL 过于严厉，PARTIAL 是明显更准确的评价
- **简洁性**: ★★★★★ — "能回退但无剧本 = PARTIAL" 判断直观

#### §2.7 结构约定（OpenCode & OpenFang）

- **正确性**: ★★★☆☆ — **存在争议**
  - OpenCode: pr-standards.yml (PR 标题)、bunfig.toml (测试根限制)、compliance-close.yml (自动关闭) 构成≥2 机械机制，v1.2.0 的 PASS 可能更合理
  - OpenFang: clippy + rustfmt 是通用工具，v1.3.3 认为不算"项目级结构约定"有一定道理，但 cargo-audit + TruffleHog 也是机械约束
- **必要性**: ★★★★☆ — 区分"通用工具"和"项目特定约定"是有价值的维度
- **简洁性**: ★★★☆☆ — 规则中"至少 2 种机械执行机制"的范围定义不够清晰，什么算"结构约定"需要进一步界定

#### §1.2 结构化知识库（规则存在但 OpenCode 未触发降级）

- **正确性**: ★★★★★ — v1.3.3 审计员正确判断 README 链接到文档站 = PASS（满足替代条件）
- **简洁性**: ★★★★☆ — "根 docs/ 或 README 直接链接" 的双路径规则清晰

### 5.2 由新最低证据规则引起的变化

#### 3.5 诊断错误上下文（OpenCode: PARTIAL→PASS）

- **正确性**: ★★★★★ — Effect 的 Cause 模式提供堆栈 + 状态 + 建议修复（≥2/3 证据阈值）
- **必要性**: ★★★★★ — 最低证据规则减少了"结构化错误算不算充分"的主观判断空间
- **简洁性**: ★★★★★ — "≥2/3 条件" 机械可判

#### 6.1 黄金原则（OpenFang: PASS→PARTIAL）

- **正确性**: ★★★★☆ — CLAUDE.md 未引用 CONTRIBUTING.md，代理需自行发现原则文件；但 CONTRIBUTING.md 是标准文件名，代理大概率会自动读取
- **必要性**: ★★★★☆ — 要求代理入口"链接"而非"假设代理知道查找"是合理的严格化
- **简洁性**: ★★★★★ — "原则必须从代理指令文件可引用" 判断清晰

### 5.3 审计质量提升（发现了 v1.2.0 遗漏的证据）

| 项目 | 变化 | 评价 |
|------|------|------|
| OpenCode 2.3 | FAIL→PARTIAL | **v1.2.0 评分错误**。Prettier 已配置 = PARTIAL 而非 FAIL |
| OpenCode 5.2 | PASS→PARTIAL | **v1.3.3 发现实质问题**: docs-update.yml 仓库条件不匹配 |
| OpenCode 6.3 | FAIL→PARTIAL | **v1.3.3 发现更多证据**: Issue 标签 + VOUCHED.td |
| OpenFang 5.5 | PARTIAL→PASS | **v1.3.3 更准确**: CLAUDE.md 精炼，文档分散化 |
| OpenFang 7.1 | FAIL→PARTIAL | **v1.3.3 发现更多证据**: CONTRIBUTING.md 分步指导 |
| OpenFang 7.4 | PARTIAL→PASS | **v1.3.3 发现关键文件**: scripts/install.sh + install.ps1 |

这 6 项变化均为**正面改进**，反映审计质量的客观提升。

### 5.4 审计员差异（主观判断偏移 — 需关注）

以下变化**非源自规则变更**，而是审计代理的主观判断不同：

| 项目 | 变化 | 合理性 | 建议 |
|------|------|--------|------|
| OpenCode 1.3 | PARTIAL→FAIL | ⚠️ **偏严**。CONTRIBUTING.md 含包职责描述 = "部分架构信息"，应维持 PARTIAL | 需修正 |
| OpenCode 4.3 | PARTIAL→FAIL | ⚠️ **偏严**。`bun test --coverage` 确实收集覆盖率（虽无阈值），checklist 说"Coverage measured but no thresholds"=PARTIAL | 需修正 |
| OpenCode 4.4 | PARTIAL→FAIL | ⚠️ **偏严**。PR 模板清单是"人类可读完成标准"，符合 PARTIAL 条件 | 需修正 |
| OpenCode 6.2 | PASS→PARTIAL | ⚠️ **遗漏**。close-stale-prs.yml、close-issues.yml、compliance-close.yml 均为 cron 自动化清理 | 需修正 |
| OpenCode 7.1 | PARTIAL→FAIL | ⚠️ **偏严**。Turbo 任务图 + specs/project.md 构成"非正式分解"，符合 PARTIAL | 需修正 |
| OpenCode 8.1 | PASS→PARTIAL | ⚠️ **偏保守**。per-job 权限作用域 (`contents: read`) 是有效的最小权限实践 | 需修正 |
| OpenCode 8.4 | PASS→PARTIAL | △ **可接受**。workflow_dispatch 是有意操作但非"人工确认门控" | 视项目而定 |
| OpenCode 4.6 | PASS→PARTIAL | △ **可接受**。Playwright retry 有效但缺少系统化策略文档 | 可保留 |
| OpenFang 2.1 | PASS→PARTIAL | ⚠️ **偏保守**。CI 在 PR 上运行且设计为门禁，branch protection 是 GitHub 设置而非仓库文件 | 需修正 |
| OpenFang 3.1 | PASS→PARTIAL | ⚠️ **偏严**。`tracing` 框架 + span 字段 + 关联 ID 已满足"结构化日志"标准，JSON 输出格式非必需 | 需修正 |
| OpenFang 4.2 | PASS→PARTIAL | ⚠️ **同 2.1**。CI 运行测试的事实不应因无法验证 branch protection 而降级 | 需修正 |
| OpenFang 5.2 | FAIL→PARTIAL | △ **可接受**。识别到 PR 审查作为部分机制 | 可保留 |
| OpenFang 8.4 | PASS→PARTIAL | △ **可接受**。tag 触发是有意操作，但非显式确认界面 | 视项目而定 |
| OpenCode 7.6 | FAIL→PARTIAL | △ **可接受**。找到部分进度机制 | 可保留 |

**标记 ⚠️ 的 8 项为明显的审计员偏差**，这些变化不源自规则升级，而是 v1.3.3 审计代理在执行时过于保守或遗漏了已有证据。

---

## 六、对技能升级的综合评估

### 6.1 评分标准变更评估

| 新规则 | 正确性 | 必要性 | 简洁性 | 总评 |
|--------|--------|--------|--------|------|
| §1.4 渐进式披露导航链 | ★★★★★ | ★★★★★ | ★★★★☆ | 优秀 |
| §6.4 手动命令 vs 自动规则 | ★★★★★ | ★★★★★ | ★★★★★ | 优秀 |
| §8.2 平台原生 vs 专用审计 | ★★★★☆ | ★★★★☆ | ★★★★★ | 良好 |
| §8.3 临时回退 = PARTIAL | ★★★★★ | ★★★★★ | ★★★★★ | 优秀 |
| §2.7 机械执行 ≥2 种 | ★★★☆☆ | ★★★★☆ | ★★★☆☆ | 需改进 |
| §1.2 文档路径位置 | ★★★★★ | ★★★★★ | ★★★★☆ | 优秀 |
| §2.2 Linter 覆盖范围 | ★★★★★ | ★★★★★ | ★★★★★ | 优秀 |
| 最低证据规则 (3.5, 6.1 等) | ★★★★★ | ★★★★★ | ★★★★★ | 优秀 |
| 可复现性分类 (mechanical/judgment) | ★★★★☆ | ★★★☆☆ | ★★★★★ | 良好 |

### 6.2 重复实现检查

| 检查项 | 结论 |
|--------|------|
| dimension-scanners.sh/ps1 vs 旧 content-analyzers.sh | **无重复**。content-analyzers.sh 已删除（-337 行），功能合并入 dimension-scanners.sh（+601 行）。是重构非重复。 |
| validate-data-consistency.sh vs validate-data-consistency.ps1 | **合理双平台支持**。Bash 和 PowerShell 各 128 行，面向不同操作系统。非重复。 |
| harness-audit.sh vs harness-audit.ps1 | **合理双平台支持**。主脚本的 Bash/PowerShell 双版本是 cross-platform 需求。 |
| scoring-rubric.md 中新增的消歧规则 vs checklist.md 中的判据 | **互补无重复**。checklist.md 定义 PASS/PARTIAL/FAIL 的基本标准，scoring-rubric.md 的消歧规则处理灰区判断。两者角色不同。 |

**结论: 未发现重复实现。**

### 6.3 过度设计检查

| 检查项 | 评估 |
|--------|------|
| **可复现性分类** (mechanical vs judgment) | 理论价值高（设定一致性预期），但本次审计中**未被审计代理实际引用**。24 项 mechanical 的分类未影响任何评分决策。**当前为文档性功能，非执行性功能**——合理但 ROI 待验证。 |
| **最低证据规则** (9 条) | **高价值**。直接影响了 3.5 PASS 和 6.1 PARTIAL 的判定。有效减少主观性。 |
| **Streaming Audit Protocol** | **高价值**。为大型审计提供结构化上下文管理。本次两个审计代理均受益于批次化处理。 |
| **7 条消歧规则** | 5 条高价值、1 条良好、1 条需改进（§2.7 范围不清）。总体非过度设计。 |
| **data validation scripts** (128 行 ×2) | 数据完整性验证脚本。作为回归防护合理；但当前数据文件变更频率低，ROI 一般。 |

**结论: 未发现过度设计，但可复现性分类和数据验证脚本处于"预防性投资"阶段，价值需随使用积累验证。**

---

## 七、发现的问题与改进建议

### 7.1 需要修复的审计评分（8 项偏差）

以下评分偏差不是由规则升级引起的，而是审计代理执行时的判断错误：

1. **OpenCode 1.3**: FAIL→应为 PARTIAL（CONTRIBUTING.md 含包职责描述）
2. **OpenCode 4.3**: FAIL→应为 PARTIAL（`bun test --coverage` 确实收集覆盖率）
3. **OpenCode 4.4**: FAIL→应为 PARTIAL（PR 模板含人类可读清单）
4. **OpenCode 6.2**: PARTIAL→应为 PASS（close-stale-prs/close-issues/compliance-close 均为自动化 cron）
5. **OpenCode 7.1**: FAIL→应为 PARTIAL（Turbo 任务图 + specs/project.md 为非正式分解）
6. **OpenCode 8.1**: PARTIAL→应为 PASS（per-job 权限作用域是有效最小权限）
7. **OpenFang 2.1/4.2**: PARTIAL→应为 PASS（CI 在 PR 上运行，branch protection 是 GitHub 设置非仓库文件；按 checklist "CI runs on every PR" 已满足）
8. **OpenFang 3.1**: PARTIAL→应为 PASS（tracing 框架 + span 字段 + 关联 ID 满足结构化日志标准）

### 7.2 规则改进建议

1. **§2.7 结构约定**: 需明确定义"项目级结构约定"的范围。建议增加示例表：

   | 算作结构约定 | 不算 |
   |------------|------|
   | 文件命名规则 (eslint-plugin-filenames) | 通用代码风格 (prettier) |
   | 导入限制 (no-restricted-imports) | 通用 lint (clippy defaults) |
   | PR 标题格式 (conventional-commits CI) | 基本格式化 (rustfmt) |
   | 测试路径限制 (bunfig.toml test root) | 类型检查 (tsc strict) |

2. **2.1/4.2 CI 阻断**: 需明确 "blocks merges on failure" 的判定标准。建议增加：
   > CI 以 PR 触发的 required check 设计（workflow 名称暗示门禁用途）在无法验证 branch protection 设置时，应按 PASS 评分。仅当 CI 明确不阻断（如 `continue-on-error: true`）或不在 PR 上触发时，才评 PARTIAL 或 FAIL。

3. **3.1 结构化日志**: 需明确 JSON 格式是否为 PASS 的必要条件。建议：
   > 使用 tracing/log4j/winston 等结构化日志框架，并具备 level、context fields、correlation ID 中至少 2 项，即可评 PASS。JSON 输出格式非必需；框架本身提供的结构化能力已满足标准。

### 7.3 如果修正 8 项偏差后的预期评分

**OpenCode 修正后**: +0.5×6 = +3.0 分 → 约 62.6 (C)
**OpenFang 修正后**: +0.5×3 = +1.5 分，对应维度重新计算 → 约 70.1 (B)

---

## 八、结论

### 技能升级总体评价

v1.2.0 → v1.3.3 的升级是一次**有效且方向正确的改进**：

1. **7 条消歧规则中 5 条优秀、1 条良好、1 条需改进**，显著减少了灰区判断的模糊性
2. **最低证据规则**为判断型项目提供了锚点，是最高 ROI 的新增内容
3. **脚本重构**（content-analyzers → dimension-scanners）提升了代码组织，无功能重复
4. **Streaming Audit Protocol** 为大型审计的上下文管理提供了结构化方案

### 需要关注的问题

1. **审计代理一致性**: v1.3.3 审计中出现 8 项非规则引起的评分偏差（占总变化项的 25%），说明审计代理在执行新规则时倾向过度保守。建议在 SKILL.md 中增加"保守性校准"指引：对于 mechanical 类项目，若文件/配置证据明确存在，不应因"无法验证外部平台设置"而降级。

2. **§2.7 范围模糊**: 当前规则的"结构约定"定义不够精确，导致两个项目均因不同解读而降级。需要补充更明确的示例边界。

3. **评分漂移量**: 同一仓库在规则升级后下降 8-10 分，虽然其中约 4 分可归因于审计员偏差（应修正），但即便修正后仍有 4-6 分的系统性下降。这反映了 v1.3.3 的"严格化"方向——应在 skill 版本变更日志中明确记录，以免用户将规则收紧误读为项目退步。

---

*分析由 Harness Engineering Guide v1.3.3 差异评估流程生成。*
