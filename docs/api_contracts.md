# API 契约文档 v3.4

> **红线规则**：
> 1. `/api/v1/auth/register` 和 `/api/v1/auth/login` 为唯一公开接口，其他接口**必须**在请求头携带 `Authorization: Bearer <token>`
> 2. `/api/v1/app_config` 是**匿名公共接口**，严禁依赖 JWT
> 3. `first_pass` 事件**始终**由算法 yield、后端透传、前端按 `ENABLE_STREAM_MASKING` 决定是否加脉冲动画
> 4. `refined_pass.oov_map` 严格 `{原词: 降级词}` 格式
> 5. `refined_pass.nmm_hints` 值为字符串枚举 `NEGATION/QUESTION/PAUSE`，key 为词在 CSL 序列中的字符串索引
> 6. `refined_pass.alignment_ops` 元素严格 `{type, word, target?, position?, source?}`，其中 `source` 仅 POSTPONE 操作有
> 7. `/api/v1/tts` 返回的 `audio_url` 必须是**绝对路径**
> 8. `/api/v1/practice/validate` 接受 `answer`，L1/L2 传有序数组、L3 传纯文本
> 9. `/api/v1/log_mismatch` 接收 `{original_text, failed_options: List[str], context?}`
> 10. SSE 流正常结束时引擎发送 `done` 事件；发生未捕获异常时发送 `error` 事件

---

## 一、对外 HTTP 接口（14个）

### 1.1 认证接口

#### POST /api/v1/auth/register
**鉴权**：否（公开）
**限流**：5/minute

**请求**：
```json
{
  "username": "string",
  "password": "string",
  "age_group": "L1|L2|L3",
  "nickname": "string|null"
}
```

**响应 200**：
```json
{
  "access_token": "string",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "string",
    "age_group": "L1",
    "nickname": "string|null",
    "avatar_url": "string|null"
  }
}
```

---

#### POST /api/v1/auth/login
**鉴权**：否（公开）
**限流**：5/minute

**请求**：
```json
{
  "username": "string",
  "password": "string"
}
```

**响应 200**：
```json
{
  "access_token": "string",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "string",
    "age_group": "L1",
    "nickname": "string|null",
    "avatar_url": "string|null"
  }
}
```

---

### 1.2 聊天接口

#### POST /api/v1/chat/asr_and_rewrite
**鉴权**：是
**限流**：15/minute
**返回**：SSE 流

**请求**：multipart/form-data
- `file`: 音频文件 (WAV/16k/16bit/单声道)
- `context`: string|null

**SSE 事件流**：
```
event: preheat
data: {"original": ""}

event: preheat
data: {"original": "识别出的文字"}

event: first_pass
data: {"text": "string", "oov_status": boolean}

event: refined_pass
data: {
  "text": "string",
  "oov_map": {"原词": "降级词"},
  "nmm_hints": {"词索引": "NEGATION|QUESTION|PAUSE"},
  "alignment_ops": [
    {"type": "postpone|advance|delete|insert", "word": "string", "target": "string|null", "position": number|null, "source": number|null}
  ]
}

event: done
data: {}
```

> 注意：ASR 识别前有一个 `preheat`（original为空），识别后有第二个 `preheat`（original为识别结果）。

---

#### POST /api/v1/chat/rewrite
**鉴权**：是
**限流**：30/minute
**返回**：SSE 流

**请求**：
```json
{
  "text": "string",
  "context": "string|null"
}
```

**SSE 事件流**：同 asr_and_rewrite（无 ASR 阶段，直接一个 preheat）

---

#### POST /api/v1/chat/tts
**鉴权**：是
**限流**：30/minute

**请求**：
```json
{
  "text": "string",
  "speed": 1.0
}
```

**响应 200**：
```json
{
  "audio_url": "http://<SERVER_PUBLIC_HOST>/tts_audio/xxx.wav"
}
```

---

#### POST /api/v1/chat/suggest_reply
**鉴权**：是
**限流**：30/minute

**请求**：
```json
{
  "text": "string",
  "context": "string|null"
}
```

**响应 200**：
```json
{
  "suggestions": [
    {"text": "候选1", "reason": ""},
    {"text": "候选2", "reason": ""},
    {"text": "候选3", "reason": ""}
  ]
}
```

---

#### POST /api/v1/chat/normalize_options
**鉴权**：是
**限流**：30/minute

**请求**：
```json
{
  "text": "CSL文本，如 苹果 我 吃",
  "num_options": 3
}
```

> 注意：请求体中无 `context` 字段。

**响应 200**：
```json
{
  "options": ["归一化候选1", "归一化候选2", "归一化候选3"]
}
```

---

#### POST /api/v1/chat/log_mismatch
**鉴权**：是
**限流**：30/minute

**请求**：
```json
{
  "original_text": "string",
  "failed_options": ["string"],
  "context": "string|null"
}
```

**响应 200**：
```json
{
  "status": "ok"
}
```

---

### 1.3 读物接口

#### GET /api/v1/reading/books
**鉴权**：是
**限流**：60/minute

**查询参数**：`age_group` (可选: L1|L2|L3)

**响应 200**：
```json
[
  {
    "id": 1,
    "title": "string",
    "age_group": "L1",
    "cover_url": "string|null",
    "difficulty": 1
  }
]
```

---

#### GET /api/v1/reading/books/{book_id}/content
**鉴权**：是
**限流**：60/minute

**路径参数**：`book_id` (必填，int)

**响应 200**：
```json
{
  "book_id": 1,
  "sentences": [
    {
      "index": 0,
      "original": "原文",
      "sign_text": "手语文本",
      "alignment_ops": [
        {"type": "postpone", "word": "吃", "target": "苹果", "position": 2, "source": 1}
      ]
    }
  ]
}
```

---

### 1.4 练习接口

#### GET /api/v1/practice/question
**鉴权**：是
**限流**：30/minute

**查询参数**：
- `level`: L1|L2|L3 (必填)
- `type`: word_match|sentence_order|sign_recognize (必填)

**响应 200**：
```json
{
  "id": 1,
  "level": "L1",
  "type": "word_match",
  "mode": "image|text|null",
  "image_urls": ["string"],
  "text": "string|null",
  "choices": ["string"],
  "scrambled": ["string"],
  "target_text": "string|null"
}
```

**不同 type 的字段填充规则**：
| type | mode | image_urls | text | choices | scrambled | target_text |
|---|---|---|---|---|---|---|
| word_match | image/text | 有图片时填充 | 可选 | 4个选项 | [] | null |
| sentence_order | null | [] | null | [] | 有 | null |
| sign_recognize | null | [] | null | 3个选项 | [] | 有 |

---

#### POST /api/v1/practice/validate
**鉴权**：是
**限流**：30/minute

**请求 L1/L2**：
```json
{
  "question_id": 1,
  "answer": ["词1", "词2"]
}
```

**请求 L3**：
```json
{
  "question_id": 2,
  "answer": "完整句子"
}
```

**响应 200**：
```json
{
  "correct": true,
  "feedback": "答对了！真棒！"
}
```

---

### 1.5 配置接口

#### GET /api/v1/app_config
**鉴权**：否（匿名）
**限流**：60/minute

**响应 200**：
```json
{
  "enable_stream_masking": true,
  "show_oov_map": true,
  "show_nmm_hints": true,
  "sse_timeout_ms": 10000
}
```

---

### 1.6 健康检查

#### GET /health（Backend）
**鉴权**：否
**网络**：外部可访问

**响应 200**：
```json
{
  "status": "healthy|degraded",
  "dependencies": {
    "mysql": "ok|error",
    "redis": "ok|error",
    "engine": "ok|error"
  }
}
```

---

## 二、内部 HTTP 接口（4个）

> **注意**：这些接口只能通过 Docker 内部网络访问，前端无法直接调用。

### 2.1 POST /internal/rewrite
**网络隔离**：仅 signvcb-server → signvcb-engine
**鉴权**：网络隔离，无 JWT

**请求**：
```json
{
  "text": "string",
  "context": "string|null"
}
```

**响应**：SSE 流（同 /chat/rewrite）

---

### 2.2 POST /internal/normalize
**网络隔离**：仅 signvcb-server → signvcb-engine
**鉴权**：网络隔离

**请求**：
```json
{
  "text": "CSL文本",
  "num_options": 3
}
```

> 注意：请求体中无 `context` 字段。

**响应**：
```json
{
  "options": ["string"]
}
```

---

### 2.3 GET /internal/dynamic_fallback
**网络隔离**：仅 signvcb-server → signvcb-engine
**鉴权**：网络隔离

**响应**：
```json
{
  "items": [
    {"oov": "原词", "fallback": "降级词"}
  ],
  "server_time": "2026-07-20T12:00:00Z",
  "count": 1
}
```

---

### 2.4 GET /health（Engine）
**网络**：无限制（外部可访问）
**鉴权**：无

**响应**：
```json
{
  "status": "healthy|degraded",
  "dependencies": {
    "onnx": "ok|error",
    "faiss": "ok|error",
    "llm": "ok|error",
    "rewrite_pipeline": "ok|error",
    "normalize_pipeline": "ok|error",
    "dynamic_dict": "ok|not_loaded"
  }
}
```

> `status` 说明：
> - `healthy`：ONNX + FAISS 均可用，核心功能完整
> - `degraded`：ONNX 或 FAISS 不可用，向量检索等部分功能受限

---

## 三、SSE 事件契约（6个事件）

### 3.1 preheat
**触发时机**：每次 rewrite 请求开始时
**data 字段**：
```json
{
  "original": "用户输入原文"
}
```

### 3.2 first_pass
**触发时机**：算法 Step 1 分词完成后（始终触发）
**data 字段**：
```json
{
  "text": "分词后的CSL文本(空格分隔)",
  "oov_status": true|false
}
```

### 3.3 refined_pass
**触发时机**：算法 LLM 精炼完成后（正常流程）
**data 字段**：
```json
{
  "text": "精炼后的CSL文本",
  "oov_map": {"原词": "降级词"},
  "nmm_hints": {"词索引字符串": "NEGATION|QUESTION|PAUSE"},
  "alignment_ops": [
    {
      "type": "postpone|advance|delete|insert",
      "word": "string",
      "target": "string|null",
      "position": "number|null",
      "source": "number|null"
    }
  ]
}
```

> - `nmm_hints`：key 为词在 CSL 序列中的**字符串索引**（如 `"3"`），value 为枚举字符串
> - `position`：词在原始（first_pass）序列中的索引位置。DELETE/INSERT 时表示被操作词的位置；POSTPONE 时表示被移动的词在原始序列中的位置。
> - `source`：仅 POSTPONE 操作有，表示被移动的词在原始（first_pass）序列中的索引位置（与 `position` 相等但语义不同，用于前端还原移动路径）。
> - `target`：仅 POSTPONE 操作有，表示目标位置对应的词（即 refined 中该位置原有的词）。

### 3.4 fallback
**触发时机**：LLM 精炼失败或超时时
**data 字段**：
```json
{
  "fallback_text": "兜底文案"
}
```
> 此时返回 `first_pass`（分词后文本）作为兜底，客户端应展示此文案并停止等待后续事件。

### 3.5 error
**触发时机**：rewrite 流水线内部发生未捕获异常时
**data 字段**：
```json
{
  "message": "错误描述字符串"
}
```

### 3.6 done
**触发时机**：流正常结束（所有事件发送完毕后）
**data 字段**：
```json
{}
```
> 客户端收到此事件后应关闭 SSE 连接。

---

## 四、数据库表结构

### users
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| username | VARCHAR(50) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| age_group | ENUM('L1','L2','L3') | NOT NULL |
| nickname | VARCHAR(50) | |
| avatar_url | VARCHAR(500) | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |

### reading_books
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| title | VARCHAR(100) | NOT NULL |
| age_group | ENUM('L1','L2','L3') | NOT NULL |
| cover_url | VARCHAR(500) | |
| difficulty | SMALLINT | DEFAULT 1 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### reading_sentences
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| book_id | BIGINT | FK → reading_books.id |
| sentence_index | INT | NOT NULL |
| original_text | TEXT | NOT NULL |
| sign_text | TEXT | NOT NULL |
| alignment_ops | JSON | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### practice_questions
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| level | ENUM('L1','L2','L3') | NOT NULL |
| type | VARCHAR(50) | NOT NULL |
| question | JSON | NOT NULL |
| answer | JSON | NOT NULL |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### practice_records
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id |
| question_id | BIGINT | FK → practice_questions.id |
| correct | BOOLEAN | NOT NULL |
| answered_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### dynamic_fallback
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| oov_word | VARCHAR(100) | UNIQUE, NOT NULL |
| fallback_word | VARCHAR(100) | NOT NULL |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |

### intent_mismatch_logs
| 字段 | 类型 | 约束 |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id, NOT NULL |
| original_text | TEXT | NOT NULL |
| failed_options | JSON | NOT NULL |
| context | TEXT | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

---

## 五、错误码定义

| 错误码 | HTTP状态码 | 说明 |
|---|---|---|
| AUTH_INVALID | 401 | 登录已失效，请重新登录 |
| RATE_LIMITED | 429 | 操作太频繁 |
| ENGINE_TIMEOUT | 502 | 算法引擎响应超时 |
| ENGINE_UNAVAILABLE | 503 | 算法引擎暂不可用 |
| ASR_FAILED | 500 | 语音识别失败 |
| VALIDATION_ERROR | 422 | 请求参数验证失败 |
| INTERNAL_ERROR | 500 | 服务器内部错误 |

**统一错误响应格式**：
```json
{
  "code": "ERROR_CODE",
  "message": "错误描述",
  "request_id": "请求追踪ID"
}
```
