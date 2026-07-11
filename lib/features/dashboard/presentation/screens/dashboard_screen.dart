import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  // Cette fonction s'exécute juste après que l'écran soit dessiné
  @override
  void initState() {
    super.initState();
    // On attend un tout petit peu que Riverpod charge les données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMorningBalance();
    });
  }

  // Vérifie si on doit afficher la popup du solde du matin
  void _checkMorningBalance() {
    final state = ref.read(dashboardProvider);
    state.whenData((data) {
      // Si la journée n'est pas clôturée ET que le solde du matin est à 0
      if (!data.isClosed && data.morningBalance == 0) {
        _showMorningBalanceDialog();
      }
    });
  }

  // La fameuse popup du matin (maintenant modifiable)
  void _showMorningBalanceDialog({double currentBalance = 0}) {
    // Si on a déjà un solde, on le pré-remplit dans le champ
    final controller = TextEditingController(
      text: currentBalance > 0 ? currentBalance.toInt().toString() : '',
    );

    showDialog(
      context: context,
      barrierDismissible: currentBalance > 0, // On peut fermer en cliquant à côté SEULEMENT si on a déjà un solde
      builder: (context) => AlertDialog(
        title: const Text('Solde de la caisse', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Combien y a-t-il dans le tiroir-caisse ce matin ?', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant en FCFA',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // Bouton Annuler (visible uniquement si on modifie un solde existant)
          if (currentBalance > 0)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),

          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                ref.read(dashboardProvider.notifier).saveMorningBalance(amount);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Petit widget pour dessiner les cartes
  Widget _buildStatCard(String title, String amount, IconData icon, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isLarge ? 16 : 14)),
              Icon(icon, color: Colors.white.withOpacity(0.8), size: isLarge ? 28 : 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(amount, style: TextStyle(color: Colors.white, fontSize: isLarge ? 32 : 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ShopTrack', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dashboardAsync.when(
          skipError: true, // 👈 LA MAGIE EST ICI : Si on a déjà les données, on ignore l'erreur réseau !
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => NetworkErrorWidget(
            error: err.toString(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ... (Garde ton code existant pour le bandeau rouge "Journée clôturée") ...
                  if (data.isClosed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Journée clôturée. Aucune nouvelle vente ne peut être enregistrée aujourd\'hui.',
                              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Aujourd'hui", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      // Petit badge gris pour le solde du matin (CLIQUABLE)
                      GestureDetector(
                        onTap: data.isClosed ? null : () => _showMorningBalanceDialog(currentBalance: data.morningBalance),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Text('Matin : ${CurrencyFormatter.format(data.morningBalance)}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              if (!data.isClosed) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grande carte : CAISSE CALCULÉE
                  _buildStatCard(
                    'Caisse Actuelle (Calculée)',
                    CurrencyFormatter.format(data.calculatedCash),
                    Icons.account_balance_wallet,
                    AppColors.primary,
                    isLarge: true,
                  ),
                  const SizedBox(height: 16),

                  // Deux petites cartes : Bénéfice net et Sorties
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Bénéfice Net',
                          CurrencyFormatter.format(data.netProfit),
                          Icons.trending_up,
                          AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: data.isClosed ? null : () => context.push('/cash-out'),
                          child: _buildStatCard(
                            'Sorties',
                            CurrencyFormatter.format(data.totalWithdrawals),
                            Icons.money_off,
                            Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Bouton Nouvelle Vente
                  ElevatedButton.icon(
                    onPressed: data.isClosed ? null : () => context.push('/sales/new'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.point_of_sale, size: 32, color: Colors.white),
                    label: const Text('NOUVELLE VENTE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                  const SizedBox(height: 16),

                  // Bouton Gérer le stock
                  OutlinedButton.icon(
                    onPressed: () => context.push('/products'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.inventory_2, color: AppColors.primary),
                    label: const Text('Gérer mon stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),

                  const SizedBox(height: 40),

                  // 👇 NOUVEAU : SECTION ALERTES STOCK BAS 👇
                  Consumer(
                    builder: (context, ref, child) {
                      final productsAsync = ref.watch(productProvider);

                      return productsAsync.when(
                        data: (products) {
                          // On filtre les produits en alerte (quantité <= minQuantity)
                          final lowStockProducts = products.where((p) => p.quantity <= p.minQuantity).toList();

                          if (lowStockProducts.isEmpty) return const SizedBox.shrink(); // Rien à afficher si tout va bien

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lowStockProducts.length} ALERTE${lowStockProducts.length > 1 ? 'S' : ''} STOCK BAS',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 12),

                              // Liste des alertes
                              ListView.separated(
                                shrinkWrap: true, // Important pour mettre une ListView dans une ScrollView
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lowStockProducts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final product = lowStockProducts[index];
                                  final isOutOfStock = product.quantity <= 0;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isOutOfStock ? Colors.red.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isOutOfStock ? Colors.red.shade200 : Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock ? Colors.red.shade900 : Colors.orange.shade900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          isOutOfStock ? 'Rupture' : '${product.quantity} restants',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock ? Colors.red.shade700 : Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  // 👆 FIN SECTION ALERTES 👆

                  const SizedBox(height: 40),

                  // Bouton Clôturer la journée
                  if (!data.isClosed)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/closing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800, // Couleur sérieuse
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock_clock, color: Colors.white),
                      label: const Text(
                          'Clôturer la journée',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}