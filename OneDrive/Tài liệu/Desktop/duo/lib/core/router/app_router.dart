import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/app_lock_screen.dart';
import '../../features/auth/screens/couple_link_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/music/screens/together_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/notes/screens/compose_note_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/snaps/screens/snaps_tab_screen.dart';
import '../../features/snaps/screens/snap_camera_screen.dart';
import '../../features/snaps/screens/snap_view_screen.dart';
import '../../core/snaps/snaps_models.dart';
import '../../core/notes/notes_models.dart';
import '../../features/games/screens/chess_screen.dart';
import '../../features/games/screens/tic_tac_toe_screen.dart';
import '../../features/games/screens/truth_or_dare_screen.dart';
import '../../features/games/screens/love_quiz_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorChatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final _shellNavigatorSnapsKey = GlobalKey<NavigatorState>(debugLabel: 'snaps');
final _shellNavigatorTogetherKey =
    GlobalKey<NavigatorState>(debugLabel: 'together');
final _shellNavigatorNotesKey = GlobalKey<NavigatorState>(debugLabel: 'notes');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => AppLockScreen(targetPath: state.extra as String? ?? '/home'),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignUpScreen(),
          ),
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: 'link',
            builder: (context, state) => const CoupleLinkScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChatKey,
            routes: [
              GoRoute(
                path: '/home/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSnapsKey,
            routes: [
              GoRoute(
                path: '/home/snaps',
                builder: (context, state) => const SnapsTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTogetherKey,
            routes: [
              GoRoute(
                path: '/home/together',
                builder: (context, state) => const TogetherScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorNotesKey,
            routes: [
              GoRoute(
                path: '/home/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/home/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/home/chat',
      ),
      GoRoute(
        path: '/games/chess',
        builder: (context, state) => const ChessScreen(),
      ),
      GoRoute(
        path: '/games/tictactoe',
        builder: (context, state) => const TicTacToeScreen(),
      ),
      GoRoute(
        path: '/games/truth_or_dare',
        builder: (context, state) => const TruthOrDareScreen(),
      ),
      GoRoute(
        path: '/games/love_quiz',
        builder: (context, state) => const LoveQuizScreen(),
      ),
      GoRoute(
        path: '/home/snaps/camera',
        builder: (context, state) => const SnapCameraScreen(),
      ),
      GoRoute(
        path: '/home/snaps/view',
        builder: (context, state) => SnapViewScreen(snap: state.extra as Snap),
      ),
      GoRoute(
        path: '/home/notes/compose',
        builder: (context, state) => ComposeNoteScreen(note: state.extra as Note?),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/home') return '/home/chat';
      return null;
    },
  );
});
