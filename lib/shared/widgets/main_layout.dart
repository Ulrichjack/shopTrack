import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 On importe Riverpod
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/shop_settings_provider.dart';
import 'offline_banner.dart';

// 👈 On utilise ConsumerWidget à la place de StatelessWidget
class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 👈 On ajoute WidgetRef ref

    // 👈 ON LIT LE MODE ICI
    final isBossMode = ref.watch(appModeProvider).value ?? false;
    // Mode de la boutique : ajoute l'onglet Cycles pour les boutiques qui
    // vendent par unités (œufs, casiers...) — voir docs/ARCHITECTURE_MODULES.md
    final settings = ref.watch(shopSettingsProvider).value;
    final isHierarchical = settings?.unitMode == 'hierarchical';
    final isPeriodic = settings?.saleCaptureMode == 'periodic';

    // Un seul endroit décide des onglets ET de leur ordre : impossible que
    // l'index tapé et l'index surligné se désynchronisent quand un onglet
    // apparaît ou disparaît selon le mode.
    final destinations = <_NavDestination>[
      const _NavDestination(
        route: '/home',
        label: 'Accueil',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      const _NavDestination(
        route: '/sales-history',
        label: 'Ventes',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
      ),
      const _NavDestination(
        route: '/products',
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
      ),
      if (isHierarchical)
        const _NavDestination(
          route: '/cycles',
          label: 'Cycles',
          icon: Icons.autorenew_outlined,
          activeIcon: Icons.autorenew,
        ),
      if (isPeriodic)
        const _NavDestination(
          route: '/inventory',
          label: 'Recette',
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments,
        ),
      if (isBossMode)
        const _NavDestination(
          route: '/bilan',
          label: 'Bilan',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
        ),
    ];

    final location = GoRouterState.of(context).matchedLocation;
    final matchedIndex = destinations.indexWhere(
      (destination) => location.startsWith(destination.route),
    );
    // Onglet masqué dans ce mode (ex: /bilan pour un vendeur) : on retombe
    // sur Accueil plutôt que de planter avec un index hors liste.
    final selectedIndex = matchedIndex >= 0 ? matchedIndex : 0;

    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: OfflineBanner()),
          Expanded(child: child),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => context.go(destinations[index].route),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: destinations
            .map(
              (destination) => BottomNavigationBarItem(
                icon: Icon(destination.icon),
                activeIcon: Icon(destination.activeIcon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}