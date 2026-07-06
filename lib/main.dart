import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const ShopTrackApp());
}

class ShopTrackApp extends StatelessWidget {
  const ShopTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Bienvenue dans ShopTrack')),
      ),
      theme:AppTheme.lightTheme,
    );
  }
}