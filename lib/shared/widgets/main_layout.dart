import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'offline_banner.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  // Cette fonction regarde sur quelle page on est pour allumer la bonne icône
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/sales-history')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/bilan')) return 3;
    return 0;
  }

  // Fonction quand on clique sur une icône
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: OfflineBanner()), // Le bandeau
          Expanded(child: child), // L'écran actuel (Dashboard, Stock, etc.)
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed, // Empêche les icônes de bouger bizarrement
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Bilan',
          ),
        ],
      ),
    );
  }
}