import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/earnings/earnings_screen.dart';
import 'features/home/worker_home_screen.dart';
import 'features/jobs/active_job_screen.dart';
import 'features/jobs/job_history_screen.dart';
import 'features/profile/worker_profile_screen.dart';
import 'features/ratings/ratings_screen.dart';
import 'features/schedule/calendar_screen.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ---- Auth routes ----
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ---- Shell with bottom nav ----
      ShellRoute(
        builder: (context, state, child) {
          return _WorkerShell(child: child, location: state.matchedLocation);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const WorkerHomeScreen(),
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobHistoryScreen(),
          ),
          GoRoute(
            path: '/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const WorkerProfileScreen(),
          ),
        ],
      ),

      // ---- Detail routes (outside shell) ----
      GoRoute(
        path: '/job/:ref',
        builder: (context, state) {
          final ref = state.pathParameters['ref']!;
          return ActiveJobScreen(bookingRef: ref);
        },
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final jobRef = state.pathParameters['ref']!;
              return ChatScreen(bookingRef: jobRef);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/ratings',
        builder: (context, state) => const RatingsScreen(),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Shell scaffold with bottom nav
// ---------------------------------------------------------------------------

class _WorkerShell extends StatelessWidget {
  const _WorkerShell({required this.child, required this.location});

  final Widget child;
  final String location;

  int _currentIndex(String location) {
    if (location.startsWith('/jobs')) return 1;
    if (location.startsWith('/earnings')) return 2;
    if (location.startsWith('/schedule')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: WorkerColors.accent,
        unselectedItemColor: WorkerColors.textMuted,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/jobs');
              break;
            case 2:
              context.go('/earnings');
              break;
            case 3:
              context.go('/schedule');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house_outlined),
            activeIcon: Icon(Icons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_outlined),
            activeIcon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Root app widget
// ---------------------------------------------------------------------------

class WorkerApp extends ConsumerWidget {
  const WorkerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'HizmatAI Worker',
      debugShowCheckedModeBanner: false,
      theme: WorkerTheme.light,
      routerConfig: router,
    );
  }
}
