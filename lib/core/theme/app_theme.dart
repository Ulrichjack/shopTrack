

import 'package:flutter/material.dart';
import 'package:shoptrack/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme{
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
           error: AppColors.error
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );

   }
}