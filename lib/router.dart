import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/employees_screen.dart';
import 'features/auth/presentation/screens/shop_settings_screen.dart';
import 'features/cash/presentation/screens/cash_screen.dart';
import 'features/products/presentation/screens/edit_product_screen.dart';
import 'features/reports/presentation/screens/monthly_report_screen.dart';
import 'features/sales/presentation/screens/sales_history_screen.dart';
import 'shared/widgets/main_layout.dart';
import 'features/auth/presentation/screens/first_password_screen.dart';
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
import 'core/providers/employees_provider.dart';
import 'core/providers/shop_settings_provider.dart';
import 'features/cycles/presentation/screens/create_cycle_screen.dart';
import 'features/cycles/presentation/screens/cycle_report_screen.dart';
import 'features/cycles/presentation/screens/cycle_sale_screen.dart';
import 'features/cycles/presentation/screens/cycles_hub_screen.dart';
import 'features/cycles/presentation/screens/loss_entry_screen.dart';
import 'features/cycles/presentation/screens/manage_units_screen.dart';
import 'features/inventory/presentation/screens/daily_takings_screen.dart';
import 'features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'features/inventory/presentation/screens/inventory_count_screen.dart';
import 'features/inventory/presentation/screens/declare_loss_screen.dart';
import 'features/inventory/presentation/screens/transfer_detail_screen.dart';
import 'features/inventory/presentation/screens/transfers_screen.dart';
import 'features/inventory/presentation/providers/stock_transfer_provider.dart';
import 'features/inventory/presentation/screens/inventory_hub_screen.dart';
import 'features/inventory/presentation/screens/inventory_report_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/current_shop_provider.dart';

// Clés nécessaires pour le ShellRoute
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Les deux écrans qu'on peut ouvrir sans être connecté.
const _routesAuth = {'/login', '/register'};

/// Les écrans réservés au patron.
///
/// '/inventory-report' y figure aussi : il donne le bénéfice et l'écart
/// inexpliqué, exactement ce que le bilan protège en mode simple.
const bossOnlyRoutes = {
  '/employees',
  '/bilan',
  '/activity-log',
  '/shop-settings',
  '/inventory-report',
  // Compter, c'est constater ce qui manque — donc pouvoir effacer la trace de
  // ce qu'on a pris. Un vendeur qui recompte jusqu'à tomber juste fait
  // disparaître un manquant sans que personne le sache. Demandé par le client
  // le 19/08/2026, et cohérent avec `/inventory-report` déjà réservé.
  '/inventory-count',
};

/// L'écran où le vendeur remplace le mot de passe provisoire de son patron.
const routePremierMotDePasse = '/first-password';

/// La route à imposer, ou `null` si l'écran demandé est autorisé.
///
/// Sortie du `redirect` pour être testable : c'est la seule barrière de
/// l'application. Cacher un bouton dans l'interface ne protège rien — une
/// route reste atteignable par un lien direct ou un retour d'historique.
String? routeImposee({
  required bool connecte,
  required bool doitChangerMotDePasse,
  required bool accesPatron,
  required String emplacement,
}) {
  final surAuth = _routesAuth.contains(emplacement);

  if (!connecte) return surAuth ? null : '/login';

  // Avant tout le reste : un mot de passe provisoire n'ouvre rien d'autre que
  // l'écran qui sert à le remplacer. Placé après le renvoi vers '/home', la
  // redirection fonctionnait encore — mais en deux sauts, et l'accueil avait
  // le temps de lancer ses chargements pour un compte qui n'entre pas encore.
  if (doitChangerMotDePasse) {
    return emplacement == routePremierMotDePasse ? null : routePremierMotDePasse;
  }

  // Mot de passe déjà choisi : cet écran n'a plus lieu d'être.
  if (surAuth || emplacement == routePremierMotDePasse) return '/home';

  if (bossOnlyRoutes.contains(emplacement) && !accesPatron) return '/profile';
  return null;
}

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',

  redirect: (context, state) => routeImposee(
    connecte: Supabase.instance.client.auth.currentSession != null,
    doitChangerMotDePasse: doitChangerMotDePasse(),
    accesPatron: bossModeAccess.value,
    emplacement: state.matchedLocation,
  ),

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
      path: routePremierMotDePasse,
      // `extra` n'est conservé que si l'on est arrivé ici par une navigation
      // explicite depuis la connexion. Une redirection le perd, et une
      // redirection venue d'un autre écran pourrait y laisser tout autre
      // chose : on ne le lit que si c'est bien un texte.
      builder: (context, state) => FirstPasswordScreen(
        motDePasseProvisoire: state.extra is String
            ? state.extra as String
            : null,
      ),
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
    // Placeholders : le hub y renvoie déjà, mais les écrans arrivent (B3, B6).
    // Sans route déclarée, un clic ferait planter la navigation.
    GoRoute(
      path: '/inventory-count',
      builder: (context, state) => const InventoryCountScreen(),
    ),
    GoRoute(
      path: '/employees',
      builder: (context, state) => const EmployeesScreen(),
    ),
    GoRoute(
      path: '/transfers',
      builder: (context, state) => const TransfersScreen(),
    ),
    GoRoute(
      path: '/transfer-detail',
      builder: (context, state) =>
          TransferDetailScreen(entree: state.extra as TransferEntry),
    ),
    GoRoute(
      path: '/declare-loss',
      builder: (context, state) => const DeclareLossScreen(),
    ),
    GoRoute(
      path: '/daily-takings',
      builder: (context, state) => const DailyTakingsScreen(),
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
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryHubScreen(),
        ),
        // Dans le ShellRoute, donc AVEC la barre du bas : le rapport est une
        // destination, pas un écran de détail. Déclaré à l'extérieur, le
        // bouton retour quittait l'application et rien ne permettait de
        // rejoindre Accueil, Stock ou Inventaire.
        GoRoute(
          path: '/inventory-report',
          builder: (context, state) => const InventoryReportScreen(),
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
    // Ne rien deviner tant que le mode est inconnu. En repli sur le mode
    // simple pendant le chargement, `DashboardScreen` se construisait — et son
    // initState ouvrait aussitôt la boîte « fonds de caisse », qui restait à
    // l'écran même une fois l'accueil inventaire affiché. Une boîte de
    // dialogue est une route : elle survit au widget qui l'a ouverte.
    // Aucune boutique = on ne sait pas encore, ou on est en train de se
    // déconnecter (les préférences viennent d'être vidées). Dans les deux cas
    // il ne faut rien construire : l'accueil simple ouvrirait la boîte
    // « fonds de caisse », qui apparaissait une seconde en pleine
    // déconnexion.
    final boutiqueAsync = ref.watch(currentShopIdProvider);
    // Tant qu'on cherche, écran neutre. Une fois la recherche finie sans
    // résultat — hors ligne au tout premier lancement — on affiche l'accueil
    // simple plutôt que de laisser tourner un cercle sans fin.
    if (boutiqueAsync.isLoading) return const _EcranNeutre();
    final boutique = boutiqueAsync.value;
    if (boutique == null || boutique.isEmpty) return const DashboardScreen();

    return ref
        .watch(shopSettingsProvider)
        .when(
          loading: () => const _EcranNeutre(),
          error: (_, _) => const DashboardScreen(),
          // Mode inconnu = on attend. Parier sur « simple » faisait apparaître
          // la boîte « fonds de caisse » avant de basculer en inventaire, et
          // elle restait affichée par-dessus.
          data: (settings) => !settings.connu
              ? const _EcranNeutre()
              : settings.saleCaptureMode == 'periodic'
              ? const InventoryDashboardScreen()
              : const DashboardScreen(),
        );
  }
}

/// Le temps de savoir quoi afficher. Volontairement muet : un message
/// « chargement » qui clignote une demi-seconde inquiète plus qu'il n'informe.
class _EcranNeutre extends StatelessWidget {
  const _EcranNeutre();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}
