import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Le rouage des réglages, à poser dans l'en-tête de tout écran de la barre.
///
/// Il vivait sur le seul accueil : depuis le stock ou les commandes, il fallait
/// revenir en arrière pour l'atteindre. Un réglage se cherche rarement, mais
/// quand on le cherche c'est depuis l'écran où on vient de buter — pas depuis
/// l'accueil.
///
/// En haut plutôt qu'en bas : la barre du bas porte déjà cinq destinations, et
/// un sixième onglet tronquait les libellés sur un petit téléphone. Un réglage
/// se touche une fois au départ, il n'a pas à occuper une place permanente à
/// côté des gestes quotidiens.
class BoutonReglages extends StatelessWidget {
  const BoutonReglages({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Réglages',
      onPressed: () => context.push('/profile'),
    );
  }
}
