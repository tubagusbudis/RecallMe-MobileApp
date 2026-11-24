import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/decks/presentation/deck_detail_screen.dart';
import '../features/decks/presentation/deck_form_screen.dart';
import '../features/decks/presentation/deck_list_screen.dart';
import '../features/flashcards/presentation/flashcard_form_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/navigation/presentation/main_scaffold.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/study/presentation/study_deck_picker_screen.dart';
import '../features/study/presentation/study_session_screen.dart';
import '../features/study/presentation/study_summary_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Listens to auth state changes to trigger GoRouter re-evaluation of route guards.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isPasswordRecovery != next.isPasswordRecovery) {
        notifyListeners();
      }
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;
    final location = state.matchedLocation;
    final isPublicAuthRoute =
        location == '/welcome' ||
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password';

    // 1. If currently on /forgot-password OR in password recovery mode:
    // GoRouter MUST NOT throw user to /app/home.
    if (location == '/forgot-password' || authState.isPasswordRecovery) {
      if (location.startsWith('/app')) {
        return '/login';
      }
      return null;
    }

    // 2. If not authenticated:
    // If attempting to view protected /app routes, redirect directly to /login
    if (!isAuthenticated) {
      if (location.startsWith('/app')) {
        return '/login';
      }
      return isPublicAuthRoute ? null : '/welcome';
    }

    // 3. If authenticated and attempting to view /welcome, /login, or /register,
    // redirect to Home (/app/home).
    if (location == '/welcome' ||
        location == '/login' ||
        location == '/register') {
      return '/app/home';
    }

    return null;
  }
}

/// Riverpod provider for GoRouter with auth guards.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Root redirect
      GoRoute(path: '/', redirect: (context, state) => '/welcome'),

      // Welcome / Splash Route
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Card edit outside bottom nav
      GoRoute(
        path: '/app/cards/:cardId/edit',
        builder: (context, state) {
          final cardId = state.pathParameters['cardId'];
          return FlashcardFormScreen(cardId: cardId);
        },
      ),

      // Study session (1 deck, max 20 cards) outside bottom nav for focus
      GoRoute(
        path: '/app/study/session/:deckId',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId'] ?? 'default';
          return StudySessionScreen(deckId: deckId);
        },
      ),

      // Study session summary outside bottom nav
      GoRoute(
        path: '/app/study/summary/:deckId',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId'] ?? 'default';
          final countStr = state.uri.queryParameters['count'] ?? '20';
          final count = int.tryParse(countStr) ?? 20;
          return StudySummaryScreen(deckId: deckId, count: count);
        },
      ),

      // Main App Shell with Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1: Decks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/decks',
                builder: (context, state) => const DeckListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const DeckFormScreen(),
                  ),
                  GoRoute(
                    path: ':deckId',
                    builder: (context, state) {
                      final deckId = state.pathParameters['deckId']!;
                      return DeckDetailScreen(deckId: deckId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final deckId = state.pathParameters['deckId'];
                          return DeckFormScreen(deckId: deckId);
                        },
                      ),
                      GoRoute(
                        path: 'cards/new',
                        builder: (context, state) {
                          final deckId = state.pathParameters['deckId'];
                          return FlashcardFormScreen(deckId: deckId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Study (Deck Picker)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/study',
                builder: (context, state) => const StudyDeckPickerScreen(),
              ),
            ],
          ),

          // Tab 3: Stats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),

          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
