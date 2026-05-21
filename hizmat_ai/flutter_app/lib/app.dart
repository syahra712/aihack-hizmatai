import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/role_selector_screen.dart';
import 'features/home/home_screen.dart';
import 'features/booking/booking_history_screen.dart';
import 'features/booking/booking_confirmation_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/saved_addresses_screen.dart';
import 'features/worker/worker_phone_login_screen.dart';
import 'features/worker/worker_register_screen.dart';
import 'features/worker/worker_home_screen.dart';
import 'services/firebase_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter _buildRouter(User? authUser) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (_, __) => const RoleSelectorScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // ── Worker auth + home ──────────────────────────────────────────
      GoRoute(
        path: '/worker-login',
        builder: (_, __) => const WorkerPhoneLoginScreen(),
      ),
      GoRoute(
        path: '/worker-register',
        builder: (_, __) => const WorkerRegisterScreen(),
      ),
      GoRoute(
        path: '/worker-home',
        builder: (_, __) => const WorkerHomeScreen(),
      ),

      // ── Booking confirmation (full-screen overlay) ──────────────────
      GoRoute(
        path: '/booking-confirmation/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => BookingConfirmationScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // ── Customer shell (bottom nav) ─────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/bookings',
              builder: (_, __) => const BookingHistoryScreen()),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'addresses',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const SavedAddressesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class HizmatApp extends ConsumerWidget {
  const HizmatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final router = authAsync.when(
      data: (user) => _buildRouter(user),
      loading: () => _buildRouter(null),
      error: (_, __) => _buildRouter(null),
    );

    return MaterialApp.router(
      title: 'Hizmat AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/bookings')) return 1;
    if (loc.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), offset: const Offset(0, -4), blurRadius: 20),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/bookings');
              case 2: context.go('/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
