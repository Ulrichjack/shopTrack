import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/cash/presentation/screens/cash_screen.dart';
import 'features/products/presentation/screens/edit_product_screen.dart';
import 'features/reports/presentation/screens/monthly_report_screen.dart';
import 'features/sales/presentation/screens/sales_history_screen.dart';
import 'shared/widgets/main_layout.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dashboard/presentation/screens/closing_screen.dart';
import 'features/products/domain/entities/product_entity.dart';
import 'features/products/presentation/screens/add_product_screen.dart';
import 'features/products/presentation/screens/barcode_scanner_screen.dart';
import 'features/products/presentation/screens/product_detail_screen.dart';
import 'features/products/presentation/screens/product_list_screen.dart';
import 'features/sales/presentation/screens/new_sale_screen.dart';
import 'features/sales/presentation/screens/sale_confirmation_screen.dart';

// Clés nécessaires pour le ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (isLoggedIn && isOnAuth) return '/home';
    if (!isLoggedIn && !isOnAuth) return '/login';
    return null;
  },

  routes: [
    // --- ROUTES SANS BARRE DE NAVIGATION (Plein écran) ---
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/closing',
      builder: (context, state) => const ClosingScreen(),
    ),
    GoRoute(
      path: '/cash-out',
      builder: (context, state) => const CashScreen(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) => const AddProductScreen(),
    ),
    GoRoute(
      path: '/edit-product',
      builder: (context, state) {
        final product = state.extra as ProductEntity;
        return EditProductScreen(product: product);
      },
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

    // --- ROUTES AVEC LA BARRE DE NAVIGATION (ShellRoute) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child); // Ajoute la barre en bas
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
        ),

        // Écrans temporaires en attendant de les coder (Phase 9 et Historique)
        GoRoute(
          path: '/sales-history',
          builder: (context, state) => const SalesHistoryScreen(),        ),
        GoRoute(
          path: '/bilan',
          builder: (context, state) => const MonthlyReportScreen(),
        ),

      ],
    ),
  ],
);