import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/practice/presentation/practice_map_page.dart';
import '../../features/practice/presentation/sign_recognize_page.dart';
import '../../features/practice/presentation/sentence_order_page.dart';
import '../../features/practice/presentation/word_match_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/reading/presentation/book_list_page.dart';
import '../../features/reading/presentation/reading_content_page.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = GoRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isAuth = location.startsWith('/auth');

      if (status == AuthStatus.initial) {
        return isSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        if (isSplash || isAuth) return null;
        return '/auth/login';
      }
      if (isSplash || isAuth) return '/chat';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            pageBuilder: (_, __) => const NoTransitionPage(child: ChatPage()),
          ),
          GoRoute(
            path: '/reading/books',
            pageBuilder: (_, __) => const NoTransitionPage(child: BookListPage()),
          ),
          GoRoute(
            path: '/practice/map',
            pageBuilder: (_, __) => const NoTransitionPage(child: PracticeMapPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        path: '/reading/content/:bookId',
        builder: (_, state) => ReadingContentPage(bookId: state.pathParameters['bookId'] ?? ''),
      ),
      GoRoute(path: '/practice/word_match', builder: (_, __) => const WordMatchPage()),
      GoRoute(path: '/practice/sentence_order', builder: (_, __) => const SentenceOrderPage()),
      GoRoute(path: '/practice/sign_recognize', builder: (_, __) => const SignRecognizePage()),
    ],
  );
});

class GoRouterNotifier extends ChangeNotifier {
  GoRouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
}
