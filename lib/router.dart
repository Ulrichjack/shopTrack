import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/shop_settings_screen.dart';
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
import 'core/audit/activity_log_screen.dart';
import 'core/sync/sync_status_screen.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/shop_settings_provider.dart';
import 'features/cycles/presentation/screens/create_cycle_screen.dart';
import 'features/cycles/presentation/screens/cycle_report_screen.dart';
import 'features/cycles/presentation/screens/cycle_sale_screen.dart';
import 'features/cycles/presentation/screens/cycles_hub_screen.dart';
import 'features/cycles/presentation/screens/loss_entry_screen.dart';
import 'features/cycles/presentation/screens/manage_units_screen.dart';
import 'features/inventory/presentation/screens/daily_takings_screen.dart';
import 'features/inventory/presentation/screens/inventory_dashboard_screen.dart';

// Clés nécessaires pour le ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (isLoggedIn && isOnAuth) return '/home';
    if (!isLoggedIn && !isOnAuth) return '/login';
    const bossOnlyRoutes = {'/bilan', '/activity-log', '/shop-settings'};
    if (isLoggedIn &&
        bossOnlyRoutes.contains(state.matchedLocation) &&
        !bossModeAccess.value) {
      return '/profile';
    }
    return null;
  },

  routes: [
    // --- ROUTES SANS BARRE DE NAVIGATION (Plein écran) ---
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/closing',
      builder: (context, state) => const ClosingScreen(),
    ),
    GoRoute(path: '/cash-out', builder: (context, state) => const CashScreen()),
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
      path: '/sync-status',
      builder: (context, state) => const SyncStatusScreen(),
    ),
    GoRoute(
      path: '/activity-log',
      builder: (context, state) => const ActivityLogScreen(),
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
    GoRoute(
      path: '/shop-settings',
      builder: (context, state) => const ShopSettingsScreen(),
    ),
    GoRoute(
      path: '/create-cycle',
      builder: (context, state) => const CreateCycleScreen(),
    ),
    GoRoute(
      path: '/manage-units',
      builder: (context, state) => const ManageUnitsScreen(),
    ),
    GoRoute(
      path: '/loss-entry',
      builder: (context, state) => const LossEntryScreen(),
    ),
    GoRoute(
      path: '/cycle-sale',
      builder: (context, state) => const CycleSaleScreen(),
    ),
    GoRoute(
      path: '/cycle-report',
      builder: (context, state) => const CycleReportScreen(),
    ),

    // --- ROUTES AVEC LA BARRE DE NAVIGATION (ShellRoute) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child); // Ajoute la barre en bas
      },
      routes: [
        // Deux accueils selon le mode : en inventaire périodique il n'y a ni
        // vente enregistrée ni caisse calculée, donc l'accueil classique
        // n'aurait que des zéros à montrer. Une condition ici plutôt que
        // vingt dans un écran déjà trop chargé.
        GoRoute(
          path: '/home',
          builder: (context, state) => const _HomeForShopMode(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
        ),

        // Écrans temporaires en attendant de les coder (Phase 9 et Historique)
        GoRoute(
          path: '/sales-history',
          builder: (context, state) => const SalesHistoryScreen(),
        ),
        GoRoute(
          path: '/cycles',
          builder: (context, state) => const CyclesHubScreen(),
        ),
        // Module B. Deviendra un tableau de bord d'inventaire quand le
        // comptage et le rapport existeront ; pour l'instant la recette
        // journalière est la seule saisie du module.
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const DailyTakingsScreen(),
        ),
        GoRoute(
          path: '/bilan',
          builder: (context, state) => const MonthlyReportScreen(),
        ),
      ],
    ),
  ],
);

/// Choisit l'accueil selon le mode de saisie de la boutique.
class _HomeForShopMode extends ConsumerWidget {
  const _HomeForShopMode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodic =
        ref.watch(shopSettingsProvider).value?.saleCaptureMode == 'periodic';
    return periodic
        ? const InventoryDashboardScreen()
        : const DashboardScreen();
  }
}
