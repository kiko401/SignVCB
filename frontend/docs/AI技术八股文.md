# AI 技术八股文（2026 最新版）

> 涵盖：RAG · 向量数据库 · AI Agent · 流式输出 · Embedding · Vibe Coding

---

## 目录

1. [RAG 检索增强生成](#一rag-检索增强生成)
2. [向量数据库](#二向量数据库)
3. [AI Agent](#三ai-agent)
4. [流式输出 SSE/WebSocket](#四流式输出-ssewebsocket)
5. [Embedding 与大模型基础](#五embedding-与大模型基础)
6. [Vibe Coding 与 AI 辅助编程](#六vibe-coding-与-ai-辅助编程)

---

## 一、RAG 检索增强生成

### Q1: 什么是 RAG？为什么需要它？

RAG（Retrieval-Augmented Generation）是在 LLM 推理时，从外部知识库检索相关信息注入提示，增强生成质量的技术。

**为什么需要 RAG：**
- 解决 LLM 幻觉问题（生成不准确或虚构的信息）
- 支持动态知识更新（无需重新训练）
- 提供可审计性和可引用性
- 支持私有和企业数据访问

### Q2: RAG 系统的完整架构是什么？

四个核心阶段：

1. **预处理阶段**：文档分块 → 元数据提取 → Embedding 生成 → 存入向量库
2. **检索阶段**：查询向量化 → 相似度检索 → 返回 Top-K 文档
3. **重排序阶段**：交叉编码模型精排 → 过滤不相关结果
4. **生成阶段**：检索内容 + 用户查询 → 拼接 Prompt → LLM 生成答案

### Q3: RAG 有哪些优化策略？

**Query 改写（Query Rewriting）：**
- 原始查询可能模糊，改写后更匹配知识库表达
- 假设驱动改写：先生成假设答案的关键词再检索
- 逻辑规划改写：将复杂多跳问题拆分为多个子查询

**混合检索（Hybrid Retrieval）：**
- 关键词检索（BM25）+ 语义检索（向量）融合
- 提升精度 15-30%，是企业 RAG 标准配置

**重排序（Reranking）：**
- 用交叉编码器对检索结果精细排序
- 过滤掉语义相近但实际不相关的干扰文档

**HyDE（假设文档嵌入）：**
- 让 LLM 先生成一个假设答案，用假设答案向量检索
- 适合查询与文档风格差异大的场景

### Q4: Chunking 分块策略有哪些？如何选择？

| 策略 | 原理 | 优点 | 缺点 | 适用场景 |
|------|------|------|------|---------|
| 固定大小 | 按 token 数切割 | 简单快速 | 可能割裂语义 | 大规模通用文本 |
| 句子级 | 按句子边界切割 | 保持句子完整 | 长句效果差 | 新闻、评论 |
| 递归字符 | 按段落→句子→词递归 | 效果稳定 | 计算略贵 | 通用推荐方案 |
| 语义分块 | 按 Embedding 相似度分组 | 准确率最高（+70%） | 成本高 | 知识库、技术文档 |
| 父子分块 | 小块检索 + 大块返回 | 精度与上下文兼顾 | 实现复杂 | 长文档 QA |

**推荐参数：**
- 事实导向检索：256-512 tokens
- 上下文重型任务：512-1024 tokens

### Q5: RAG 常见失败模式和解决方案？

| 失败类型 | 原因 | 解决方案 |
|---------|------|---------|
| 检索失败 | 分块不当、查询表达不匹配 | 混合检索 + Query 改写 + 改进分块 |
| 幻觉问题 | 检索质量差或 LLM 忽视检索结果 | 重排序 + 优化 Prompt + CRAG 纠正 |
| 知识冲突 | 检索结果互相矛盾 | Graph RAG + 多源验证 |
| 延迟过高 | 检索+重排+生成链路长 | 异步架构 + 结果缓存 + 批处理 |

### Q6: RAG vs Fine-tuning 如何选择？

| 维度 | RAG | Fine-tuning |
|------|-----|-------------|
| 知识更新 | 即时（无需重训） | 需要重新训练 |
| 成本 | 低（按查询计费） | 高（训练成本） |
| 可追溯性 | 高（可见源文档） | 低（黑盒） |
| 适用场景 | 动态知识、私有数据 | 风格/格式、低资源领域 |
| 延迟 | 较高（含检索） | 低（纯推理） |

**行业共识：80% 的「将我们的数据上传给 AI」问题应用 RAG 解决。**

**最佳组合：RAG（知识）+ Fine-tuning（风格）+ MCP（行动能力）**

---

## 二、向量数据库

### Q1: 向量数据库的核心原理是什么？

向量数据库存储高维向量（Embedding），通过**近似最近邻（ANN）算法**实现快速相似度检索。

**与传统数据库的本质区别：**

| 维度 | 传统数据库 | 向量数据库 |
|------|----------|----------|
| 数据形式 | 行列结构化数据 | 高维向量（数百到数千维） |
| 查询方式 | 精确匹配（`WHERE id=1`） | 相似度检索（Top-K 最近邻） |
| 索引结构 | B-Tree / Hash | HNSW / IVF / PQ |
| 事务支持 | ACID 强一致 | 最终一致性为主 |
| 适用场景 | 结构化业务数据 | 语义搜索、RAG、推荐系统 |

### Q2: 主流向量数据库对比？

| 数据库 | P99 延迟 | 成本 | 部署方式 | 适用场景 |
|--------|---------|------|---------|---------|
| Pinecone | <10ms | 较高 | 完全托管 | 生产 RAG，无运维能力 |
| Qdrant | 12-15ms | 低（比 Pinecone 省 2-3x） | 自托管/云托管 | 高性能、成本敏感 |
| Milvus | 中等 | 低 | 自托管（需 K8s） | 十亿级向量规模 |
| Weaviate | 22ms | 中等 | 自托管/云托管 | 原生混合检索 |
| ChromaDB | 低-中 | 低 | 本地/云 | 开发原型，不适合生产 |
| pgvector | 中等 | 低 | PostgreSQL 扩展 | MVP 阶段（<1000万向量） |
| FAISS | 低 | 低 | 本地库 | 研究、本地应用 |

### Q3: 向量索引算法对比（HNSW / IVF / PQ）？

**HNSW（分层可导航小世界）：**
- 原理：构建分层图结构，查询从顶层快速跳跃，O(log N) 复杂度
- 优点：95%+ 召回率、支持在线插入、是大多数向量库默认算法
- 缺点：内存占用高（约 2-5 倍原始数据）
- 适用：**默认首选，通用场景**

**IVF（倒排文件索引）：**
- 原理：K-means 聚类划分向量空间，查询只搜索相关的几个簇
- 优点：内存占用少、构建快
- 缺点：数据增长后召回率漂移，需定期重建
- 适用：内存紧张、数据有聚类特征

**PQ（乘积量化）：**
- 原理：将向量压缩成短码，大幅减少内存占用
- 优点：十亿级向量也能装进内存
- 缺点：有精度损失
- 适用：数十亿级向量、内存极受限

**选型口诀：** 默认用 HNSW → 内存紧张用 IVF → 超大规模用 IVF+PQ

### Q4: 三种相似度计算方法如何选择？

| 方法 | 特点 | 适用场景 |
|------|------|---------|
| 余弦相似度 | 只看方向，对向量长度不敏感 | **大多数 RAG 默认方案** |
| 欧氏距离 | 衡量几何距离 | 图像向量、K-means 聚类 |
| 点积 | 计算最快，可硬件加速 | 大规模检索性能优化 |

**原则：使用与模型训练方式一致的相似度方法。**

### Q5: RAG 生产架构的向量库最佳实践？

- 分离 Embedding 服务、检索服务、生成服务（三者资源特性不同）
- 使用连接池（无连接池在 512+ 并发时吞吐下降 80%）
- 部署副本到第二个可用区（故障转移从 2.3s 降至 150ms）
- 接受最终一致性，新插入向量约几秒后可搜索
- 定期重建 Embedding（模型更新时使用版本化+双库切换策略）

---

## 三、AI Agent

### Q1: 什么是 AI Agent？与普通 LLM 调用的区别？

AI Agent 是能**自主决策、循环执行、调用工具**的系统。

| 维度 | 普通 LLM 调用 | AI Agent |
|------|-------------|---------|
| 执行模式 | 单次请求-响应 | 循环推理-行动 |
| 工具使用 | 无 | 可调用外部工具/API |
| 自主性 | 被动回答 | 主动规划和执行 |
| 记忆 | 无状态 | 有短期/长期记忆 |

**核心组件：** LLM 大脑 → 规划模块 → 记忆系统 → 工具层 → 反馈循环

### Q2: ReAct 模式的原理是什么？

ReAct（Reasoning + Acting）是现代 Agent 的核心范式，由 Yao et al. 2022 提出。

**工作循环：**
```
Thought（推理）→ Action（行动）→ Observation（观察）→ Thought...
```

**优势：**
- 每次决策基于实时数据，不凭空猜测
- 错误可及时发现和纠正
- 比纯推理或纯行动效果更好

**ReAct vs Plan-Execute 对比：**
- ReAct：灵活调整，适合复杂多变任务
- Plan-Execute：先制定完整计划再执行，调用次数少、延迟低，适合已知流程

### Q3: Function Calling 机制是什么？

Function Calling（工具调用）让 LLM 生成结构化指令调用外部函数。

**流程：**
1. 开发者用 JSON Schema 定义工具
2. 工具定义 + 用户提示发给 LLM
3. LLM 决定是否调用工具，生成 JSON 格式调用请求
4. 系统执行工具，返回结果
5. LLM 基于结果继续推理

**关键特性：** 类型安全、结构化输出、多轮对话、上下文保留

### Q4: Agent 的 Memory 有哪些类型？

| 类型 | 说明 | 实现方式 |
|------|------|---------|
| 短期记忆 | 当前对话上下文 | LLM 上下文窗口 |
| 长期记忆 | 历史轨迹 | 向量数据库检索 |
| 工作记忆 | 当前任务约束和状态 | 结构化变量 |
| 程序记忆 | 可复用的任务单元 | 知识图谱/数据库 |

**Write-Manage-Read 循环：** 执行时写入 → 维护清理 → 规划时检索

### Q5: 多 Agent 协作模式有哪些？

- **任务分解**：大任务分配给不同专业 Agent 并行处理
- **聚合收敛**：多个 Agent 输出汇聚到最终答案
- **部分解交换**：Agent 间共享中间结果
- **评审-改进**：一个 Agent 生成，另一个 Agent 审查

**评估指标：** 集体成功率（CSS）、任务统一效率（TUE）、总延迟、API 成本

**生产建议：** LangGraph 做有状态编排、LlamaIndex 做 RAG 数据层、两者可混合使用

### Q6: LangChain vs LlamaIndex 怎么选？

| 维度 | LangChain | LlamaIndex |
|------|----------|-----------|
| 核心定位 | 广泛的 LLM 工作流编排 | RAG 优先的数据框架 |
| 强项 | 多步 Agent、工具调用 | 文档处理、检索准确度 |
| 适用场景 | 复杂 Agent 流程 | 高质量文档检索 |

**最佳实践：** LlamaIndex 处理文档数据层 + LangChain 负责 Agent 编排

---

## 四、流式输出 SSE/WebSocket

### Q1: SSE 的核心原理是什么？

SSE（Server-Sent Events）基于 HTTP 的服务端单向推流技术：
- 客户端用 `EventSource` API 建立长连接
- 服务端保持连接打开，持续发送数据块
- 每条消息以 `data:` 开头，`\n\n` 分隔
- **浏览器原生支持自动重连**

**消息格式：**
```
data: {"token": "hello"}\n\n
event: error\ndata: {"msg": "timeout"}\n\n
id: 42\ndata: {"token": "world"}\n\n
retry: 3000\n\n
```

### Q2: SSE vs WebSocket 如何选型？

| 特性 | SSE | WebSocket |
|------|-----|---------|
| 通信方向 | 单向（服务端→客户端） | 双向全双工 |
| 协议 | HTTP/1.1+ | 独立 WS 协议 |
| 自动重连 | 原生支持 | 需手动实现 |
| 消息类型 | 文本 | 文本/二进制 |
| 穿透性 | 好（基于 HTTP） | 需特殊配置 |
| 适用场景 | LLM 流式输出、通知推送 | 聊天、游戏、协作编辑 |

**选型原则：** 只需服务端推流选 SSE；需要双向实时通信选 WebSocket。

### Q3: 流式输出的前后端实现？

**FastAPI 后端：**
```python
from fastapi.responses import StreamingResponse

@app.get("/stream")
async def stream():
    async def generate():
        async for chunk in llm.astream(prompt):
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})
```

**React 前端：**
```javascript
useEffect(() => {
    const es = new EventSource('/api/stream');
    es.onmessage = (e) => {
        if (e.data === '[DONE]') return es.close();
        setOutput(prev => prev + JSON.parse(e.data).token);
    };
    es.onerror = () => es.close();
    return () => es.close();
}, []);
```

### Q4: 流式输出的异常处理和重连机制？

**前端策略：**
- 监听 `onerror`，触发指数退避重连（1s → 2s → 4s → ...）
- 保留已接收内容，断点续传（发送 `Last-Event-ID` 头）
- 超过最大重试次数后提示用户

**后端策略：**
- 设置全局超时（连接超时 10s + 消息间隔超时 30s）
- 通过 `event: error` 推送错误信息，不让连接无声挂死
- 监听客户端断开事件（`request.on('close')`），及时清理资源

### Q5: 背压（Backpressure）问题如何处理？

背压指生产速度 > 消费速度时缓冲区溢出的问题。

**解决策略：**
- 服务端检测 `res.write()` 返回 false 时暂停生成，等待 `drain` 事件
- 限流：控制每条消息发送间隔（如 `asyncio.sleep(0.05)`）
- 批量发送：合并多个 token 为一条消息，减少系统调用频次
- 单条消息控制在 16KB 以内

---

## 五、Embedding 与大模型基础

### Q1: 主流 Embedding 模型对比（2026）？

**闭源模型：**
| 模型 | 维度 | 特点 |
|------|------|------|
| OpenAI text-embedding-3-large | 1536 | 精度最高，适合关键应用 |
| Cohere embed-v4 | 1024 | 混合检索能力强 |
| Voyage AI v3 | 1024 | 性价比最优 |

**开源模型：**
| 模型 | 维度 | 特点 |
|------|------|------|
| BGE-M3 | 1024 | **多语言最强**（111种语言），支持混合检索 |
| Jina v5 | 1024 | 支持长文本（8K token） |
| Qwen3-Embedding | 1024 | 中文优化 |

**选型建议：**
- 精度优先 → OpenAI text-embedding-3-large
- 成本优先 → Voyage AI v3 或 BGE-M3 自建
- 多语言 → BGE-M3（必选）
- 长文本 → Jina v5

### Q2: Transformer 和 Attention 机制原理？

**Transformer 核心：** 完全基于 Attention，无循环结构，支持并行处理。

**自注意力三步：**
```
1. 生成 Q（Query）、K（Key）、V（Value）三个投影
2. 计算注意力分数：Attention(Q,K,V) = softmax(QKᵀ/√d) × V
3. 加权求和：每个 token 获得融合了全局上下文的表示
```

**直观理解：** Q = "我想要什么信息"，K = "我能提供什么"，V = "我的具体内容"

**多头注意力：** 8-12 个并行注意力头，每头学习不同关系（句法、语义、指代等）

### Q3: Token 是什么？LLM 如何处理文本？

- Token 是 LLM 最小处理单位，不等于单词（如 "tokenization" → ["token","ization"]）
- 1 个英文单词 ≈ 1.3 个 token，1 个汉字 ≈ 2-3 个 token
- **自回归生成：** 每次推理预测下一个 token，生成 N 个 token = 运行 N 次 Transformer

**解码策略：**
- 贪心：每步选概率最高的 token（快速但重复）
- Top-k：从前 k 个高概率中随机抽样
- Top-p（Nucleus）：从累计概率 p% 的 token 中抽样（最常用）

### Q4: Embedding 维度如何选择？

| 维度范围 | 性能 | 内存 | 适用场景 |
|---------|------|------|---------|
| 1024-1536 | 最高 | 大 | 知识库大（>100万文档）、精度优先 |
| 512-768 | 均衡 | 中 | 大多数 RAG 系统 |
| 128-384 | 略低（-5-15%） | 小 | 实时应用、移动端、成本敏感 |

**维度规律：** 减少维度 50%，精度通常下降 5-10%。

---

## 六、Vibe Coding 与 AI 辅助编程

### Q1: 什么是 Vibe Coding？

Vibe Coding 由 Andrej Karpathy 于 2025 年初提出，描述一种开发者通过**自然语言对话引导 AI 生成代码**的开发方式。

**工作流程：** Intent（意图）→ Spec（规范）→ Generate（生成）→ Review（审查）→ Iterate（迭代）→ Ship

**2026 年数据：** 41% 的全球代码由 AI 生成，92% 的美国开发者每天使用 AI 工具。

### Q2: Cursor vs GitHub Copilot vs Claude Code 对比？

| 工具 | 价格 | 核心优势 | 适用场景 |
|------|------|---------|---------|
| Cursor | $20/月 | 整个代码库理解、协调一致的变更 | 中大型项目重构 |
| GitHub Copilot | $10/月 | 最快的自动补全、多 IDE 支持 | 日常编码加速 |
| Claude Code | $20/月 | 最自主的 Agent、无需持续监督 | 复杂多步任务 |

**2026 年开发者最喜爱评分：** Claude Code 46% > Cursor 19% > Copilot 9%

### Q3: AI 辅助编程的 Prompt Engineering 最佳实践？

- **清晰具体：** 描述输入、输出格式、边界条件
- **提供上下文：** 说明技术栈、已有约束、相关代码
- **角色提示：** "作为一个熟悉 FastAPI 的后端工程师..."
- **思维链（CoT）：** "请先分析问题，然后给出解决方案"
- **XML 结构化：** 用标签分隔不同内容块，减少歧义

### Q4: AI 生成代码的安全风险和质量保证？

**主要风险：**
- 43% 的 AI 生成变更需要后续调试
- AI 工具容易引入安全漏洞（Stanford 研究）
- 3 个月后技术债务明显累积

**质量保证措施：**
- 集成 SAST 静态分析工具（SonarQube、Checkmarx）
- 维持严格的代码审查流程
- 使用 TDD（测试驱动开发）循环
- 关注依赖项安全（供应链攻击）
- 避免将敏感数据或密钥提交给 AI 工具

### Q5: Vibe Coding 面试考察什么？

面试不是纯编码测试，而是**产品思维测试**：
- 如何框架化问题（问题定义是否清晰）
- MVP 范围划定（能否在时间压力下做合理权衡）
- 权衡决策（选择的理由和取舍思考）
- 原型是你思维的证据，不是最终交付物

---

## 附：常见高频追问

| 问题 | 核心答案 |
|------|---------|
| RAG 效果不好怎么优化？ | 换更好的 Embedding → 混合检索 → Reranker → 改进分块 → Query 改写 |
| 向量数据库数据量大了怎么办？ | IVF 分区 → PQ 压缩 → 分布式 Milvus → 定期清理旧数据 |
| Agent 成本太高怎么控制？ | 缓存中间结果 → 简单任务用小模型 → 合理设置 token 预算 → 减少不必要工具调用 |
| SSE 和 WebSocket 怎么选？ | 单向推流选 SSE（LLM 输出场景）；双向实时交互选 WebSocket |
| Embedding 模型怎么评估？ | MTEB 榜单 + 自己业务数据集测试召回率 |

---

## 七、编写 Skill（AI 技能）

### Q1: 什么是 Skill？和 MCP、Hook 有什么区别？

Skill 是可复用的工作流指令包，遵循开放的 Agent Skills 标准。解决的核心问题：**Claude 功能强大但不记得你的偏好，每次都需要重复说明**。Skill 让你写一次指令，在所有会话中自动应用。

| 机制 | 本质 | 典型场景 |
|------|------|---------|
| **Skill** | 可复用工作流指令集 | PR 审查、部署流程、代码规范 |
| **MCP** | 连接外部工具/API 的标准协议 | 接入 GitHub、Slack、数据库 |
| **Hook** | 特定事件触发的命令 | 提交前检查、保存后格式化 |
| **CLAUDE.md** | 全局规则和身份约束 | 全局编码风格、禁止行为 |

### Q2: Skill 的文件结构是什么？

每个 Skill 是一个文件夹，核心文件是 `SKILL.md`（**大小写严格，`skill.md` 会被忽略**）：

```
.claude/skills/
└── my-skill/
    ├── SKILL.md        # 必须
    ├── scripts/        # 可选：辅助脚本
    └── templates/      # 可选：模板文件
```

`SKILL.md` 分两部分：

```markdown
---
name: code-review
description: "Perform thorough PR reviews. ALWAYS check security and performance. Never approve without tests."
triggers:
  - "when user asks to review code"
  - "when user mentions PR or pull request"
allowed-tools:
  - read
  - bash
  - grep
args:
  - name: target
    description: "File or PR to review"
    required: false
---

# Code Review Skill

Your detailed workflow instructions here...
```

### Q3: Frontmatter 各字段的作用？

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | ✓ | 唯一标识符，用于 `/name` 调用 |
| `description` | ✓ | **最关键**，决定是否自动激活 |
| `triggers` | 可选 | 显式触发条件列表 |
| `allowed-tools` | 可选 | 声明需要的工具，不声明则用默认集 |
| `args` | 可选 | 接受的参数定义 |
| `disabled` | 可选 | 设为 true 禁用该 Skill |

### Q4: 为什么 description 是最重要的字段？

基于 650+ 次实际试验的数据：

| description 类型 | 激活率 |
|----------------|--------|
| 指令型（"ALWAYS invoke when X, never do Y directly"） | **100%** |
| 标准描述型 | 仅 37% |

**高激活率 description 的写法：**
- 以动词开头（Review、Build、Deploy）
- 包含明确的负面约束（never、don't、ALWAYS）
- 控制在 1-2 句话内

```yaml
# 差
description: "Code review utility"

# 好
description: "Perform thorough PR reviews for this codebase. ALWAYS check performance, security, and test coverage. Never approve without running tests."
```

### Q5: Skill 如何被激活？有哪些调用方式？

**三种激活模式：**

1. **自动激活（推荐）**：Agent 识别任务相关性自动加载，依赖 description 质量
2. **显式调用**：用户输入 `/skill-name` 或 `Skill(skill-name, args: "value")`
3. **Hook 触发**：在 settings.json 配置事件自动调用

```json
// settings.json 配置 Hook 触发 Skill
{
  "hooks": {
    "before-commit": "Skill(code-review)",
    "after-file-save": "Skill(format-code)"
  }
}
```

### Q6: 编写 Skill 的最佳实践？

**1. 从重复工作出发**
发现自己重复相同指令时，就是写 Skill 的时机。预期时间：15-30 分钟写出第一个可用 Skill。

**2. 指令具体而不冗长**
```markdown
# 差：过于宽泛
Review the code carefully.

# 好：具体可执行
1. Check for SQL injection and XSS vulnerabilities
2. Verify all inputs are validated at system boundaries
3. Confirm test coverage > 80% for new code
4. Flag any hardcoded secrets or credentials
```

**3. 提供反面示例**
```markdown
## What NOT to do
- Never approve a PR that modifies auth logic without security review
- Don't suggest refactoring unless it's blocking the PR's goal
```

**4. 最小化 allowed-tools**
只声明真正需要的工具（5个 MCP 服务器 ≈ 50K+ tokens 额外开销）。

**5. 常见 7 个错误（100+ Skill 验证结果）**

| 错误 | 影响 | 修复 |
|------|------|------|
| description 过长或模糊 | 激活率 <40% | 1-2 句，以动词开头 |
| 无负面约束 | 激活率下降 | 加 "never"/"don't" |
| 无 triggers 字段 | 激活率下降 | 显式列出触发条件 |
| allowed-tools 声明过宽 | 频繁权限提示 | 最小化工具集 |
| 指令过于宽泛 | 执行不准确 | 提供具体步骤和示例 |
| 未测试激活 | 投入产出比低 | 用真实场景验证 |
| 无版本维护计划 | 逐渐失效 | 定期回顾更新 |

### Q7: Skill 存储在哪里？如何分发？

**存储路径：**
- 项目级：`.claude/skills/`（仅当前项目有效）
- 全局：`~/.claude/skills/`（所有项目可用）

**分发方式：**
- 提交到项目 Git 仓库（团队共享）
- 发布到 playbooks.com 公开库
- 通过 `skill-creator` 工具创建和管理

### Q8: 完整 Skill 示例

```markdown
---
name: api-endpoint
description: "Create REST API endpoints following project conventions. ALWAYS add input validation, error handling, and tests. Never skip authentication checks."
triggers:
  - "create API endpoint"
  - "add route"
  - "new controller"
allowed-tools:
  - read
  - write
  - edit
  - grep
args:
  - name: resource
    description: "Resource name (e.g. user, product)"
    required: true
---

# API Endpoint Creator

## Workflow
1. Read existing endpoints in `src/routes/` to understand conventions
2. Create route file: `src/routes/{resource}.ts`
3. Create controller: `src/controllers/{resource}Controller.ts`
4. Add input validation with Zod schema
5. Write unit tests in `src/tests/{resource}.test.ts`

## Required patterns
- All routes must use `authMiddleware`
- Input validation via Zod, validation errors return 400
- Use `asyncHandler` wrapper for all async routes
- Log errors with `logger.error()` before returning 500

## What NOT to do
- Never expose internal error details to client
- Never skip the auth middleware
- Don't use `any` type in TypeScript
```

### Q9: Skill 为什么要拆分文件夹？核心原理是什么？

**核心问题：把所有内容写进一个 md 文件 = 每次对话都加载全部内容 = token 浪费。**

举例说明：假设你有一个生成图片的 Skill，支持 A、B、C 三种风格，每种风格对应不同的 API 接口和参数：

```
❌ 全写进 SKILL.md：
- A 风格的完整请求代码
- B 风格的完整请求代码
- C 风格的完整请求代码
→ 每次对话无论用哪个风格，所有代码都被加载进上下文
```

```
✅ 拆分到 scripts/：
SKILL.md 只写："用户要 A 风格 → 执行 scripts/a-fetch.sh"
→ 对话中只在需要时才读取对应脚本
→ 上下文只包含当前任务需要的代码
```

**本质：** Skill 的 SKILL.md 是**路由层**，scripts/ 是**执行层**，两层分离实现按需加载。

### Q10: Skill 标准目录结构和各文件夹的作用？

```
my-skill/
├── SKILL.md          # 必须：路由逻辑 + 触发规则（保持精简！）
├── scripts/          # Shell/Python 脚本，按需调用
├── prompts/          # Prompt 片段，避免 SKILL.md 臃肿
├── templates/        # 生成内容时用的模板文件
├── assets/           # 静态资源（图片、图标、配置）
├── examples/         # 示例文件，展示使用方法
├── references/       # 参考资料，支撑设计
├── data/             # 配置数据、知识库
├── docs/             # API 文档、设计文档
├── tests/            # 测试文件和测试用例
├── hooks/            # 特定事件触发的钩子脚本
├── tools/            # 自定义 MCP 工具
├── workflows/        # 多步骤流程定义
└── lib/ 或 utils/    # 可复用辅助函数
```

**各文件夹使用时机：**

| 文件夹 | 何时创建 | 反例（过度设计） |
|--------|---------|----------------|
| `scripts/` | 有 2+ 个可复用脚本时 | 只有 1 个脚本直接放根目录 |
| `examples/` | 有 10+ 个示例文件时 | 2 个示例直接放根目录 |
| `prompts/` | Prompt 片段被多处复用时 | 只有 1 个 prompt |
| `assets/` | 图片/脚本/文档混在一起时 | 文件类型单一时不需要 |
| `docs/` | 团队协作、多人维护时 | 个人项目无需 |

### Q11: SKILL.md 应该写什么，不该写什么？

**应该写（路由逻辑）：**
- 触发条件和意图识别规则
- "当用户要 X → 调用 scripts/x.sh"
- 参数传递规则
- 错误处理策略

**不该写（放到对应文件夹）：**
- 完整的 API 请求代码 → `scripts/`
- 长篇的 prompt 模板 → `prompts/`
- 详细的文档说明 → `docs/`
- 示例数据 → `examples/` 或 `data/`

**判断标准：** 如果某段内容在 90% 的对话中用不到，就不该放在 SKILL.md 里。

### Q12: 过度设计 Skill 结构的常见误区？

- **空文件夹** - 没有内容的文件夹只增加认知负担
- **1-2 个文件就建文件夹** - 直接放根目录更清晰
- **把 SKILL.md 写成大而全的文档** - 本质上还是在写 prompt，失去了 Skill 的意义
- **所有子功能都写在 SKILL.md** - 正确做法是 SKILL.md 只做意图路由，具体逻辑分散到各文件

