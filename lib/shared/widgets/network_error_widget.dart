import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const NetworkErrorWidget({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // On vérifie si c'est une erreur d'internet
    final isNetworkError = error.contains('SocketException') || error.contains('Failed host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? 'Pas de connexion internet' : 'Une erreur est survenue',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isNetworkError
                  ? 'Connectez-vous à internet pour charger ces données pour la première fois.'
                  : error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}