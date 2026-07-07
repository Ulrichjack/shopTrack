// lib/router.dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- N'oublie pas cet import
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/login',

  // 👇 LA MAGIE EST ICI : Redirection automatique 👇
  redirect: (context, state) {
    // On vérifie si l'utilisateur a une session active dans Supabase
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    // On vérifie sur quel écran il essaie d'aller
    final isOnAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // S'il est connecté ET qu'il est sur la page login/register -> on l'envoie sur /home
    if (isLoggedIn && isOnAuth) return '/home';

    // S'il n'est PAS connecté ET qu'il essaie d'aller ailleurs que login/register -> on l'envoie sur /login
    if (!isLoggedIn && !isOnAuth) return '/login';

    return null; // Sinon, on le laisse passer normalement
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);