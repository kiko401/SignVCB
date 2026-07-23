# 数据契约文档 v3.4

> **说明**：本文档定义后端(Python/Pydantic)、前端(Dart)、算法(Python/Pydantic)三方共用的强类型模型。

---

## 一、共享枚举

### AlignmentOpType
```python
from enum import Enum

class AlignmentOpType(str, Enum):
    POSTPONE = "postpone"   # 后移
    ADVANCE = "advance"      # 前移
    DELETE = "delete"        # 删除
    INSERT = "insert"        # 插入
```

### NMMHintType
```python
class NMMHintType(str, Enum):
    NEGATION = "NEGATION"    # 否定
    QUESTION = "QUESTION"    # 疑问
    PAUSE = "PAUSE"          # 停顿
```

---

## 二、AlignmentOp（对齐操作）

### Pydantic 定义（Engine & Backend 共用）
```python
from pydantic import BaseModel, field_validator
from typing import Optional

class AlignmentOp(BaseModel):
    type: AlignmentOpType
    word: str                          # 被操作的目标词
    target: Optional[str] = None       # POSTPONE 时：目标位置对应的词（即 refined 中该位置原有的词）
    position: Optional[int] = None    # 操作发生位置的词索引（DELETE/INSERT 时为被操作词索引；POSTPONE 时为被移动词在原始序列中的索引）
    source: Optional[int] = None       # POSTPONE 时：被移动词在原始（first_pass）序列中的索引

    @field_validator('type', mode='before')
    @classmethod
    def validate_type(cls, v):
        if isinstance(v, str):
            return v.lower()
        return v
```

### JSON 结构
```json
{
  "type": "postpone",
  "word": "吃",
  "target": "苹果",
  "position": 1,
  "source": 2
}
```

### 字段约束
| 字段 | 类型 | 约束 |
|---|---|---|
| type | string | 必填，可选值: postpone/advance/delete/insert |
| word | string | 必填，被操作的词 |
| target | string/null | POSTPONE/ADVANCE 时有，DELETE/INSERT 时为 null |
| position | int/null | DELETE/INSERT 时必填；POSTPONE 时为被移动词在原始序列中的索引 |
| source | int/null | 仅 POSTPONE 时有，表示被移动词在原始序列中的位置（与 position 相等，语义不同） |

---

## 三、PreheatData（预热数据）

### Pydantic 定义
```python
class PreheatData(BaseModel):
    original: str
```

### JSON 结构
```json
{
  "original": "我吃苹果"
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| original | string | 用户输入的原始文本 |

---

## 四、FirstPassData（首轮分词数据）

### Pydantic 定义
```python
class FirstPassData(BaseModel):
    text: str          # 分词后的 CSL 文本，如 "我 吃 苹果"
    oov_status: bool  # 是否包含 OOV 词
```

### JSON 结构
```json
{
  "text": "我 吃 苹果",
  "oov_status": false
}
```

---

## 五、RefinedPassData（精炼数据）

### Pydantic 定义
```python
class RefinedPassData(BaseModel):
    text: str                      # 精炼后的 CSL 文本
    oov_map: dict[str, str]       # OOV 降级映射 {原词: 降级词}
    nmm_hints: dict[str, str]     # NMM 标识 {词索引字符串: NEGATION|QUESTION|PAUSE}
    alignment_ops: list           # 对齐操作列表
```

### JSON 结构
```json
{
  "text": "我 吃 苹果",
  "oov_map": {"量子": "东西"},
  "nmm_hints": {"3": "NEGATION"},
  "alignment_ops": [
    {"type": "postpone", "word": "吃", "target": "苹果", "position": 1, "source": 2}
  ]
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| text | string | LLM 精炼后的 CSL 文本 |
| oov_map | dict | OOV 词降级映射，key=原词，value=降级词；无 OOV 时为空 `{}` |
| nmm_hints | dict | NMM 标识；key 为词在 CSL 序列中的**字符串索引**（如 `"3"`），value 为枚举字符串；无标记时为空 `{}` |
| alignment_ops | list[AlignmentOp] | 词序调整操作列表；无需调整时为空 `[]` |

---

## 六、FallbackData（降级数据）

### Pydantic 定义
```python
class FallbackData(BaseModel):
    fallback_text: str
```

### JSON 结构
```json
{
  "fallback_text": "网络有点慢哦，再试一次？"
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| fallback_text | string | 超时/异常时的兜底文案（内容为 first_pass 分词结果） |

---

## 七、AppConfigResponse（应用配置）

### Pydantic 定义
```python
class AppConfigResponse(BaseModel):
    enable_stream_masking: bool    # OOV 词卡脉冲动画开关
    show_oov_map: bool             # 是否渲染 refined_pass.oov_map
    show_nmm_hints: bool           # 是否渲染 refined_pass.nmm_hints
    sse_timeout_ms: int           # SSE 超时毫秒数
```

### JSON 结构
```json
{
  "enable_stream_masking": true,
  "show_oov_map": true,
  "show_nmm_hints": true,
  "sse_timeout_ms": 10000
}
```

---

## 八、PracticeQuestionResponse（练习题响应）

### Pydantic 定义
```python
class PracticeQuestionResponse(BaseModel):
    id: int
    level: str                      # L1|L2|L3
    type: str                       # word_match|sentence_order|sign_recognize
    mode: str | None = None         # image|text|null；仅 word_match 有
    image_urls: list[str] = []
    text: str | None = None
    choices: list[str] = []
    scrambled: list[str] = []       # 仅 sentence_order 有
    target_text: str | None = None  # 仅 sign_recognize 有
```

### JSON 示例（word_match）
```json
{
  "id": 1,
  "level": "L1",
  "type": "word_match",
  "mode": "image",
  "image_urls": ["https://cdn.example.com/wordcards/apple.png"],
  "text": null,
  "choices": ["苹果", "香蕉", "葡萄", "西瓜"],
  "scrambled": [],
  "target_text": null
}
```

### 不同 type 的字段填充规则
| type | mode | image_urls | text | choices | scrambled | target_text |
|---|---|---|---|---|---|---|
| word_match | image/text | 有图片时填充 | 可选 | 4个选项 | [] | null |
| sentence_order | null | [] | null | [] | 有 | null |
| sign_recognize | null | [] | null | 3个选项 | [] | 有 |

---

## 九、TtsRequest / TtsResponse

### TtsRequest
```python
class TtsRequest(BaseModel):
    text: str       # 合成的文本
    speed: float = 1.0  # 语速，默认 1.0
```

### TtsResponse
```python
class TtsResponse(BaseModel):
    audio_url: str  # 绝对路径，如 http://server:8081/tts_audio/xxx.wav
```

### JSON
```json
{
  "audio_url": "http://localhost:8081/tts_audio/abc123.wav"
}
```

---

## 十、NormalizeOptionsRequest / Response

### NormalizeOptionsRequest
```python
class NormalizeOptionsRequest(BaseModel):
    text: str          # CSL 文本
    num_options: int = 3  # 候选数量，默认 3
```

> 注意：**无 `context` 字段**。

### NormalizeOptionsResponse
```python
class NormalizeOptionsResponse(BaseModel):
    options: list[str]
```

### JSON
```json
{
  "options": ["我吃苹果", "我吃个苹果", "苹果我吃"]
}
```

---

## 十一、Auth 相关模型

### RegisterRequest
```python
class RegisterRequest(BaseModel):
    username: str
    password: str
    age_group: str      # "L1"|"L2"|"L3"
    nickname: str | None = None
```

### LoginRequest
```python
class LoginRequest(BaseModel):
    username: str
    password: str
```

### TokenResponse
```python
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"
```

### UserResponse
```python
class UserResponse(BaseModel):
    id: int
    username: str
    age_group: str
    nickname: str | None
    avatar_url: str | None
```

---

## 十二、Reading 相关模型

### ReadingBookResponse
```python
class ReadingBookResponse(BaseModel):
    id: int
    title: str
    age_group: str          # "L1"|"L2"|"L3"
    cover_url: str | None
    difficulty: int
```

### ReadingSentenceResponse
```python
class ReadingSentenceResponse(BaseModel):
    index: int
    original: str
    sign_text: str
    alignment_ops: list[AlignmentOp] = []
```

### ReadingContentResponse
```python
class ReadingContentResponse(BaseModel):
    book_id: int
    sentences: list[ReadingSentenceResponse]
```

---

## 十三、Practice Validate 相关模型

### PracticeValidateRequest
```python
class PracticeValidateRequest(BaseModel):
    question_id: int
    answer: list[str] | str  # L1/L2 传有序数组；L3 传字符串
```

### PracticeValidateResponse
```python
class PracticeValidateResponse(BaseModel):
    correct: bool
    feedback: str
```

---

## 十四、LogMismatch 相关模型

### LogMismatchRequest
```python
class LogMismatchRequest(BaseModel):
    original_text: str
    failed_options: list[str]
    context: str | None = None
```

### LogMismatchResponse
```python
class LogMismatchResponse(BaseModel):
    status: str = "ok"
```

---

## 十五、SuggestionItem（建议回复项）

### SuggestionItem
```python
class SuggestionItem(BaseModel):
    text: str            # 建议回复文本
    reason: str | None = None  # 理由（当前固定为空字符串）
```

### SuggestReplyResponse
```python
class SuggestReplyResponse(BaseModel):
    suggestions: list[SuggestionItem]
```

---

## 十六、三端模型映射表

| 模型名 | 后端 (Pydantic) | 前端 (Dart) | 算法 (Pydantic) |
|---|---|---|---|
| AlignmentOpType | `AlignmentOpType` | `AlignmentOpType` | `AlignmentOpType` |
| AlignmentOp | `AlignmentOp` (含 source) | `AlignmentOp` | `AlignmentOp` (含 source) |
| PreheatData | `PreheatData` | `PreheatData` | `PreheatData` |
| FirstPassData | `FirstPassData` | `FirstPassData` | `FirstPassData` |
| RefinedPassData | `RefinedPassData` | `RefinedPassData` | `RefinedPassData` |
| FallbackData | `FallbackData` | `FallbackData` | `FallbackData` |
| AppConfigResponse | `AppConfigResponse` | `AppConfig` | - |
| PracticeQuestionResponse | `PracticeQuestionResponse` | `PracticeQuestion` | - |
| SuggestionItem | `SuggestionItem` | - | - |

> **注意**：前端 Dart 模型字段名使用 camelCase，后端 Python 使用 snake_case，JSON 传输时使用 snake_case。
