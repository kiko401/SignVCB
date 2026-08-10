# 如何写好一个 Skill

> Skill = 路由层（SKILL.md）+ 执行层（scripts/prompts/等子目录）
> 核心原则：**按需加载，避免 token 浪费**

---

## 一、为什么要写 Skill？

直接把所有指令写进 prompt 的问题：
- 每次对话都加载全部内容，无论用不用得到
- 上下文 token 快速消耗
- 无法复用，每个项目重复编写

Skill 的优势：
- Claude 初始化时只读取 frontmatter（~100 tokens）
- 完整指令仅在触发时加载
- scripts/ 中的代码只在明确调用时执行
- 平均节省 **90%+ 的上下文开销**

---

## 二、标准目录结构

```
my-skill/
├── SKILL.md          # 必须，路由逻辑（保持精简）
├── scripts/          # Shell/Python/JS 脚本，按需调用
│   ├── hooks/        # 事件触发脚本（before-task、on-error）
│   └── core/         # 核心执行逻辑
├── prompts/          # Prompt 片段，避免 SKILL.md 臃肿
├── templates/        # 生成内容用的模板
├── references/       # 参考文档，仅在需要时加载
├── assets/           # 静态资源（图片、图标、schema）
├── examples/         # 示例文件
├── data/             # 配置数据、知识库
└── tests/            # 测试用例
```

**按需创建原则：**
- 文件 < 3 个：直接放根目录，不建文件夹
- 文件夹为空：删掉，空文件夹只增加认知负担
- 只有 1-2 个脚本：放 `scripts/` 根目录即可，不必再分 `core/`

---

## 三、SKILL.md 结构详解

```markdown
---
name: image-generator
description: "Generate images by calling style-specific APIs. ALWAYS ask user for style (A/B/C) before generating. Never call multiple APIs simultaneously."
triggers:
  - "generate image"
  - "create image"
  - "画图"
allowed-tools:
  - bash
  - read
args:
  - name: style
    description: "Image style: A (realistic), B (anime), C (abstract)"
    required: true
---

# Image Generator

## 意图路由

- 用户要 A 风格 → 执行 `scripts/fetch-a.sh`
- 用户要 B 风格 → 执行 `scripts/fetch-b.sh`
- 用户要 C 风格 → 执行 `scripts/fetch-c.sh`

## 参数说明

脚本统一接受两个参数：`$1` = prompt，`$2` = output path

## 错误处理

- 接口超时（exit code 1）→ 提示用户重试
- 参数不合法（exit code 2）→ 展示参数格式说明
```

**SKILL.md 只写路由逻辑，不写实现细节。**

---

## 四、description 字段：决定激活率的关键

基于 650+ 次实验的数据：

| description 写法 | 激活率 |
|----------------|--------|
| 指令型（动词 + 明确约束） | **100%** |
| 普通描述型 | 37% |

### 高激活率写法

```yaml
# 差 ❌
description: "Image generation utility"

# 好 ✅
description: "Generate images via style-specific APIs. ALWAYS confirm style with user first. Never call APIs without explicit style selection."
```

**公式：** `动词 + 场景 + ALWAYS/Never 约束`

### 配合 triggers 字段

```yaml
triggers:
  - "generate image"
  - "create picture"
  - "画图"
  - "生成图片"
```

description 负责模糊匹配，triggers 负责精确匹配，两者配合激活率最高。

---

## 五、scripts/ 目录：按需加载的核心

### 设计原则

把所有实现代码从 SKILL.md 移出来，SKILL.md 只保留调用路径。

```
❌ 错误做法：把 API 请求代码写进 SKILL.md
→ 每次对话都加载 A、B、C 三套接口代码

✅ 正确做法：
scripts/
├── fetch-a.sh    # A 风格 API 请求
├── fetch-b.sh    # B 风格 API 请求
└── fetch-c.sh    # C 风格 API 请求
SKILL.md 只写："用户要 A 风格 → 执行 scripts/fetch-a.sh"
```

### 脚本编写规范

```bash
#!/bin/bash
# scripts/fetch-a.sh
# 参数：$1=prompt, $2=output_path

PROMPT="$1"
OUTPUT="$2"

if [ -z "$PROMPT" ]; then
  echo "Error: prompt required" >&2
  exit 2
fi

curl -s -X POST "https://api-a.example.com/generate" \
  -H "Authorization: Bearer $API_KEY_A" \
  -d "{\"prompt\": \"$PROMPT\"}" \
  -o "$OUTPUT"
```

脚本职责单一，用 exit code 表达结果状态，不要在脚本里写业务路由逻辑。

### hooks/ 子目录

```
scripts/hooks/
├── before-task.sh    # 任务开始前：检查环境变量、依赖
├── on-error.sh       # 出错时：记录日志、通知
└── after-complete.sh # 完成后：清理临时文件
```

在 SKILL.md frontmatter 中引用：

```yaml
hooks:
  - event: before-task
    script: scripts/hooks/before-task.sh
  - event: on-error
    script: scripts/hooks/on-error.sh
```

---

## 六、prompts/ 目录：拆分复杂 Prompt

当 SKILL.md 中的 prompt 内容超过 500 tokens，应该拆出去：

```
prompts/
├── system-base.md      # 基础系统提示
├── style-a-context.md  # A 风格的完整上下文
├── style-b-context.md  # B 风格的完整上下文
└── error-recovery.md   # 错误恢复引导
```

SKILL.md 只写引用：

```markdown
## Prompt 路由
- A 风格对话 → 加载 `prompts/style-a-context.md`
- 出错时 → 加载 `prompts/error-recovery.md`
```

---

## 七、allowed-tools 最小化原则

只声明真正需要的工具：

```yaml
# 差 ❌：声明所有工具
allowed-tools:
  - read
  - write
  - edit
  - bash
  - grep
  - glob

# 好 ✅：只声明需要的
allowed-tools:
  - bash    # 执行 scripts/ 中的脚本
  - read    # 读取用户提供的文件
```

**原因：** 每多一个 MCP 工具连接约消耗 10K tokens 的上下文初始化开销。

---

## 八、完整示例：多风格图片生成 Skill

### 目录结构

```
image-generator/
├── SKILL.md
├── scripts/
│   ├── fetch-realistic.sh
│   ├── fetch-anime.sh
│   ├── fetch-abstract.sh
│   └── hooks/
│       ├── before-task.sh
│       └── on-error.sh
├── examples/
│   ├── realistic-sample.png
│   ├── anime-sample.png
│   └── abstract-sample.png
└── references/
    └── api-params.md     # 各接口参数说明，仅在调试时加载
```

### SKILL.md

```markdown
---
name: image-generator
description: "Generate images in different styles via dedicated API scripts. ALWAYS confirm style choice before calling any script. Never run multiple style scripts simultaneously."
triggers:
  - "generate image"
  - "create picture"
  - "画图"
  - "生成图片"
allowed-tools:
  - bash
  - read
args:
  - name: style
    description: "realistic | anime | abstract"
    required: true
  - name: prompt
    description: "Image description"
    required: true
hooks:
  - event: before-task
    script: scripts/hooks/before-task.sh
  - event: on-error
    script: scripts/hooks/on-error.sh
---

# 图片生成

## 风格路由

| 用户意图 | 执行脚本 |
|---------|---------|
| 写实风格 / realistic | `scripts/fetch-realistic.sh` |
| 动漫风格 / anime | `scripts/fetch-anime.sh` |
| 抽象风格 / abstract | `scripts/fetch-abstract.sh` |

## 调用方式

```bash
bash scripts/fetch-{style}.sh "{prompt}" "./output.png"
```

## 错误码

- exit 1：API 超时，提示重试
- exit 2：参数错误，展示参数格式
- exit 3：余额不足，提示充值
```

---

## 九、常见错误和避坑

| 错误 | 后果 | 正确做法 |
|------|------|---------|
| 把所有实现代码写进 SKILL.md | 每次对话加载全部，token 浪费 | 移到 scripts/，SKILL.md 只写路由 |
| description 过于宽泛 | 激活率低至 37% | 动词 + ALWAYS/Never 约束 |
| 创建空文件夹 | 增加认知负担 | 有内容再建 |
| allowed-tools 声明过多 | 上下文初始化开销大 | 最小化原则 |
| 一个 Skill 做太多事 | 路由逻辑复杂，难维护 | 单一职责，拆成多个 Skill |
| 在脚本里写业务路由 | 职责混乱 | 路由在 SKILL.md，执行在 scripts/ |

---

## 十、Skill 开发流程

```
1. 发现重复  →  注意自己在重复输入哪些指令
2. 提取路由  →  把意图判断逻辑写进 SKILL.md
3. 拆分执行  →  把具体实现移到 scripts/prompts/
4. 写 description  →  动词 + 约束，测试激活率
5. 添加 triggers  →  精确触发词列表
6. 最小化工具  →  删除用不到的 allowed-tools
7. 测试验证  →  用真实场景验证自动激活
8. 迭代优化  →  根据实际使用调整
```

预期时间：第一个可工作的 Skill 约 **15-30 分钟**。

---

## 参考资源

- [The SKILL.md Pattern: How to Write AI Agent Skills That Actually Work](https://bibek-poudel.medium.com/the-skill-md-pattern-how-to-write-ai-agent-skills-that-actually-work-72a3169dd7ee)
- [Claude Code Skills Architecture: Progressive Context Loading](https://www.mindstudio.ai/blog/claude-code-skills-architecture-progressive-context-loading/)
- [How to Make Claude Code Skills Actually Activate (650 Trials)](https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1)
- [The 98% Token Savings Architecture](https://igniteaisolutions.substack.com/p/claude-skills-the-98-token-savings)
- [Kiro CLI Skills Documentation](https://kiro.dev/docs/cli/skills/)

---

## 十一、Description 激活率优化（进阶）

### 三种 description 模式的激活率

| 模式 | 激活率 | 示例 |
|------|--------|------|
| 指令型（ALWAYS/Never） | **100%** | "ALWAYS invoke when user mentions X. Never do Y directly." |
| 强制评估机制 | 84% | 配合 hooks 使用 |
| 普通描述型 | 37% | "Helps with data processing" |

### description 必须回答三个问题

1. **What** — 这个 Skill 做什么
2. **When** — 什么情况下触发
3. **Trigger terms** — 具体关键词（至少 5 个）

### 四种高激活率写法模板

```yaml
# 模板 1：关键词列举
description: >
  Use when user mentions: dashboards, data visualization,
  charts, metrics, reports — even if they don't explicitly
  ask for a dashboard.

# 模板 2：文件类型触发
description: >
  Triggers include: any mention of '.docx', 'Word doc',
  or requests for documents with tables of contents,
  headings, page numbers, or letterheads.

# 模板 3：负面约束（最高激活率）
description: >
  ALWAYS invoke when handling [X].
  Do NOT attempt [Y] directly without this skill.

# 模板 4：场景 + 边界
description: >
  Use for PDF operations: reading, merging, splitting, OCR.
  Do NOT use for plain text files or Word documents.
```

### description 字数控制

- 高频简单 Skill：< 200 字
- 标准 Skill：< 500 字
- 上限：< 800 字（超过则 Claude 容易跳过）

---

## 十二、Skill 开发完整清单

**写之前：**
- [ ] 定义 3-5 个明确触发条件
- [ ] 列出具体关键词
- [ ] 明确和其他 Skill 的边界
- [ ] 确定哪些内容需要拆到子目录

**写 description：**
- [ ] 包含 What + When + Trigger terms
- [ ] 字数 < 500
- [ ] 包含 ALWAYS 或 Never 约束

**写 SKILL.md 正文：**
- [ ] 步骤清晰可执行
- [ ] 有"注意事项"（常见坑）
- [ ] 500+ 字的规则移到 `references/`
- [ ] 脚本代码移到 `scripts/`

**测试：**
- [ ] 用 10+ 真实请求验证自动激活
- [ ] 验证 scripts/ 脚本独立可执行
- [ ] 确认 allowed-tools 最小化
