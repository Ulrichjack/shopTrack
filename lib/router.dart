// lib/router.dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- N'oublie pas cet import
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/products/domain/entities/product_entity.dart';
import 'features/products/presentation/screens/add_product_screen.dart';
import 'features/products/presentation/screens/barcode_scanner_screen.dart';
import 'features/products/presentation/screens/product_detail_screen.dart';
import 'features/products/presentation/screens/product_list_screen.dart';
import 'features/sales/presentation/screens/new_sale_screen.dart';
import 'features/sales/presentation/screens/sale_confirmation_screen.dart';

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
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) => const NewSaleScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const BarcodeScannerScreen(),
    ),
    GoRoute(
      path: '/product-detail',
      builder: (context, state) {
        final product = state.extra as ProductEntity;
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: '/sales/new',
      builder: (context, state) => const NewSaleScreen(),
    ),
    GoRoute(
      path: '/sale-confirm',
      builder: (context, state) => const SaleConfirmationScreen(),
    ),

  ],
);