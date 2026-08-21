import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../../shared/widgets/shop_switcher.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 👇 1. LA VARIABLE MANQUANTE EST ICI
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlerts();
    });
  }

  void _checkAlerts() {
    // Rappelé après un `await` (clôture en retard validée) : le commerçant a
    // pu changer de boutique pendant l'attente, ce qui détruit cet écran.
    // `ref.read` sur un widget détruit lève « Cannot use "ref" after the
    // widget was disposed » — vu en test le 19/08/2026 en changeant de
    // boutique juste après avoir validé une clôture en retard.
    if (!mounted) return;

    // 👇 2. SÉCURITÉ : Si une boîte est déjà ouverte, on ne fait rien
    if (_isDialogOpen) return;

    // Deuxième garde, en ceinture et bretelles : la caisse et la clôture
    // journalière n'existent pas en inventaire périodique. Le routeur ne
    // construit plus cet écran dans ce mode, mais une boîte ouverte ici
    // survivrait à l'écran lui-même — donc on refuse aussi de ce côté.
    if (ref.read(shopSettingsProvider).value?.saleCaptureMode == 'periodic') {
      return;
    }

    final state = ref.read(dashboardProvider);
    state.whenData((data) {
      if (data.needsPreviousDayClosing && data.dateToClose != null) {
        setState(() => _isDialogOpen = true);
        _showForceClosingDialog(data.dateToClose!);
      } else if (!data.isClosed && !data.hasMorningBalance) {
        // On teste « a-t-on saisi ? », pas « le montant vaut-il 0 ? » :
        // une caisse vide le matin est un 0 parfaitement valide.
        setState(() => _isDialogOpen = true);
        _showMorningBalanceDialog();
      }
    });
  }

  void _showForceClosingDialog(DateTime dateToClose) {
    final dateStr = DateFormat('dd/MM/yyyy').format(dateToClose);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Clôture manquante !',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Tu as oublié de clôturer la caisse pour la journée du $dateStr.\n\n'
            'Tu dois absolument faire le comptage de cette journée avant de pouvoir enregistrer de nouvelles ventes.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showQuickClosingDialog(dateToClose);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Clôturer maintenant',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickClosingDialog(DateTime dateToClose) {
    final controller = TextEditingController();

    // Même raison que pour le fonds de caisse : la boîte survit à l'écran.
    final conteneur = ProviderScope.containerOf(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Comptage Physique'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Combien d\'argent y avait-il dans la caisse à la fin du ${DateFormat('dd/MM').format(dateToClose)} ?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant compté (FCFA)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null) {
                  Navigator.pop(context);
                  if (mounted) setState(() => _isDialogOpen = false);
                  await conteneur
                      .read(dashboardProvider.notifier)
                      .closeDay(
                        amount,
                        'Clôture en retard',
                        specificDate: dateToClose,
                      );
                  _checkAlerts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Valider',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // isEdit : on corrige un solde déjà saisi (donc annulable), au lieu de la
  // toute première saisie de la journée qui reste obligatoire.
  void _showMorningBalanceDialog({
    double currentBalance = 0,
    bool isEdit = false,
  }) {
    final controller = TextEditingController(
      text: isEdit ? currentBalance.toInt().toString() : '',
    );

    // Le conteneur, capturé AVANT d'ouvrir la boîte.
    //
    // Une boîte de dialogue est une route : elle survit à l'écran qui l'a
    // ouverte. Si la boutique change pendant qu'elle est affichée, cet écran
    // est détruit — et `ref.read` lève « Cannot use "ref" after the widget was
    // disposed » au moment d'enregistrer. Le commerçant tape son fonds de
    // caisse, appuie sur Enregistrer, et rien ne part : l'exception tombe
    // avant l'écriture, sans le moindre message. Vu en vrai le 21/08/2026.
    final conteneur = ProviderScope.containerOf(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: isEdit,
      builder: (context) => AlertDialog(
        title: const Text('Solde de la caisse', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Combien y a-t-il dans le tiroir-caisse ce matin ?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              // Chiffres uniquement : « 20,000 » n'est pas reconnu par
              // `double.tryParse` et le bouton restait sans effet.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Montant en FCFA',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isDialogOpen = false); // Libère le verrou
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              final cleanText = controller.text.replaceAll(' ', '');
              final amount = double.tryParse(cleanText);

              // Un champ vide ou illisible ne doit pas laisser le bouton sans
              // effet : le commerçant appuyait, rien ne se passait, et il ne
              // pouvait pas distinguer « enregistré » de « ignoré ».
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Saisis le montant qu\'il y a dans la caisse.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              conteneur
                  .read(dashboardProvider.notifier)
                  .saveMorningBalance(amount);
              Navigator.pop(context);
              // `mounted` : le verrou n'existe plus si l'écran a disparu.
              if (mounted) setState(() => _isDialogOpen = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReopenDay() async {
    // Capturé avant l'attente : au retour de la boîte, cet écran peut ne plus
    // exister.
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rouvrir la journée ?'),
        content: const Text(
          'Tu pourras de nouveau vendre aujourd\'hui.\n\n'
          'Le comptage déjà fait et son écart seront conservés dans la note '
          'de la journée. Il faudra recompter la caisse en refermant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Rouvrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await conteneur
          .read(dashboardProvider.notifier)
          .reopenDay(DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journée rouverte. Tu peux vendre à nouveau.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildStatCard(
    String title,
    String amount,
    IconData icon,
    Color color, {
    bool isLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isLarge ? 16 : 14,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: isLarge ? 28 : 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLarge ? 32 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isBossMode = ref.watch(appModeProvider).value ?? false;
    final isHierarchical =
        ref.watch(shopSettingsProvider).value?.unitMode == 'hierarchical';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Le nom de la boutique remplace celui de l'app dès qu'il y en a
        // plusieurs : le patron doit voir en permanence où il écrit.
        title: const ShopSwitcher(
          repli: Text(
            'ShopTrack',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dashboardAsync.when(
          skipError: true,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Journée clôturée. Aucune nouvelle vente ne peut être enregistrée aujourd\'hui.',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Un client qui arrive après la fermeture ne
                                // doit pas obliger à vendre hors de l'app.
                                if (isBossMode) ...[
                                  const SizedBox(height: 4),
                                  TextButton.icon(
                                    onPressed: _confirmReopenDay,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade900,
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(Icons.lock_open, size: 18),
                                    label: const Text('Rouvrir la journée'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Aujourd'hui",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: data.isClosed
                            ? null
                            : () {
                                setState(() => _isDialogOpen = true);
                                _showMorningBalanceDialog(
                                  currentBalance: data.morningBalance,
                                  isEdit: true,
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Matin : ${CurrencyFormatter.format(data.morningBalance)}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!data.isClosed) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildStatCard(
                    'Caisse Actuelle (Calculée)',
                    CurrencyFormatter.format(data.calculatedCash),
                    Icons.account_balance_wallet,
                    AppColors.primary,
                    isLarge: true,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      if (isBossMode)
                        Expanded(
                          child: _buildStatCard(
                            'Bénéfice Net',
                            CurrencyFormatter.format(data.netProfit),
                            Icons.trending_up,
                            AppColors.primaryDark,
                          ),
                        ),
                      if (isBossMode) const SizedBox(width: 16),

                      Expanded(
                        child: GestureDetector(
                          onTap: data.isClosed
                              ? null
                              : () => context.push('/cash-out'),
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

                  ElevatedButton.icon(
                    onPressed: data.isClosed
                        ? null
                        : () => context.push(
                            isHierarchical ? '/cycle-sale' : '/sales/new',
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.point_of_sale,
                      size: 32,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'NOUVELLE VENTE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () => context.push('/products'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.inventory_2,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Gérer mon stock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Consumer(
                    builder: (context, ref, child) {
                      final productsAsync = ref.watch(productProvider);

                      return productsAsync.when(
                        data: (products) {
                          final lowStockProducts = products
                              .where((p) => p.quantity <= p.minQuantity)
                              .toList();
                          if (lowStockProducts.isEmpty)
                            return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lowStockProducts.length} ALERTE${lowStockProducts.length > 1 ? 'S' : ''} STOCK BAS',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lowStockProducts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final product = lowStockProducts[index];
                                  final isOutOfStock = product.quantity <= 0;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOutOfStock
                                          ? Colors.red.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isOutOfStock
                                            ? Colors.red.shade200
                                            : Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? Colors.red.shade900
                                                  : Colors.orange.shade900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          isOutOfStock
                                              ? 'Rupture'
                                              : '${product.quantity} restants',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock
                                                ? Colors.red.shade700
                                                : Colors.orange.shade800,
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

                  const SizedBox(height: 40),

                  if (!data.isClosed && isBossMode)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/closing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.lock_clock, color: Colors.white),
                      label: const Text(
                        'Clôturer la journée',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
