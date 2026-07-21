# 数据契约文档 v3.3

> **说明**：本文档定义后端(Python/Pydantic)、前端(Dart)、算法(Pydantic)三方共用的强类型模型。

---

## 一、共享枚举

### AlignmentOpType
```python
from enum import Enum

class AlignmentOpType(str, Enum):
    POSTPONE = "postpone"   # 后移
    ADVANCE = "advance"     # 前移
    DELETE = "delete"       # 删除
    INSERT = "insert"       # 插入
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

### Pydantic 定义
```python
from pydantic import BaseModel, field_validator
from typing import Optional

class AlignmentOp(BaseModel):
    type: AlignmentOpType
    word: str
    target: Optional[str] = None
    position: Optional[int] = None

    @field_validator('type', mode='before')
    @classmethod
    def validate_type(cls, v):
        if isinstance(v, str):
            if v.lower() not in ['postpone', 'advance', 'delete', 'insert']:
                raise ValueError(f'Invalid alignment type: {v}')
            return v.lower()
        return v
```

### JSON 结构
```json
{
  "type": "postpone|advance|delete|insert",
  "word": "词",
  "target": "目标词|null",
  "position": 2
}
```

### 字段约束
| 字段 | 类型 | 约束 |
|---|---|---|
| type | string | 必填，可选值: postpone/advance/delete/insert |
| word | string | 必填，操作的词 |
| target | string/null | postpone/advance 时必填 |
| position | int/null | insert 时必填 |

---

## 三、PreheatData（预热数据）

### Pydantic 定义
```python
from pydantic import BaseModel

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
from pydantic import BaseModel

class FirstPassData(BaseModel):
    text: str          # 分词后的 CSL 文本，如 "我 吃 苹果"
    oov_status: bool   # 是否包含 OOV 词
```

### JSON 结构
```json
{
  "text": "我 吃 苹果",
  "oov_status": false
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| text | string | 空格分词的 CSL 文本 |
| oov_status | bool | 是否检测到 OOV 词 |

---

## 五、RefinedPassData（精炼数据）

### Pydantic 定义
```python
from pydantic import BaseModel
from typing import Optional

class RefinedPassData(BaseModel):
    text: str                                    # 精炼后的 CSL 文本
    oov_map: dict[str, str]                      # OOV 降级映射 {原词: 降级词}
    nmm_hints: dict[str, str]                    # NMM 标识 {词索引: NEGATION|QUESTION|PAUSE}
    alignment_ops: list[AlignmentOp]             # 对齐操作列表
```

### JSON 结构
```json
{
  "text": "我 吃 苹果",
  "oov_map": {"量子": "东西"},
  "nmm_hints": {"2": "QUESTION"},
  "alignment_ops": [
    {"type": "postpone", "word": "吃", "target": "苹果"}
  ]
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| text | string | LLM 精炼后的 CSL 文本 |
| oov_map | dict | OOV 词降级映射，key=原词，value=降级词 |
| nmm_hints | dict | NMM 标识，key=词索引，value=枚举值 |
| alignment_ops | list[AlignmentOp] | 词序调整操作列表 |

---

## 六、FallbackData（降级数据）

### Pydantic 定义
```python
from pydantic import BaseModel

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
| fallback_text | string | 超时/异常时的兜底文案 |

---

## 七、AppConfigResponse（应用配置）

### Pydantic 定义
```python
from pydantic import BaseModel

class AppConfigResponse(BaseModel):
    enable_stream_masking: bool    # OOV 词卡脉冲动画开关
    show_oov_map: bool             # 下发 refined_pass.oov_map
    show_nmm_hints: bool           # 下发 refined_pass.nmm_hints
    sse_timeout_ms: int            # SSE 超时毫秒数
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

### 字段说明
| 字段 | 类型 | 说明 |
|---|---|---|
| enable_stream_masking | bool | OOV 词卡是否加脉冲动画 |
| show_oov_map | bool | 是否渲染 oov_map 降级词 |
| show_nmm_hints | bool | 是否渲染 nmm_hints 表情 |
| sse_timeout_ms | int | SSE 超时时间（毫秒） |

---

## 八、PracticeQuestionResponse（练习题响应）

### Pydantic 定义
```python
from pydantic import BaseModel
from typing import Optional

class PracticeQuestionResponse(BaseModel):
    id: int
    level: str                      # L1|L2|L3
    type: str                       # word_match|sentence_order|sign_recognize
    mode: Optional[str] = None      # image|text|null，仅 word_match 有
    image_urls: list[str] = []      # 图片 URL 列表
    text: Optional[str] = None      # 文字题目
    choices: list[str] = []         # 选项列表
    scrambled: list[str] = []       # 乱序列表，仅 sentence_order 有
    target_text: Optional[str] = None  # 目标文本，仅 sign_recognize 有
```

### JSON 结构
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
| word_match | image/text | 有图片时填充 | 文字题目 | 4个选项 | [] | null |
| sentence_order | null | [] | null | [] | 有 | null |
| sign_recognize | null | [] | null | 3个选项 | [] | 有 |

---

## 九、TtsRequest / TtsResponse

### TtsRequest
```python
from pydantic import BaseModel, Field

class TtsRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=200)
    speed: float = Field(1.0, ge=0.5, le=2.0)
```

### TtsResponse
```python
from pydantic import BaseModel

class TtsResponse(BaseModel):
    audio_url: str  # 绝对路径，如 http://server:8081/tts_audio/xxx.mp3
```

### JSON 结构
```json
{
  "audio_url": "http://localhost:8081/tts_audio/abc123.mp3"
}
```

---

## 十、NormalizeOptionsRequest / Response

### NormalizeOptionsRequest
```python
from pydantic import BaseModel, Field

class NormalizeOptionsRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    context: str = None
    num_options: int = Field(3, ge=1, le=5)
```

### NormalizeOptionsResponse
```python
from pydantic import BaseModel

class NormalizeOptionsResponse(BaseModel):
    options: list[str]
```

### JSON 结构
```json
{
  "options": ["我吃苹果", "我吃个苹果", "苹果我吃"]
}
```

---

## 十一、Auth 相关模型

### RegisterRequest
```python
from pydantic import BaseModel
from typing import Literal

class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)
    age_group: Literal["L1", "L2", "L3"]
    nickname: str = None
```

### LoginRequest
```python
from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str
```

### TokenResponse
```python
from pydantic import BaseModel

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
```

### UserResponse
```python
from pydantic import BaseModel
from typing import Optional

class UserResponse(BaseModel):
    id: int
    username: str
    age_group: str
    nickname: Optional[str]
    avatar_url: Optional[str]
```

---

## 十二、Reading 相关模型

### ReadingBookResponse
```python
from pydantic import BaseModel
from typing import Optional

class ReadingBookResponse(BaseModel):
    id: int
    title: str
    age_group: str
    cover_url: Optional[str]
    difficulty: int
```

### ReadingSentenceResponse
```python
from pydantic import BaseModel
from typing import List, Optional

class ReadingSentenceResponse(BaseModel):
    index: int
    original: str
    sign_text: str
    alignment_ops: List[AlignmentOp] = []
```

### ReadingContentResponse
```python
from pydantic import BaseModel
from typing import List

class ReadingContentResponse(BaseModel):
    book_id: int
    sentences: List[ReadingSentenceResponse]
```

---

## 十三、Practice Validate 相关模型

### PracticeValidateRequest
```python
from pydantic import BaseModel
from typing import Union, List

class PracticeValidateRequest(BaseModel):
    question_id: int
    answer: Union[List[str], str]  # L1/L2 传数组，L3 传字符串
```

### PracticeValidateResponse
```python
from pydantic import BaseModel

class PracticeValidateResponse(BaseModel):
    correct: bool
    feedback: str
```

---

## 十四、LogMismatch 相关模型

### LogMismatchRequest
```python
from pydantic import BaseModel, Field
from typing import List, Optional

class LogMismatchRequest(BaseModel):
    original_text: str = Field(..., min_length=1, max_length=1000)
    failed_options: List[str] = Field(..., min_length=1)
    context: Optional[str] = None
```

### LogMismatchResponse
```python
from pydantic import BaseModel

class LogMismatchResponse(BaseModel):
    status: str = "ok"
```

---

## 十五、三端模型映射表

| 模型名 | 后端 (Pydantic) | 前端 (Dart) | 算法 (Pydantic) |
|---|---|---|---|
| AlignmentOpType | `AlignmentOpType` | `AlignmentOpType` | `AlignmentOpType` |
| AlignmentOp | `AlignmentOp` | `AlignmentOp` | `AlignmentOp` |
| PreheatData | `PreheatData` | `PreheatData` | `PreheatData` |
| FirstPassData | `FirstPassData` | `FirstPassData` | `FirstPassData` |
| RefinedPassData | `RefinedPassData` | `RefinedPassData` | `RefinedPassData` |
| FallbackData | `FallbackData` | `FallbackData` | `FallbackData` |
| AppConfigResponse | `AppConfigResponse` | `AppConfig` | - |
| PracticeQuestionResponse | `PracticeQuestionResponse` | `PracticeQuestion` | - |

> **注意**：前端 Dart 模型字段名使用 camelCase，后端 Python 使用 snake_case，JSON 传输时使用 snake_case。
