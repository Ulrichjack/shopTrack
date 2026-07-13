import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 On importe Riverpod
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_mode_provider.dart';
import 'offline_banner.dart';

// 👈 On utilise ConsumerWidget à la place de StatelessWidget
class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  // 👈 On passe isBossMode pour sécuriser l'index
  int _calculateSelectedIndex(BuildContext context, bool isBossMode) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/sales-history')) return 1;
    if (location.startsWith('/products')) return 2;
    // Si c'est le vendeur (isBossMode = false), on force le retour à 0 pour éviter un crash
    if (location.startsWith('/bilan')) return isBossMode ? 3 : 0;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/sales-history');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/bilan');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 👈 On ajoute WidgetRef ref

    // 👈 ON LIT LE MODE ICI
    final isBossMode = ref.watch(appModeProvider).value ?? false;

    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: OfflineBanner()),
          Expanded(child: child),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context, isBossMode),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,

        // 👈 On enlève le "const" devant la liste car elle contient maintenant un "if"
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Ventes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),

          // 👇 C'EST ICI QU'ON CACHE LE BILAN 👇
          if (isBossMode)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Bilan',
            ),
        ],
      ),
    );
  }
}