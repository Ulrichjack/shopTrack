import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Ajoute cet import
import 'package:shoptrack/features/auth/presentation/screens/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  // 2. Enveloppe ton app dans le ProviderScope
  runApp(const ProviderScope(child: ShopTrackApp()));
}

class ShopTrackApp extends StatelessWidget {
  const ShopTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Bonus : ça enlève le moche bandeau "DEBUG" en haut à droite
      home: const LoginScreen(),
      theme: AppTheme.lightTheme,
    );
  }
}