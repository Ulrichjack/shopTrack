import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On écoute l'état du réseau
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    // Si on a internet, on ne dessine rien (SizedBox.shrink = widget invisible)
    if (isOnline) return const SizedBox.shrink();

    // Si on n'a pas internet, on affiche un bandeau orange
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Text(
        'Mode hors-ligne - Les ventes sont sauvegardées dans le téléphone',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}