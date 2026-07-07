// lib/router.dart
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

// On crée notre routeur global
final goRouter = GoRouter(
  initialLocation: '/login', // L'écran de départ
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);