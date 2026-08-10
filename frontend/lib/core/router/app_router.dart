/*
# 完整运行流程
1. App 启动，加载全局 appRouterProvider，生成 GoRouter 路由对象
2. GoRouterNotifier 开始监听你的登录状态
3. 程序首先打开闪屏页 /splash，加载本地 token
4. redirect 钩子每时每刻拦截跳转
   - 正在加载 token → 停留在闪屏页
   - 没有登录 → 强制跳转登录页
   - 已经登录 → 直接进入聊天主页
5. 聊天、练习、阅读、个人主页全部放在底部导航外壳 ShellRoute 里面
6. 退出登录，登录状态改变，监听器触发通知，路由立刻拦截跳转到登录页面

# 知识点清单
1. go_router：Flutter 主流路由框架，管理页面地址、跳转
2. Provider 创建全局唯一路由实例
3. redirect 路由守卫、登录拦截权限控制
4. ShellRoute 外壳路由，实现固定底部导航，子页面嵌套
5. NoTransitionPage 关闭页面切换动画
6. 动态路径参数 pathParameters 传递 id
7. ChangeNotifier 状态通知、ref.listen 监听登录状态
8. refreshListenable：监听登录变化，自动触发路由重定向
*/

import 'package:flutter/material.dart'; //Flutter UI 基础组件库
import 'package:flutter_riverpod/flutter_riverpod.dart'; //状态管理，用来创建全局路由单例、监听登录状态
import 'package:go_router/go_router.dart'; //第三方最主流路由框架 go_router；

import '../../features/auth/application/auth_provider.dart'; //登录模块仓库，里面存放登录状态 AuthState
import '../../features/auth/presentation/login_page.dart'; //登录页
import '../../features/auth/presentation/register_page.dart'; //注册页
import '../../features/auth/presentation/splash_page.dart'; //启动页（闪屏页）
import '../../features/chat/presentation/chat_page.dart'; //AI 聊天页
import '../../features/practice/presentation/practice_map_page.dart'; //练习地图页
import '../../features/practice/presentation/sign_recognize_page.dart'; //签名识别页
import '../../features/practice/presentation/sentence_order_page.dart'; //句子排序页
import '../../features/practice/presentation/word_match_page.dart'; //单词匹配页
import '../../features/profile/presentation/profile_page.dart'; //个人资料页
import '../../features/reading/presentation/book_list_page.dart'; //图书列表页
import '../../features/reading/presentation/reading_content_page.dart'; //阅读内容页
import '../../shared/widgets/main_shell.dart'; //主界面框架

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = GoRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash', //程序初始默认页面
    refreshListenable: notifier, //登录 / 退出登录的时候，路由会自动触发重定向跳转
    redirect: (context, state) {
      //redirect 每次页面跳转前都会执行，用来拦截、强制跳转页面
      final authState = ref.read(authProvider); //读取登录仓库，拿到当前登录状态,三种状态
      final status = authState.status;
      final location = state.matchedLocation; //当前跳转的路径
      final isSplash = location == '/splash'; //判断现在是不是启动页
      final isAuth = location
          .startsWith('/auth'); //判断路径是不是登录注册页（/auth/login、/auth/register）

      if (status == AuthStatus.initial) {
        //正在初始化
        return isSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        //用户未登录
        if (isSplash || isAuth) return null;
        return '/auth/login';
      }
      if (isSplash || isAuth) return '/chat'; //已经登录
      return null;
    },
    routes: [
      //独立路由
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      //外壳路由
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            pageBuilder: (_, __) => const NoTransitionPage(
                child: ChatPage()), //关闭页面切换动画，页面之间硬切换，没有滑动过渡动画
          ),
          GoRoute(
            path: '/reading/books',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: BookListPage()),
          ),
          GoRoute(
            path: '/practice/map',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: PracticeMapPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      //带参数路由：书本阅读详情页
      GoRoute(
        path: '/reading/content/:bookId',
        builder: (_, state) =>
            ReadingContentPage(bookId: state.pathParameters['bookId'] ?? ''),
      ),
      //其余练习页面路由
      GoRoute(
          path: '/practice/word_match',
          builder: (_, __) => const WordMatchPage()),
      GoRoute(
          path: '/practice/sentence_order',
          builder: (_, __) => const SentenceOrderPage()),
      GoRoute(
          path: '/practice/sign_recognize',
          builder: (_, __) => const SignRecognizePage()),
    ],
  );
});

//监听登录状态，登录状态一变，就通知 go‑router 重新执行 redirect 权限拦截
class GoRouterNotifier extends ChangeNotifier {
  GoRouterNotifier(this.ref) {
    //构造函数接收 ref
    ref.listen<AuthState>(authProvider, (previous, next) {
      //ref.listen 持续监听登录状态 authProvider
      if (previous?.status != next.status) {
        //当登录状态发生改变（登录成功 / 退出登录 /token 过期）
        notifyListeners(); //发出通知，refreshListenable 监听到通知，触发路由重定向
      }
    });
  }

  final Ref ref; //保存 Riverpod 引用
}
