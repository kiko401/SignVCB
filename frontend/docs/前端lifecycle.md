# 前端 App 详细生命周期规划

**文档属性**：前端组专属施工手册 / 每步可执行 / 与 v3.3 设计文档严格对齐
**执行主体**：前端 Flutter 开发组（2-3 人）
**总工期**：Day 0（前期准备，1 天）→ Day 1-3（主线开发，3 天）→ Day 4-5（联调交付，2 天）= 6 天
**前置依赖**：`docs/api_contracts.md`、`docs/data_contracts.md`、`frontend_v3.3.md`、`.env` 全部就位

---

## 📋 阶段 A：前期准备（Day 0，由统筹者完成，本组组长只需 5 步）

- [ ] **A.1** 阅读 `docs/api_contracts.md` 13 个接口 + 4 个 SSE 事件的 JSON 结构
- [ ] **A.2** 阅读 `docs/data_contracts.md` 强类型模型（AlignmentOp、PreheatData、FirstPassData、RefinedPassData、FallbackData、PracticeQuestionResponse、AppConfigResponse）
- [ ] **A.3** 确认 `BASE_URL = http://<SERVER_IP>:8081`（v3.3 锁定：Nginx 唯一对外入口）
- [ ] **A.4** 从 dev 切出工作分支：
  ```bash
  git fetch origin
  git checkout dev
  git pull origin dev
  git checkout -b step/frontend-day1-skeleton
  ```
- [ ] **A.5** 本地 Flutter 环境验证：`flutter --version` 期望 3.22+；`flutter doctor` 无红色 error

---

## 🛠️ 阶段 B：主线开发（Day 1-3，并行开发期）

### Day 1：Flutter 工程骨架 + 网络层基建（10 步最小可执行）

#### F-1.1 切换分支与初始化 Flutter 工程

```bash
cd /workspace/SignVCB
git checkout -b step/frontend-day1-skeleton
flutter create app --org com.moyu --project-name moyu_app
cd app
# 删除默认 counter app
rm -rf test/widget_test.dart lib/main.dart
mkdir -p lib/{core/{router,network,storage,theme,utils},features/{auth,chat,reading,practice,profile}/{data,application,presentation/widgets},shared/{widgets,models},generated}
```

#### F-1.2 写入 `pubspec.yaml` 依赖（v3.3 严格）

```yaml
name: moyu_app
description: 默语共鸣 - 听障儿童无障碍沟通与学习应用
version: 3.3.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  dio: ^5.4.0
  shared_preferences: ^2.2.0
  record: ^5.0.0
  just_audio: ^0.9.37
  rive: ^0.13.0
  flutter_svg: ^2.0.0
  permission_handler: ^11.3.0
  uuid: ^4.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  flutter_gen_runner: ^5.4.0
  mockito: ^5.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/rive/
    - assets/svg/yuyu/
    - assets/svg/icons/
    - assets/svg/word_cards/
    - assets/svg/covers/
    - assets/svg/nodes/
    - assets/svg/deco/

flutter_gen:
  output: lib/generated/
  integrations:
    rive: true
    flutter_svg: true
```

```bash
flutter pub get
```

#### F-1.3 写入 `lib/core/theme/` 三个文件（v3.3 第一部分）

按 v3.3 第一部分 2-4 节写入：
- `app_colors.dart`：14 个色值（星光紫/丁香紫/晨雾紫/奶酪黄/嫩芽黄/樱花粉/云灰/浅云灰/静谧蓝/薄云灰/金桔橙/浅金黄/纯白/...）
- `app_text_styles.dart`：5 个层级（Display/H1/H2/Body/Caption）
- `app_shadows.dart`：3 个阴影（Resting/Lifted/Floating）

**自检命令**：
```bash
cd /workspace/SignVCB/app
flutter analyze lib/core/theme/
```

#### F-1.4 写入 `lib/core/storage/token_storage.dart`（v3.3 第六部分 5 节）

按 v3.3 第六部分 5 节逐字写入：
- `_keyToken/_keyUserId/_keyUsername/_keyAgeGroup` 四个 SharedPreferences key
- `saveToken / getToken / saveUser / getUser / clear` 五个方法

**自检**：
```dart
// 在 lib/core/storage/token_storage_test.dart
void main() {
  test('TokenStorage round trip', () async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.saveToken('abc');
    expect(await TokenStorage.getToken(), 'abc');
  });
}
```

#### F-1.5 写入 `lib/core/network/api_error_code.dart` + `api_exception.dart`（v3.3 第六部分 4 节）

按 v3.3 第六部分 4 节逐字写入：
- `ApiErrorCode` 枚举：authInvalid / rateLimited / engineTimeout / engineUnavailable / asrFailed / validationError / internalError / unknown
- `ApiException` 类：code / message / requestId / statusCode + `fromJson` 工厂

#### F-1.6 写入 `lib/core/utils/logger.dart`（v3.2 补全）

```dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(Object? message) { if (kDebugMode) debugPrint('🐛 $message'); }
  static void i(Object? message) { debugPrint('ℹ️ $message'); }
  static void w(Object? message) { debugPrint('⚠️ $message'); }
  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ $message');
    if (error != null) debugPrint('   error: $error');
    if (stackTrace != null) debugPrint('   stack: $stackTrace');
  }
}
```

#### F-1.7 写入 `lib/core/network/dio_client.dart`（v3.2 修复 + v3.3 401 全局跳登录）

按 v3.3 第六部分 6 节 + 7.5 节逐字写入：
- `dioProvider`：baseUrl = `http://<SERVER_IP>:8081`（v3.2 修复，端口是 Nginx 8081）
- `RequestIdInterceptor`：自动注入 `X-Request-ID` header
- `AuthInterceptor`：跳过 `/auth/login`、`/auth/register`、`/app_config`，其他接口注入 `Bearer <token>`
- `ErrorInterceptor`（v3.3 修复）：401 → 调 `authProvider.notifier.forceLogout()` 跳登录页

#### F-1.8 写入 `lib/core/network/sse_client.dart`（v3.2 关键修复：`receiveTimeout: Duration.zero`）

按 v3.3 第六部分 7 节 + v3.2 修复写入：
- `SseClient.stream()` 返回 `Stream<SseEvent>`
- **`receiveTimeout: Duration.zero`**（v3.2 修复：避免被 dio 截断 SSE 长连接）
- 用 `response.data!.stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter())` 解析
- `currentEvent` / `currentData` 配对 yield 后重置

#### F-1.9 写入 `lib/features/chat/data/sse_event.dart` + `chat_models.dart`（v3.3 强类型）

按 v3.3 第六部分 2-3 节逐字写入：
- `SseEvent` 类 + `SseEventType` 枚举（v3.2 修复：空值容错）
- `PreheatData`（含 `tokens` getter）
- `FirstPassData`（含 `tokens` getter + oovStatus）
- `RefinedPassData`（含 oovMap / nmmHints / alignmentOps + `isFallbackWord` 方法）
- `FallbackData`
- `nmmHintToEmoji` 辅助函数（NEGATION→🚫, QUESTION→❓, PAUSE→⏸️）

#### F-1.10 Day 1 验收门禁

```bash
cd /workspace/SignVCB/app
flutter pub get
flutter analyze
flutter test
# 自检：模拟 SSE 解析
flutter test test/sse_parser_test.dart
```

- [ ] `flutter pub get` 无错误
- [ ] `flutter analyze` 0 error
- [ ] `flutter test` 全绿
- [ ] `dio_client.dart` baseUrl 配置 8081
- [ ] `sse_client.dart` `receiveTimeout: Duration.zero`
- [ ] `git log --oneline` 显示 Day 1 commit

---

### Day 2：服务层 + 状态机 + 12 页面骨架（12 步最小可执行）

#### F-2.1 切换分支

```bash
git checkout -b step/frontend-day2-services
```

#### F-2.2 写入 5 个 API Service

按 v3.3 第六部分 8-12 节 + 第七部分 7.4 逐字写入：
- `features/auth/data/auth_api.dart`：register / login / logout
- `features/chat/data/chat_api.dart`：asrAndRewrite (FormData) / rewrite / tts / suggestReply / normalizeOptions / logMismatch（v3.2 修复：async 返回 Stream）
- `features/reading/data/reading_api.dart`：getBooks (v3.2 修复：直接解析数组) / getContent
- `features/practice/data/practice_api.dart`：getQuestion / validate
- `features/profile/data/config_api.dart`：fetch（v3.3 补全 4 字段）

**自检**：
```bash
flutter analyze lib/features/
```

#### F-2.3 写入 `shared/models/alignment_op.dart`（v3.1 修复：未知 type 抛异常）

按 v3.3 第六部分 1 节 + v3.1 修复：
- `AlignmentOpType` 枚举
- `AlignmentOp` class + `fromJson`（未知 type 抛 `FormatException`）+ `toJson`

#### F-2.4 写入 `lib/features/chat/application/chat_provider.dart`（核心 SSE 状态机）

按 v3.3 第六部分 9 节 + v3.2 修复逐字写入：
- `ChatStatus` / `CardState` / `WordCardData`
- `ChatViewModel extends StateNotifier<ChatState>`：
  - `rewriteText(text, context)`（文本模式，立即调 `_chatService.rewrite`）
  - `rewriteAudio(audioFile, context)`（v3.1 修复：async 方法）
  - `_handlePreheat`：用 `data.tokens` 生成 `WordCardData(placeholder)`
  - `_handleFirstPass`（v3.1 修复：用 `data.tokens` 而非 `data['tokens']`）：所有词卡 `CardState.normal`；根据 `enableStreamMasking + oovStatus` 决定是否加脉冲
  - `_handleRefinedPass`（v3.1 修复：用 `isFallbackWord` 判断降级词）：按 `alignment_ops` 触发位移/删除/插入动画；按 `nmmHints` 叠加 emoji
  - `_handleFallback` / `_handleTimeout` / `_handleError`
  - 8s Timer 兜底

**自检**：
```dart
// test/chat_viewmodel_test.dart
test('preheat event fills cards with placeholder', () {
  // 构造 mock stream 发出 preheat + first_pass + refined_pass
  // 验证 state.currentCards 状态变迁
});
```

#### F-2.5 写入 `lib/features/auth/application/auth_provider.dart`（v3.2 补全）

按 v3.3 第七部分 7.1 节逐字写入：
- `AuthStatus` 枚举：initial / authenticated / unaauthenticated / loading
- `AuthNotifier extends StateNotifier<AuthState>`：
  - `_bootstrap()`：读 Token + 用户信息
  - `login / register / logout / forceLogout`

#### F-2.6 写入 `lib/features/profile/application/config_provider.dart`

按 v3.3 第六部分 10 节 + v3.2 补全：
- `AppConfig` 类（v3.3 补全 showOovMap + showNmmHints）
- `ConfigNotifier extends StateNotifier<AppConfig>`：含 `refresh()` 公开方法

#### F-2.7 写入 `lib/core/router/app_router.dart`（v3.2 补全 ShellRoute）

按 v3.3 第七部分 7.2 节逐字写入：
- `GoRouter` + `ShellRoute`（4 个 tab）+ 详情页顶层路由
- `GoRouterRefreshStream` 让 authProvider 状态变化时自动重定向
- redirect 逻辑：未登录跳 `/auth/login`

#### F-2.8 写入 `lib/shared/widgets/main_shell.dart`（v3.2 补全底部 4 tab）

按 v3.3 第七部分 7.3 节逐字写入：
- 4 个 `_TabItem`（chat / reading/books / practice/map / profile）
- 64dp 高度 + SafeArea + 顶部阴影
- 激活态星光紫，未激活态薄云灰

#### F-2.9 写入 6 个 共享组件

按 v3.3 第五部分逐字写入：
- `shared/widgets/primary_button.dart`（高 56dp 圆角 28dp 星光紫）
- `shared/widgets/secondary_button.dart`（高 48dp 圆角 24dp 白底紫边）
- `shared/widgets/text_input.dart`（高 56dp 圆角 20dp 云灰底）
- `shared/widgets/card.dart`（圆角 20dp 白底）
- `shared/widgets/toast.dart`（底部偏移 80dp 圆角 16dp 半透明黑底）
- `shared/widgets/star_rating.dart`（3 颗 32dp 奶酪黄）

#### F-2.10 写入 8 个 Chat 业务组件

按 v3.3 第五部分二逐字写入：
- `word_card.dart`（96x80dp，5 个状态：placeholder/normal/degraded/correct/error）
- `chat_bubble.dart`（最大宽度 75% 圆角 20dp）
- `mic_button.dart`（96dp 直径 长按录音）
- `asr_wave_overlay.dart`（160x80dp 5 根柱状条）
- `input_assembly_tray.dart`（100dp 高 横排 WordCard）
- `intent_bubble.dart`（候选气泡）
- `tts_visualizer.dart`（120dp 嘴部开合）

#### F-2.11 写入 12 个 Page 骨架（不含完整业务逻辑，只放占位）

按 v3.3 第八部分结构创建 12 个文件 + 引入对应 Widget：
- `features/auth/presentation/splash_page.dart`（v3.2 补全：3s 超时 + AuthProvider 监听跳转）
- `features/auth/presentation/login_page.dart`（调用 AuthService.login + AuthNotifier.login）
- `features/auth/presentation/register_page.dart`（同 login）
- `features/chat/presentation/chat_page.dart`（含 ChatViewModel + 词卡列表 + MicButton + InputAssemblyTray）
- `features/reading/presentation/book_list_page.dart`（GridView + BookCard）
- `features/reading/presentation/reading_content_page.dart`（ListView + ReadingText）
- `features/practice/presentation/practice_map_page.dart`（MapPathNode）
- `features/practice/presentation/word_match_page.dart`（拖拽拼图）
- `features/practice/presentation/sentence_order_page.dart`（TianZiGeCanvas）
- `features/practice/presentation/sign_recognize_page.dart`（跟读 MicButton）
- `features/profile/presentation/profile_page.dart`（鹿角进度 + 退出登录）

#### F-2.12 Day 2 验收门禁

- [ ] 5 个 API Service + 2 个 Provider + 1 个 Router + 1 个 MainShell 全部就位
- [ ] ChatViewModel 单测通过（preheat → first_pass → refined_pass 状态变迁）
- [ ] AuthProvider 单测通过（bootstrap / login / forceLogout）
- [ ] 12 个 Page 骨架（每个文件至少有 `class XxxPage extends ConsumerWidget/StatefulWidget`）
- [ ] `flutter analyze` 0 error
- [ ] `git log --oneline` 显示 Day 2 commit

---

### Day 3：main.dart 入口 + 12 页面装配 + 单元测试（10 步最小可执行）

#### F-3.1 切换分支

```bash
git checkout -b step/frontend-day3-main
```

#### F-3.2 写入 `lib/main.dart`（v3.2 补全完整入口）

按 v3.3 第七部分 7.6 节 + v3.2 补全逐字写入：
- `void main()` → `runApp(const ProviderScope(child: MoyuApp()))`
- `MoyuApp extends ConsumerStatefulWidget`
- `initState`：`Future.microtask` 调 `configProvider.notifier.refresh()` 拉全局配置
- `build`：MaterialApp.router + 主题 + ToastHost

#### F-3.3 配置 Android 明文 HTTP

修改 `android/app/src/main/AndroidManifest.xml`：
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

#### F-3.4 配置 iOS 明文 HTTP

修改 `ios/Runner/Info.plist`，加：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

#### F-3.5 写入 `lib/core/utils/audio_collector.dart` + `audio_player.dart`

按 v3.3 第四部分流程 1 写入：
- `AudioCollector`：WAV/16k/16bit/单声道，失败抛异常
- `AudioPlayerSingleton`：单例 just_audio，切换页面不中断

#### F-3.6 写入 12 个 Page 的业务逻辑

逐个页面填入业务逻辑（按 v3.3 第八部分详细拼装方案）：

**优先级**：
1. **SplashPage**（v3.2 补全完整实现）
2. **LoginPage / RegisterPage**（调 AuthNotifier）
3. **ChatPage**（含 ChatViewModel + 词卡状态机 + MicButton + InputAssemblyTray + IntentBubble）
4. **PracticeMapPage + WordMatchPage**（L1 拼图）
5. **BookListPage + ReadingContentPage**
6. **SentenceOrderPage + SignRecognizePage**
7. **ProfilePage**

每完成一个 Page，立即写 widget test 验证可渲染。

#### F-3.7 写入 SSE 重连逻辑（v3.3 增强）

在 `ChatViewModel` 中加 SSE 自动重连：
```dart
// 指数退避 1s/2s/4s，最多 3 次
Future<void> _connectWithRetry() async {
  for (var i = 0; i < 3; i++) {
    try { return await _connect(); }
    catch (e) {
      if (i == 2) rethrow;
      await Future.delayed(Duration(seconds: 1 << i));
    }
  }
}
```

#### F-3.8 写入数据飞轮日志上报

在 `ChatViewModel` 的"都不是"分支，调 `_chatService.logMismatch(text, suggestions.map((s) => s.text).toList())`。

#### F-3.9 编译并跑模拟器

```bash
cd /workspace/SignVCB/app
# 启动 Android 模拟器
flutter emulators --launch <emulator_id>

# 指定 BASE_URL
flutter run --dart-define=API_BASE_URL=http://<SERVER_IP>:8081 -d <device>

# 验证：
# 1. 启动页 → 登录页（3s 后）
# 2. 注册 → 跳聊天页
# 3. 输入"我吃苹果" → 看到 preheat → first_pass → refined_pass
```

#### F-3.10 Day 3 验收门禁

- [ ] `flutter run` 成功启动
- [ ] Splash → Login → Register → Chat 全流程跑通
- [ ] SSE 事件流正确解析（preheat/first_pass/refined_pass）
- [ ] 录音 + 上传 + 播放 TTS 全跑通
- [ ] 401 拦截跳登录页生效
- [ ] `git log --oneline` 显示 Day 3 commit

---

## 🔗 阶段 C：联调与交付（Day 4-5）

### Day 4：与后端组 + 算法组联调（10 步）

#### F-4.1 切换联调分支

```bash
git checkout dev
git pull origin dev
git checkout -b step/integration-frontend
```

#### F-4.2 接收后端联调服务器信息

统筹者提供：
- 后端 BFF 公网 URL：`http://<SERVER_IP>:8081`
- 测试账号：`smoke / smoke123`
- 启动命令：`flutter run --dart-define=API_BASE_URL=http://<SERVER_IP>:8081`

#### F-4.3 联调登录注册流程

打开 App → Splash → Login → 输入 `smoke / smoke123` → 登录成功 → 进入 ChatPage

**Bug 排查清单**：
| 现象 | 可能原因 | 修复方式 |
|:---|:---|:---|
| 网络连接失败 | BASE_URL 错 | 检查 `--dart-define` |
| 401 无限循环 | AuthInterceptor 跳过路径错 | 检查 `/app_config` 是否在白名单 |
| 登录后立刻退出 | Token 没存 | 检查 TokenStorage.saveToken 调用 |

#### F-4.4 联调 SSE 流程

在 ChatPage 输入"我吃苹果" → 看到：
- 词卡从占位灰卡 → 正常 CSL 词卡
- 收到 refined_pass 后词卡根据 alignment_ops 动画移动
- 8s 内没收到 refined_pass → fallback 文案

**Bug 排查清单**：
| 现象 | 可能原因 | 修复方式 |
|:---|:---|:---|
| 词卡一直占位 | SSE 解析失败 | 检查 SseClient receiveTimeout 配置 |
| first_pass 没收到 | 后端按开关过滤了 | 检查 v3.3 first_pass 透传契约 |
| refined_pass 字段解析失败 | Pydantic 与 Dart 不一致 | 查 `data_contracts.md` |
| OOV 词卡不显示降级色 | isFallbackWord 逻辑 | 检查 oovMap.values.contains |

#### F-4.5 联调录音 + TTS 播放

长按 MicButton → 录音 → 松手 → ASR → preheat(空) → ASR 结果 → first_pass → refined_pass → 词卡

点击 ChatBubble 的喇叭 → TTS 请求 → 播放音频

**Bug 排查清单**：
| 现象 | 可能原因 | 修复方式 |
|:---|:---|:---|
| 录音启动失败 | permission_handler 权限 | 检查 AndroidManifest 麦克风权限 |
| TTS URL 不可访问 | audio_url 拼接错 | 检查 SERVER_PUBLIC_HOST 配置 |
| 播放卡顿 | just_audio 单例问题 | 检查 AudioPlayerSingleton |

#### F-4.6 联调 401 拦截跳登录

在另一个设备登出 → App 收到 401 → 自动跳 LoginPage

**Bug 排查清单**：
| 现象 | 可能原因 | 修复方式 |
|:---|:---|:---|
| 不跳登录页 | ErrorInterceptor 401 检测失败 | 检查 ApiErrorCode.authInvalid |
| 死循环跳登录 | Splash 不停触发 bootstrap | 检查 SplashPage 状态机 |

#### F-4.7 联调 reading / practice 模块

- 进入 BookListPage → 看到书籍列表
- 点击书 → 进入 ReadingContentPage → 点击句子 → TTS 播放
- 进入 PracticeMapPage → 点击节点 → 进入 WordMatchPage → 拖拽拼图 → 提交

#### F-4.8 修复联调 Bug

按优先级修复并 commit。常见 Bug：
- 录音格式不对导致 ASR 失败 → 配 16k/16bit/单声道
- alignment_ops 动画卡顿 → 减少 AnimatedContainer 嵌套
- Riverpod 状态更新不及时 → 检查 StateNotifier 用法

#### F-4.9 写集成测试

```dart
// test/integration/chat_flow_test.dart
testWidgets('Full chat flow with mock backend', (tester) async {
  // 注入 mock ChatService
  // 验证 12 个页面的状态机
});
```

```bash
flutter test test/integration/
```

#### F-4.10 Day 4 验收门禁

- [ ] App 能正常登录 → 聊天 → 录音 → 改写 → 词卡动画
- [ ] 12 个页面全部能渲染（用真机或模拟器走一遍）
- [ ] 401 拦截跳登录页生效
- [ ] 集成测试全绿
- [ ] `git log --oneline` 显示 Day 4 commit

---

### Day 5：消融实验配合 + 验收 + 归档（8 步）

#### F-5.1 切换收尾分支

```bash
git checkout -b step/finalization-frontend
```

#### F-5.2 配合算法组做 SHOW_OOV_MAP 消融

```bash
# 后端组修改 .env
SHOW_OOV_MAP=false
docker compose restart signvcb-server
# 前端 app 中观察：refined_pass.oov_map = {}，降级词卡无脉冲动画
```

App 中 `AppConfig.showOovMap` 应为 false，`RefinedPassData.isFallbackWord` 返回 false，词卡保持 normal 状态。

#### F-5.3 配合算法组做 SHOW_NMM_HINTS 消融

```bash
SHOW_NMM_HINTS=false
docker compose restart signvcb-server
# 前端：NMM emoji 不显示
```

App 中 `AppConfig.showNmmHints` 为 false，词卡上方不叠加 NMM emoji。

#### F-5.4 配合算法组做 ENABLE_STREAM_MASKING 消融

```bash
ENABLE_STREAM_MASKING=false
docker compose restart signvcb-server
# 前端：first_pass 仍收到（v3.3 锁定：算法 yield + 后端透传），但 OOV 词卡无脉冲动画
```

**v3.3 验收**：App 仍能收到 first_pass 事件（不断流），只是 UI 不加脉冲。

#### F-5.5 端到端验收

打开 App → 完成 12 个页面的完整用户旅程：
1. 注册 / 登录
2. 主沟通页：输入文本 → 收到 SSE 事件流 → 词卡动画
3. 主沟通页：长按录音 → ASR → 改写 → 词卡
4. 主沟通页：点击词卡 → TTS 播放
5. 阅读：选书 → 看句子 → 点击 TTS
6. 练习：选节点 → 拼图 / 田字格 / 跟读
7. 个人中心：看鹿角进度 → 退出登录

#### F-5.6 性能优化

- `flutter run --release` 跑一遍
- 用 DevTools 看 widget rebuild 次数
- 优化大列表（chat_page 词卡列表）性能

#### F-5.7 归档源码

```bash
cd /workspace/SignVCB
mkdir -p docs/archive/v3.3/frontend_lib
cp -r app/lib/ docs/archive/v3.3/frontend_lib/
cp app/pubspec.yaml docs/archive/v3.3/
git add docs/archive/
git commit -m "chore(frontend): Day 5 archive - source code, dependencies"
```

#### F-5.8 Day 5 验收门禁（前端组最终交付）

- [ ] 12 个页面全部跑通（含真机/模拟器完整用户旅程）
- [ ] 配合算法组完成 3 个消融实验（SHOW_OOV_MAP / SHOW_NMM_HINTS / ENABLE_STREAM_MASKING）
- [ ] 集成测试 + 单元测试全绿
- [ ] `flutter analyze` 0 error
- [ ] `docs/archive/v3.3/frontend_lib/` 归档完成
- [ ] `git log --oneline` 显示 Day 5 commit
- [ ] PR 合并入 dev + main

---

## 🚨 前端组红线（10 条不可触犯）

1. ❌ **绝不**直接 commit 到 `main` 或 `dev`
2. ❌ **绝不**修改 `docs/api_contracts.md`（已冻结）
3. ❌ **绝不**在 `SseClient` 设 `receiveTimeout` 不为 `Duration.zero`（会截断 SSE）
4. ❌ **绝不**让前端直连算法引擎（必须走 8081 → BFF 8000 → Engine 8001）
5. ❌ **绝不**在 `SplashPage` 写死跳转路径（用 `ref.listen(authProvider)`）
6. ❌ **绝不**忘记 401 时调 `forceLogout()`
7. ❌ **绝不**把 `X-Request-ID` 写死（用 RequestIdInterceptor 自动生成）
8. ❌ **绝不**让 TTS audio_url 二次拼接（用 `SERVER_PUBLIC_HOST` 绝对路径）
9. ❌ **绝不**让 `failed_options` 传对象数组（必须 `.map((s) => s.text).toList()`）
10. ❌ **绝不**用 emoji 存 `nmm_hints`（必须用 `NEGATION/QUESTION/PAUSE` 字符串）

---

**前端组任务到此结束。Day 5 完成后由项目统筹者统一宣布交付完成。**
