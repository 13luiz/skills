# Harness Engineering Guide 版本差异分析

**对比版本**: v1.3.3 → v1.5.4  
**对比日期**: 2026-04-02  
**对比项目**: OpenCode v1.3.13、OpenFang v0.5.7

---

## 一、总览

| 项目 | v1.3.3 得分 | v1.5.4 得分 | 变化 | 等级变化 |
|------|------------|------------|------|----------|
| OpenCode | 60/100 (C) | 57/100 (C) | -3 | 无变化 |
| OpenFang | 65/100 (C) | 73/100 (B) | +8 | C → B |

> **注意**: v1.5.4 OpenCode 报告存在两处**算术错误**（Dim 3 和 Dim 8），修正后实际得分约为 55/100，差异为 -5 分。详见下方「计算准确性审计」。

---

## 二、OpenCode 逐项评分变化（v1.3.3 → v1.5.4）

### 维度 1 — 架构文档（60% → 60%，无变化）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 1.1 | PASS | PASS | — | |
| 1.2 | PASS | PASS | — | |
| 1.3 | **FAIL** | **PARTIAL** | ↑ | v1.5.4 认为 CONTRIBUTING.md 描述包边界构成部分架构文档 |
| 1.4 | PARTIAL | PARTIAL | — | |
| 1.5 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 对「版本化知识工件」标准更严格，要求 ADR 目录 |

### 维度 2 — 机械约束（57.1% → 42.9%，下降 14.2%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 2.1 | PASS | PASS | — | |
| 2.2 | FAIL | FAIL | — | |
| 2.3 | PARTIAL | PARTIAL | — | |
| 2.4 | **PASS** | **PARTIAL** | ↓ | v1.5.4 发现 `noUncheckedIndexedAccess: false`，认为非严格模式 |
| 2.5 | PARTIAL | PARTIAL | — | |
| 2.6 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 更严格：无自定义 lint 规则即 FAIL |
| 2.7 | PARTIAL | PARTIAL | — | |

### 维度 3 — 可观测性（80% → 70%↓，但实际计算应为 60%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 3.1 | PASS | PASS | — | |
| 3.2 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 更严格：AI SDK experimental 配置不算 metrics |
| 3.3 | PARTIAL | PARTIAL | — | |
| 3.4 | PASS | PASS | — | |
| 3.5 | **PASS** | **PARTIAL** | ↓ | v1.5.4 认为非全库统一「建议修复步骤」级别 |

> **算术错误**: v1.5.4 报告声称 3.5/5=70%，但 1+0+0.5+1+0.5=3.0/5=60%。

### 维度 4 — 测试与验证（57.1% → 71.4%，上升 14.3%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 4.1 | PASS | PASS | — | |
| 4.2 | PASS | PASS | — | |
| 4.3 | **FAIL** | **PARTIAL** | ↑ | v1.5.4 认为存在 --coverage 运行但无阈值为 PARTIAL |
| 4.4 | FAIL | FAIL | — | |
| 4.5 | PASS | PASS | — | |
| 4.6 | **PARTIAL** | **PASS** | ↑ | v1.5.4 发现 Playwright retries + trace/screenshot 策略 |
| 4.7 | PARTIAL | PARTIAL | — | |

### 维度 5 — 上下文工程（60% → 60%，无变化）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 5.1 | PASS | PASS | — | |
| 5.2 | PARTIAL | PARTIAL | — | |
| 5.3 | FAIL | FAIL | — | |
| 5.4 | PARTIAL | PARTIAL | — | |
| 5.5 | PASS | PASS | — | |

### 维度 6 — 熵管理（62.5% → 62.5%，无变化）

全部项评分一致。

### 维度 7 — 长任务支持（41.7% → 33.3%，下降 8.4%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 7.1 | FAIL | FAIL | — | |
| 7.2 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 使用 definitive 口径：无 progress 文件即 FAIL |
| 7.3 | PARTIAL | PARTIAL | — | |
| 7.4 | **PARTIAL** | **PARTIAL** | — | 不同理由但同分 |
| 7.5 | PARTIAL | PARTIAL | — | |
| 7.6 | PARTIAL | PARTIAL | — | |

### 维度 8 — 安全护栏（50% → 58.3%↑，但实际计算应为 50%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 8.1 | PARTIAL | PARTIAL | — | |
| 8.2 | **PARTIAL** | **PARTIAL** | — | v1.5.4 证据不同但同分 |
| 8.3 | PARTIAL | PARTIAL | — | |
| 8.4 | PARTIAL | PARTIAL | — | |
| 8.5 | PARTIAL | **PASS** | ↑ | v1.5.4 使用 definitive 口径：CODEOWNERS 文件存在即 PASS |
| 8.6 | PARTIAL | **FAIL** | ↓ | v1.5.4 更严格：无 MCP 配置策略即 FAIL |

> **算术错误**: v1.5.4 报告声称 3.5/6=58.3%，但 0.5+0.5+0.5+0.5+1+0=3.0/6=50%。

---

## 三、OpenFang 逐项评分变化（v1.3.3 → v1.5.4）

### 维度 1 — 架构文档（75% → 87.5%，上升 12.5%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 1.1 | **PARTIAL** | **PASS** | ↑ | v1.3.3 认为未链接 docs 故 PARTIAL；v1.5.4 聚焦行数+内容质量 |
| 1.2 | PASS | PASS | — | |
| 1.3 | PASS | PASS | — | |
| 1.4 | PARTIAL | PARTIAL | — | |

### 维度 2 — 机械约束（75% → 91.7%，上升 16.7%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 2.1 | **PARTIAL** | **PASS** | ↑ | v1.5.4 采用保守性校准：PR 门禁设计 = PASS，不因分支保护不可验证而降级 |
| 2.2 | PASS | PASS | — | |
| 2.3 | PASS | PASS | — | |
| 2.4 | PASS | PASS | — | |
| 2.5 | PARTIAL | PARTIAL | — | |
| 2.7 | **PARTIAL** | **PASS** | ↑ | v1.5.4 认为 fmt+clippy+RUSTFLAGS 满足「≥2 机械强制」 |

### 维度 3 — 可观测与反馈（75% → 100%，上升 25%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 3.1 | **PARTIAL** | **PASS** | ↑ | v1.5.4 依据 rubric：框架+级别+上下文字段+关联ID满足PASS |
| 3.5 | PASS | PASS | — | |

### 维度 4 — 测试与验证（50% → 60%，上升 10%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 4.1 | PASS | PASS | — | |
| 4.2 | **PARTIAL** | **PASS** | ↑ | 同 2.1：保守性校准，PR 门禁设计 = PASS |
| 4.3 | FAIL | FAIL | — | |
| 4.5 | PASS | PASS | — | |
| 4.7 | FAIL | FAIL | — | |

### 维度 5 — 上下文工程（83.3% → 66.7%，下降 16.7%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 5.1 | PASS | PASS | — | |
| 5.2 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 更严格：无任何自动化新鲜度机制即 FAIL |
| 5.5 | PASS | PASS | — | |

### 维度 6 — 熵管理（25% → 50%，上升 25%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 6.1 | **PARTIAL** | **PASS** | ↑ | v1.5.4 认为 CONTRIBUTING.md + CLAUDE.md 工程约束满足 PASS |
| 6.4 | FAIL | FAIL | — | |

### 维度 7 — 长任务支持（62.5% → 50%，下降 12.5%）

| 项 | v1.3.3 | v1.5.4 | 变化 | 说明 |
|----|--------|--------|------|------|
| 7.1 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 使用 definitive 口径：无 exec-plans 即 FAIL |
| 7.2 | **PARTIAL** | **FAIL** | ↓ | v1.5.4 使用 definitive 口径：无 progress 文件即 FAIL |
| 7.4 | PASS | PASS | — | |
| 7.5 | **PARTIAL** | **PASS** | ↑ | v1.5.4 认为 PR 模板+CONTRIBUTING 满足 PASS |

### 维度 8 — 安全护栏（50% → 50%，无变化）

全部项评分一致。

---

## 四、差异分类汇总

共发现 **22 处** 评分变化（跨两个项目的具体项目级变化），归类如下：

### A. 因保守性校准导致的评分上调（5 处）

| 项目 | 项 | v1.3.3→v1.5.4 | 原因 |
|------|-----|---------------|------|
| OpenFang | 2.1 | PARTIAL→PASS | PR 门禁设计 = PASS（保守性校准规则） |
| OpenFang | 4.2 | PARTIAL→PASS | 同上 |
| OpenFang | 2.7 | PARTIAL→PASS | 机械约束计数规则明确化：≥2 = PASS |
| OpenFang | 3.1 | PARTIAL→PASS | 结构化日志 rubric 细化：框架+字段+关联ID = PASS |
| OpenFang | 1.1 | PARTIAL→PASS | 聚焦文件本身质量而非与 docs 链接 |

### B. 因 definitive 口径导致的评分下调（3 处）

| 项目 | 项 | v1.3.3→v1.5.4 | 原因 |
|------|-----|---------------|------|
| OpenFang | 7.1 | PARTIAL→FAIL | definitive 项：文件不存在 = FAIL |
| OpenFang | 7.2 | PARTIAL→FAIL | definitive 项：文件不存在 = FAIL |
| OpenCode | 7.2 | PARTIAL→FAIL | definitive 项：文件不存在 = FAIL |

### C. 因 rubric 条目细化导致的评分变化（8 处）

| 项目 | 项 | v1.3.3→v1.5.4 | 原因 |
|------|-----|---------------|------|
| OpenCode | 2.4 | PASS→PARTIAL | 发现 `noUncheckedIndexedAccess: false` |
| OpenCode | 2.6 | PARTIAL→FAIL | 无自定义 lint 规则 = FAIL（rubric 要求更明确） |
| OpenCode | 3.2 | PARTIAL→FAIL | AI SDK experimental ≠ 平台级 metrics |
| OpenCode | 3.5 | PASS→PARTIAL | 非全库统一修复建议 = PARTIAL |
| OpenCode | 8.5 | PARTIAL→PASS | definitive 口径：CODEOWNERS 存在 = PASS |
| OpenCode | 8.6 | PARTIAL→FAIL | 无 MCP 策略 = FAIL |
| OpenFang | 5.2 | PARTIAL→FAIL | 无自动化新鲜度机制 = FAIL |
| OpenFang | 6.1 | PARTIAL→PASS | 成文原则覆盖面判定细化 |

### D. 因证据发现差异导致的评分变化（6 处）

| 项目 | 项 | v1.3.3→v1.5.4 | 原因 |
|------|-----|---------------|------|
| OpenCode | 1.3 | FAIL→PARTIAL | v1.5.4 发现 CONTRIBUTING.md Core pieces |
| OpenCode | 1.5 | PARTIAL→FAIL | v1.5.4 更严格搜索 ADR 目录 |
| OpenCode | 4.3 | FAIL→PARTIAL | v1.5.4 发现 --coverage 运行 |
| OpenCode | 4.6 | PARTIAL→PASS | v1.5.4 发现 Playwright retries + trace 配置 |
| OpenFang | 7.5 | PARTIAL→PASS | v1.5.4 发现 PR 模板含自检清单 |
| OpenFang | 2.1 | PARTIAL→PASS | v1.5.4 采用保守性校准（与 A 类重叠） |

---

## 五、v1.5.4 OpenCode 报告计算准确性审计

| 维度 | 报告声称 | 实际正确值 | 偏差 |
|------|----------|-----------|------|
| Dim 3 | 70.0%（3.5/5） | 60.0%（3.0/5） | **+10%（错误）** |
| Dim 8 | 58.3%（3.5/6） | 50.0%（3.0/6） | **+8.3%（错误）** |

**影响**: 报告总分 56.57 → 修正后应为 **~53.5/100**（等级可能从 C 降至 D）。

**原因分析**: 子代理在汇总各项得分时出现加法错误（将某些项多计 0.5 分）。这是 LLM 执行数学运算时的已知薄弱点，与技能本身的设计无关，但说明需要在 SKILL.md 中增加对最终计算的交叉验证要求。

---

## 六、差异质量评估

### 正确性评估

| 差异类别 | 正确性 | 评判 |
|----------|--------|------|
| **保守性校准上调**（A 类, 5 处） | **高** | v1.5.4 的 scoring-rubric.md 明确规定「CI designed as gate = PASS; 不因外部 branch protection 降级」。v1.3.3 对 OpenFang 2.1/4.2 给 PARTIAL 属过保守。升级合理。 |
| **definitive 口径下调**（B 类, 3 处） | **高** | 双层评估模型将 7.1/7.2 标记为 `script_role: definitive`，文件不存在即 FAIL。v1.3.3 给 PARTIAL 缺乏标准化依据。v1.5.4 更可复现。 |
| **rubric 条目细化**（C 类, 8 处） | **中高** | 多数细化合理（如 3.1 结构化日志标准、2.7 结构约定计数规则）。但 OpenCode 2.4 (PASS→PARTIAL) 存在争议：`noUncheckedIndexedAccess: false` 是否足以否定「CI 中类型检查 = PASS」，rubric 未明确此级别差异。 |
| **证据发现差异**（D 类, 6 处） | **中** | 反映了 LLM 审计的固有随机性。例如 1.3 在 v1.3.3 给 FAIL 但 v1.5.4 发现 CONTRIBUTING.md 描述；4.6 在 v1.3.3 给 PARTIAL 但 v1.5.4 发现 Playwright retries 配置。这些差异更多归因于审计代理的探索路径，而非技能规则变化。 |

### 必要性评估

| 变更 | 必要性 | 理由 |
|------|--------|------|
| 双层评估模型 (definitive/prescreen/none) | **高** | 解决了 v1.3.3 中审计者自由裁量空间过大的问题。definitive 项使用脚本输出直接决定评分，消除人为偏差。 |
| 保守性校准规则 | **高** | v1.3.3 对 CI 门禁的判断不一致（OpenCode 给 PASS，OpenFang 给 PARTIAL），新规则统一了标准。 |
| scoring-rubric.md 边界案例细化 | **中** | 3.1（结构化日志）和 2.7（结构约定）的细化减少了模糊地带，但部分细化（如 8.6 MCP 策略）对大多数项目可能过早。 |
| checklist-items.json script_output_mapping | **高** | 45 项完整映射到 JSON 输出路径，使 Tier 1→Tier 2 的传递链路透明化。 |
| 测试文件抽样分析 (v1.5.2) | **低** | 增加了测试文件 per-directory 分布输出，但在实际评分中未见显著影响。 |

### 简洁性评估

| 方面 | 评价 |
|------|------|
| **SKILL.md 变化** | +46 行主要用于双层评估模型说明和流式审计协议补充。必要且不冗余。 |
| **checklist-items.json** | +600 行：大量新增 `script_output_mapping` 和 `auto_detect` 字段。结构合理，但 45 项的完整映射表可考虑自动生成而非手写。 |
| **profiles.json** | +224 行：增加 `weight_rationale` 和 `calibration_notes`。有助于理解权重选择的依据，但文字量偏大。 |
| **报告输出** | v1.5.4 报告比 v1.3.3 略短（OpenCode: 204 行 vs 172 行）。格式更统一，但 v1.5.4 减少了工作流逐一审阅的详细记录。 |

---

## 七、重复实现检查

| 检查项 | 结论 |
|--------|------|
| script_output_mapping 与 checklist.md | **无重复**：前者是机器可读映射，后者是人类可读评分标准。互补关系。 |
| dimension-scanners.sh 与 dimension-scanners.ps1 | **必要重复**：跨平台支持（Bash + PowerShell）。但两者逻辑必须保持同步，维护成本较高。 |
| profiles.json 中的 weight_rationale 与 scoring-rubric.md 中的 Project-Type Adaptations | **轻微重叠**：两处都解释了为什么某些维度权重不同。建议 profiles.json 中的 rationale 保留为简短引用，详细说明集中在 scoring-rubric.md。 |
| scoring-rubric.md 中 Borderline Guidance 与 checklist-items.json 中的 pass_criteria | **功能互补**：前者是边界案例指导，后者是结构化标准。目前无实质性重复。 |

---

## 八、过度设计检查

| 检查项 | 结论 |
|--------|------|
| **双层评估模型** | **不是过度设计**。6 个 definitive 项 + 27 个 prescreen 项 + 12 个 none 项的分类使评分流程标准化，减少 LLM 审计的随机性。 |
| **script_output_mapping（45 项完整映射）** | **边界情况**。映射本身有价值，但 12 个 `no_script_signal` 项的显式标注可能只需在文档中说明「未列出的项即为 none」。不过显式优于隐式。 |
| **profiles.json weight_rationale** | **轻微过度设计**。每个 profile 约 30-50 字的 rationale 有助于可解释性，但 `calibration_notes` 字段引用了「8 real-repo audits」的校准数据——这些数据并未公开，引用价值有限。 |
| **流式审计协议** | **不是过度设计**。对 mature 阶段 45 项审计，分 3 批次处理是防止 LLM 上下文溢出的实用策略。 |
| **测试文件 per-directory 分布输出 (v1.5.2)** | **轻微过度设计**。在当前评分体系中，测试文件的目录分布不直接影响任何项的 PASS/PARTIAL/FAIL 判定。信息价值为「补充参考」而非「决策依据」。 |
| **8.6 MCP 工具协议信任** | **对多数项目过早**。MCP 使用尚未普及，将其作为 mature 阶段的必评项可能导致大量项目在此项上获得 FAIL，降低评分的区分度。 |

---

## 九、结论与建议

### 技能升级整体评价

v1.3.3 → v1.5.4 的升级**总体方向正确**。核心改进（双层评估模型、保守性校准、definitive 口径）显著提高了审计的可复现性和标准化程度。22 处评分变化中，约 **14 处（64%）属于标准化改进**（A+B+C 类），**6 处（27%）归因于 LLM 探索路径差异**（D 类），**2 处为计算错误**。

### 需修复的问题

1. **计算验证**: 应在 SKILL.md 或 report-format.md 中增加「完成报告后，对每个维度的项分求和进行交叉验证」的指令，防止 LLM 汇总时的加法错误。

2. **OpenCode 2.4 评分标准**: `noUncheckedIndexedAccess: false` 是否构成降级依据需在 scoring-rubric.md 中明确。当前 rubric 对「strict mode」的定义粒度不够（是 `strict: true` 即可，还是需要每项 strict 标志都开启？）。

3. **profiles.json calibration_notes**: 引用了不可访问的校准数据，建议移除或补充实际校准报告链接。

### 值得保留的改进

1. **双层评估模型**：使 45 项评估的一致性显著提高。
2. **保守性校准规则**：解决了 CI 门禁评分的跨项目不一致。
3. **definitive 口径**：6 个项的评分完全确定性化。
4. **scoring-rubric.md 边界指导**：为 judgment 类项目提供了锚定标准。

---

*分析由 Harness Engineering Guide v1.5.4 生成，基于对同一仓库的 v1.3.3 与 v1.5.4 审计报告逐项对比。*
