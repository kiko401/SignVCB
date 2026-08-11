# TODO — 默语共鸣前端

> 当前阶段：**Flutter 前端 MVP 持续迭代 · 工程骨架已就位，等联调契约定稿**
> 更新日期：2026-08-08

---

## 契约状态（等同事的实际后端/算法代码）

以下为联调契约层待确认项，**以同事实际代码 / `../docs/api_contracts.md`、`../docs/data_contracts.md` 为准**，前端设计文档与之有冲突不作数。当前**只记录、不强绑定实现**：对契约敏感的模块先预留可替换的扩展结构（model / service 层留接口），不做深绑定。

- [ ] API 路径是否带 `chat` 段（如 `/api/v1/chat/rewrite` vs `/api/v1/rewrite`）
- [ ] `AlignmentOp` 字段：是否含 `source`、字段名与类型
- [ ] SSE 事件实际字段名（`preheat.original`、`first_pass.oov_status`、`refined_pass.nmm_hints` 结构等）
- [ ] `reading content` 路径形式（路径参数 `/books/{id}/content` vs query `?book_id=`）
- [ ] `/api/v1/app_config` 实际返回字段
- [ ] practice 相关接口响应结构
- [ ] 统一错误码与 message 格式

> 结论：契约层先挂起，等同事代码；先推进下方不依赖契约的纯前端部分，后续按真实代码回填。

---

## 不依赖契约 · 现在可推进（按优先级）

当前主线：**边搭边 run，用真实画面建立对项目的理解**。关键前提：**设计系统先行**——先把颜色/字号/圆角/阴影这套 token 定死，之后所有页面都引用它，即使逐页搭样式也不会乱（这是防止"按钮写三四套、间距不统一"的真正机制）。组件不预先全做，而是搭页面时发现复用点再抽取（渐进式抽象）。

- [x] **① 资产目录整理**：给 pubspec 声明的 6 个空 svg 子目录补 `.gitkeep` 占位，消除 "no file found" 构建错误。已验证 `flutter pub get` / `flutter analyze`（No issues）/ `flutter test`（passed）全通过
- [x] ② 设计系统补全：`AppTextStyles`（5级）/ `AppShadows`（3档）/ `AppColors`（13色）均已就位；新增 `AppDimens`（圆角L1/L2/L3/Toast/Full + 间距6档 + 组件尺寸）。flutter analyze No issues / flutter test passed
- [ ] ③ 逐个搭页面静态骨架并 run 起来看（从简单到复杂）：登录/注册 → 个人中心 → 书库 → 练习地图 → 阅读内容 → 三个练习页 → 沟通页（最复杂，放最后）。每页都要处理加载/空/错状态 ← **当前下一步**
- [ ] ④ 通用组件（搭页面过程中按需抽取，不预先全做）：PrimaryButton / SecondaryButton / TextInput / Card / Toast / LoadingOverlay / StarRating / EmptyState / ErrorState
- [ ] ⑤ 业务组件静态形态：WordCard / ChatBubble / MicButton / InputAssemblyTray / MapPathNode / BookCard（先用假数据，不接网络）

## Mock 数据驱动（可选增强，仍不依赖契约）

让页面能"演示"，帮自己理解业务、也作面试展示。**Mock 层与未来真实接口层分离**，将来接真实契约只换数据来源：

- [ ] 为 login / profile / booklist / practice map 准备本地假数据
- [ ] 为 chat 页准备本地假消息流（先不接真实 SSE）
- [ ] 关键页面能脱离后端独立演示

> 注意：Mock 够演示即可，不为每页精雕。

## 依赖契约 · 待契约定稿后再做

- [ ] 重写 `chat_models` 数据类，字段类型对齐契约
- [ ] 新建 `shared/models/alignment_op.dart`（按契约含/不含 source）
- [ ] chat_api / chat_provider（SSE 事件消费与词卡状态机）
- [ ] reading / practice 的 data + service 层
- [ ] 各页面接真实数据、联调

---

## 项目沉淀（面试材料 · 持续进行）

每完成一个模块就补，不要攒到最后：

- [ ] 持续更新 `INTERVIEW_NOTES.md`
- [ ] 记录：目录结构设计 / 状态管理设计 / 路由设计 / 网络层与错误处理设计
- [ ] 记录：Mock → 真实联调的演进过程（这是很好的面试故事）
- [ ] 每个模块补：一句话亮点 / 可复述版本 / STAR / 可追问点 / 回答提纲

---

## 已完成（工程骨架 + 认知准备）

- [x] 全局页面地图 + 导航流程梳理（三层结构：门口无导航 / 主屋 4 tab / 里间全屏详情；12 页面对号入座）
- [x] Flutter 工程初始化（moyu_app）
- [x] 网络层：dio + 拦截器（X-Request-ID / 鉴权 / 401 强制登出 / 错误码映射）
- [x] SSE 客户端骨架
- [x] TokenStorage 本地存储
- [x] 路由：go_router + ShellRoute 底部 4 tab + 登录态重定向
- [x] auth 全链路（provider / service / 登录注册启动页）
- [x] config_provider + 主题骨架
