import 'package:flutter/material.dart';

enum WebPage { accueil, stock, journal, caisse, bilan, employes, cycles, inventaire, commandes }

class WebDestination {
  const WebDestination(this.page, this.label, this.icon, this.selectedIcon);
  final WebPage page;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Même structure métier que la navigation Android : inventaire remplace le
/// journal des ventes, cycles est réservé au propriétaire, commandes s'ajoute.
List<WebDestination> destinationsWeb({
  required bool inventairePeriodique,
  required bool cyclesActifs,
  required bool commandesActives,
  required bool estPatron,
}) => [
  const WebDestination(
    WebPage.accueil,
    'Accueil',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard,
  ),
  if (!inventairePeriodique)
    const WebDestination(
      WebPage.journal,
      'Journal',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
    ),
  if (!inventairePeriodique && !cyclesActifs)
    const WebDestination(
      WebPage.caisse,
      'Caisse',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
    ),
  const WebDestination(
    WebPage.stock,
    'Stock',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
  ),
  if (estPatron)
    const WebDestination(
      WebPage.bilan,
      'Bilan',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
    ),
  if (estPatron && !inventairePeriodique && !cyclesActifs)
    const WebDestination(
      WebPage.employes,
      'Employés',
      Icons.group_outlined,
      Icons.group,
    ),
  if (cyclesActifs && estPatron)
    const WebDestination(
      WebPage.cycles,
      'Cycles',
      Icons.autorenew_outlined,
      Icons.autorenew,
    ),
  if (inventairePeriodique)
    const WebDestination(
      WebPage.inventaire,
      'Inventaire',
      Icons.fact_check_outlined,
      Icons.fact_check,
    ),
  if (commandesActives)
    const WebDestination(
      WebPage.commandes,
      'Commandes',
      Icons.assignment_outlined,
      Icons.assignment,
    ),
];
