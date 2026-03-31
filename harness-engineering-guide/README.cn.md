# Harness Engineering Guide

AI coding agent 的环境约束与反馈循环——审计、设计和实施指南。

## 什么是 Harness Engineering？

**Agent = Model + Harness.** Harness 是模型周围的一切：工具访问、上下文管理、验证、错误恢复和状态持久化。

控制论视角下，每个有效的 harness 实现四个要素：

| 要素 | 在 Harness 中 | 示例 |
|------|-------------|------|
| **Goal State** (目标状态) | 架构文档、质量标准、完成标准 | ARCHITECTURE.md, lint rules |
| **Sensor** (传感器) | 测试、linter、日志、指标、截图 | CI checks, Playwright |
| **Actuator** (执行器) | 自动修复、CI 门禁、回滚、重构 PR | pre-commit hooks, blocked PRs |
| **Feedback Loop** (反馈环) | CI 失败->修复->通过、review->lint 规则 | quality score trends |

缺少任何一个要素，系统就是 **开环** 的——无法自我纠正。

## 快速开始

对 AI agent 说以下任一句即可触发此技能：

- "Review my repo for AI coding readiness"
- "审计一下这个仓库的 harness 成熟度"
- "Set up AGENTS.md for my project"
- "Design a harness strategy for my new project"
- "为什么 AI agent 总是写出烂代码？"

## 三种模式

### Mode 1: Audit（审计）
评估仓库的 harness 成熟度，跨 8 个维度、43 项检查，输出 A-F 等级报告和改进路线图。

### Mode 2: Implement（实施）
按需实施具体 harness 组件：AGENTS.md、CI 管道、lint 规则、测试策略等。

### Mode 3: Design（设计）
按团队规模设计完整 harness 策略，分三个成熟度级别 (Solo / Small Team / Production)。

## 目录结构

```
harness-engineering-guide/
├── README.md                  ← English version
├── README.cn.md               ← 你正在读的文件（中文版）
├── SKILL.md                   ← Agent 主入口，编排三种模式
├── scripts/
│   ├── harness-audit.sh       ← Bash 审计脚本 (输出 JSON)
│   └── harness-audit.ps1      ← PowerShell 审计脚本 (Windows)
├── templates/
│   ├── agents-md-scaffold.md  ← AGENTS.md 脚手架
│   ├── doc-freshness-ci.yml   ← 文档新鲜度 CI 检查
│   ├── eslint-boundary-rule.js← 架构边界 ESLint 规则
│   ├── tech-debt-tracker.json ← 技术债务追踪器
│   ├── doc-gardening-prompt.md← 文档园丁 agent 提示
│   ├── feature-checklist.json ← 功能验证清单
│   ├── init.sh                ← 环境恢复脚本
│   └── execution-plan.md      ← 执行计划模板
├── evals/
│   └── evals.json             ← 12 个评测场景
└── references/
    ├── checklist.md           ← 8 维度 43 项审计清单
    ├── scoring-rubric.md      ← 评分方法与等级阈值
    ├── control-theory.md      ← 控制论理论基础
    ├── improvement-patterns.md← 改进模式 (Quick Wins + Strategic)
    ├── automation-templates.md← 模板索引 (指向 templates/)
    ├── agents-md-guide.md     ← AGENTS.md 编写指南
    ├── ci-cd-patterns.md      ← CI/CD 管道模式
    ├── linting-strategy.md    ← Lint 与类型检查策略
    ├── testing-patterns.md    ← 测试策略
    ├── review-practices.md    ← 代码审查实践
    ├── long-running-agents.md ← 多会话 agent 任务模式
    ├── cache-stability.md     ← 缓存稳定性与上下文管理
    ├── durable-execution.md   ← 持久化执行与崩溃恢复
    └── protocol-hygiene.md    ← 协议层卫生 (MCP/ACP/A2A)
```

## 关键引用

- **OpenAI**: 5 个月内零手写代码交付 100 万行，关键在 harness 而非模型升级
- **LangChain**: 仅改 harness（不换模型），Terminal Bench 2.0 从 52.8% 跃升至 66.5%（Top 30 -> Top 5）
- **Anthropic**: Generator-Evaluator 分离是长时运行 agent 最有效的 harness 模式

## 适用场景

- 想知道仓库是否适合 AI coding agent 使用
- 想为新项目设计 agent 友好的工程体系
- AI agent 写出的代码质量持续下降
- 想为团队建立 AGENTS.md / CI / 测试 / 审查流程
- 想理解为什么 harness 比换模型更有效
