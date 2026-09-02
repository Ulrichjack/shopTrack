import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/bouton_reglages.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/domain/entities/daily_closing_entity.dart';
import '../../../../core/sync/sync_service.dart'; // 👈 AJOUT POUR LA SYNCHRO
import '../../../commandes/presentation/providers/bilan_commandes_provider.dart';
import '../providers/monthly_report_provider.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _previousMonth() => setState(
    () => _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    ),
  );
  void _nextMonth() => setState(
    () => _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    ),
  );

  // --- WIDGETS UI ---

  Widget _buildTopCard(
    String title,
    double amount,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekBar(String label, double amount, double maxAmount) {
    final double percent = maxAmount > 0 ? (amount / maxAmount) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- GÉNÉRATION DU PDF ---

  /// Une ligne « libellé …… montant » du bloc commandes.
  static pw.Widget _lignePdf(
    String libelle,
    int montant, {
    String suffixe = '',
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(libelle, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Text(
            '$montant FCFA$suffixe',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(
    MonthlyReportState report,
    String monthName, {
    BilanCommandes? commandes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ShopTrack - Récapitulatif des Ventes',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Période : $monthName',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 24),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfSummaryBox('Vente Réalisée', report.totalSales),
                  _buildPdfSummaryBox('Dépenses', report.totalWithdrawals),
                  _buildPdfSummaryBox(
                    'Bénéfice Net',
                    report.totalNetProfit,
                    isGreen: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfSummaryBox('Manques caisse', report.totalShortage),
                  _buildPdfSummaryBox('Surplus caisse', report.totalSurplus),
                  _buildPdfSummaryBox(
                    'Résultat ajusté',
                    report.cashAdjustedResult,
                    isGreen: report.cashAdjustedResult >= 0,
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              pw.Text(
                'Détail par jour',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Date',
                  'Achat',
                  'Vente',
                  'Dépenses',
                  'Écart caisse',
                  'Marge nette',
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1D9E75),
                ),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {0: pw.Alignment.centerLeft},
                data: report.dailyClosings.map((closing) {
                  final dateStr = DateFormat(
                    'dd/MM/yyyy',
                  ).format(closing.closingDate);
                  final coutAchat = closing.totalSales - closing.grossProfit;
                  return [
                    dateStr,
                    CurrencyFormatter.format(coutAchat),
                    CurrencyFormatter.format(closing.totalSales),
                    CurrencyFormatter.format(closing.totalWithdrawals),
                    CurrencyFormatter.format(closing.cashGap ?? 0),
                    CurrencyFormatter.format(closing.netProfit),
                  ];
                }).toList(),
              ),
              // Les journées annotées (réouverture, clôture tardive) doivent
              // suivre le PDF : c'est ce document que le patron relit ou
              // transmet, et un écart s'y explique.
              if (report.dailyClosings.any(
                (c) => (c.note?.trim() ?? '').isNotEmpty,
              )) ...[
                pw.SizedBox(height: 24),
                pw.Text(
                  'Journées annotées',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...report.dailyClosings
                    .where((c) => (c.note?.trim() ?? '').isNotEmpty)
                    .map(
                      (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              DateFormat('dd/MM/yyyy').format(c.closingDate),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              c.note!.trim(),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],

              // Le bloc COMMANDES, ajouté seulement s'il y a quelque chose à
              // dire. Une boutique sans commandes garde exactement le PDF
              // qu'elle avait — pas un encadré vide de plus.
              if (commandes != null && !commandes.estVide) ...[
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green700, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COMMANDES — ${commandes.nombreLivrees} livrée(s)',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _lignePdf(
                        'Chiffre d\'affaires',
                        commandes.chiffreAffaires,
                      ),
                      _lignePdf('Ce que ça a coûté', commandes.cout),
                      pw.Divider(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Bénéfice des commandes',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            commandes.benefice == null
                                ? 'coût non saisi'
                                : '${commandes.benefice} FCFA',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      // L'avertissement voyage AVEC le chiffre. Un PDF est
                      // photographié, renvoyé, relu des mois plus tard : sans
                      // cette phrase, un bénéfice partiel deviendrait une
                      // vérité imprimée.
                      if (commandes.livreesSansCout > 0) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '${commandes.livreesSansCout} commande(s) livrée(s) '
                          'sans coût saisi : ce bénéfice est plus beau que le '
                          'vrai.',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.orange800,
                          ),
                        ),
                      ],
                      if (commandes.encoreDu > 0) ...[
                        pw.SizedBox(height: 8),
                        _lignePdf(
                          'Encore dû par les clientes (attendu)',
                          commandes.encoreDu,
                        ),
                        // Le PDF circule seul et se lit loin de l'application :
                        // le total sans les noms ne permet de relancer
                        // personne.
                        for (final cliente in commandes.debitrices.take(10))
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10),
                            child: _lignePdf(
                              cliente.livree
                                  ? '${cliente.nom} (déjà livrée)'
                                  : cliente.nom,
                              cliente.montant,
                            ),
                          ),
                      ],
                      if (commandes.semaines.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'SEMAINE PAR SEMAINE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        for (final semaine in commandes.semaines)
                          _lignePdf(
                            'Du ${DateFormat('dd/MM').format(semaine.debut)} '
                            'au ${DateFormat('dd/MM').format(semaine.fin)} · '
                            '${semaine.nombreLivrees} livrée(s)',
                            semaine.benefice ?? semaine.chiffreAffaires,
                            suffixe: semaine.benefice == null
                                ? ' (coût non saisi)'
                                : '',
                          ),
                      ],
                    ],
                  ),
                ),
              ],

              // Le document circule seul, souvent photographié ou renvoyé :
              // il doit dire d'où il vient et de quand il date.
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'Généré automatiquement par ShopTrack · '
                  '${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bilan_ShopTrack_$monthName.pdf',
    );
  }

  pw.Widget _buildPdfSummaryBox(
    String title,
    double amount, {
    bool isGreen = false,
  }) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: isGreen ? PdfColors.green700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Détail d'une journée : le tableau ne montre que l'écart, pas les deux
  /// montants qui le produisent. Trois semaines plus tard, « +2 447 F » ne
  /// veut plus rien dire sans savoir ce qui avait été compté.
  void _showClosingDetail(
    BuildContext context,
    String dateStr,
    DailyClosingEntity closing,
  ) {
    final gap = closing.cashGap ?? 0;
    final note = closing.note?.trim() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Journée du $dateStr'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailLine('Caisse attendue', closing.calculatedCash),
              _detailLine('Caisse comptée', closing.physicalCash ?? 0),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gap == 0 ? 'Écart' : (gap < 0 ? 'Manquant' : 'Surplus'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.format(gap),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: gap < 0
                          ? Colors.red
                          : (gap > 0 ? Colors.blue : Colors.green),
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(note, style: const TextStyle(height: 1.4)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(CurrencyFormatter.format(amount)),
        ],
      ),
    );
  }

  // --- BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(_selectedMonth));
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth);
    final capitalizedMonth =
        "${monthName[0].toUpperCase()}${monthName.substring(1)}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bilan — $capitalizedMonth',
          style: const TextStyle(fontSize: 18),
        ),
        elevation: 0,
        actions: [
          reportAsync.maybeWhen(
            data: (report) => IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: report.dailyClosings.isEmpty
                  ? null
                  : () => _generatePdf(
                      report,
                      capitalizedMonth,
                      commandes: ref
                          .read(bilanCommandesProvider(_selectedMonth))
                          .value,
                    ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const BoutonReglages(),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de mois
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _previousMonth,
                ),
                Text(
                  capitalizedMonth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed:
                      _selectedMonth.month == DateTime.now().month &&
                          _selectedMonth.year == DateTime.now().year
                      ? null
                      : _nextMonth,
                ),
              ],
            ),
          ),

          // Contenu avec RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // 1. Force le téléchargement depuis Supabase (au cas où)
                await ref.read(syncServiceProvider).pullDataFromSupabase();
                // 2. Rafraîchit l'affichage local
                ref.invalidate(monthlyReportProvider(_selectedMonth));
              },
              child: reportAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => ListView(
                  // 👈 ListView permet de "tirer" même s'il y a une erreur
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(child: Text('Erreur: $err')),
                    ),
                  ],
                ),
                data: (report) {
                  if (report.dailyClosings.isEmpty) {
                    return ListView(
                      // 👈 ListView permet de "tirer" même si c'est vide !
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const Center(
                            child: Text(
                              'Aucune donnée pour ce mois.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // --- Calcul des Ventes par Semaine ---
                  List<double> weeklySales = [0, 0, 0, 0];
                  for (var closing in report.dailyClosings) {
                    int day = closing.closingDate.day;
                    if (day <= 7)
                      weeklySales[0] += closing.totalSales;
                    else if (day <= 14)
                      weeklySales[1] += closing.totalSales;
                    else if (day <= 21)
                      weeklySales[2] += closing.totalSales;
                    else
                      weeklySales[3] += closing.totalSales;
                  }
                  double maxWeekSale = weeklySales.reduce(max);

                  return SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // 👈 Obligatoire pour le RefreshIndicator
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _buildTopCard(
                              'Encaissé',
                              report.totalSales,
                              AppColors.primaryLight,
                              AppColors.primaryDark,
                            ),
                            const SizedBox(width: 12),
                            _buildTopCard(
                              'Bénéfice net',
                              report.totalNetProfit,
                              AppColors.success,
                              AppColors.successDark,
                            ),
                          ],
                        ),

                        // Le mois inclut des journées dont le tiroir n'a
                        // jamais été compté.
                        //
                        // Leurs ventes sont réelles et comptent dans les
                        // totaux — l'argent est bien entré. Mais personne n'a
                        // vérifié la caisse ce jour-là : le chiffre est exact
                        // sur ce qui est entré, muet sur ce qui a pu sortir
                        // sans trace. On le dit, plutôt que de laisser croire
                        // à un mois vérifié.
                        //
                        // Même principe que le rapport d'inventaire : un
                        // chiffre provisoire ne se présente jamais comme
                        // définitif.
                        if (report.journeesNonCloturees > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    report.journeesNonCloturees == 1
                                        ? 'Comprend 1 journée non clôturée : '
                                              'sa caisse n\'a pas été comptée.'
                                        : 'Comprend '
                                              '${report.journeesNonCloturees} '
                                              'journées non clôturées : leur '
                                              'caisse n\'a pas été comptée.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sorties de caisse ce mois',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '- ${CurrencyFormatter.format(report.totalWithdrawals)}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'ÉCARTS DE CAISSE',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGapValue(
                                      'Manques',
                                      report.totalShortage,
                                      Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGapValue(
                                      'Surplus',
                                      report.totalSurplus,
                                      Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Résultat ajusté par la caisse',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      report.cashAdjustedResult,
                                    ),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: report.cashAdjustedResult >= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Bénéfice net + écarts de caisse. Le bénéfice opérationnel reste affiché séparément.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Le bloc COMMANDES, à part et jamais additionné au
                        // bloc boutique.
                        //
                        // Les deux n'ont pas le même rythme : un acompte d'août
                        // pour un gâteau livré en septembre appartient à
                        // septembre. Les mélanger rendrait les deux illisibles,
                        // et changerait des chiffres boutique que personne n'a
                        // demandé à changer.
                        _BlocCommandes(mois: _selectedMonth),
                        const SizedBox(height: 30),

                        const Text(
                          'VENTES PAR SEMAINE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWeekBar(
                          'Sem. 1 (1-7)',
                          weeklySales[0],
                          maxWeekSale,
                        ),
                        _buildWeekBar(
                          'Sem. 2 (8-14)',
                          weeklySales[1],
                          maxWeekSale,
                        ),
                        _buildWeekBar(
                          'Sem. 3 (15-21)',
                          weeklySales[2],
                          maxWeekSale,
                        ),
                        _buildWeekBar(
                          'Sem. 4 (22-Fin)',
                          weeklySales[3],
                          maxWeekSale,
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'DÉTAIL PAR JOUR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade100,
                              ), // 👈 Correction du MaterialStateProperty
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Achat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Vente Réal.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Dépenses',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Écart caisse',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Marge Nette',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: report.dailyClosings.map((closing) {
                                final dateStr = DateFormat(
                                  'dd/MM',
                                ).format(closing.closingDate);
                                final coutAchat =
                                    closing.totalSales - closing.grossProfit;
                                final note = closing.note?.trim() ?? '';
                                final hasNote = note.isNotEmpty;

                                return DataRow(
                                  // Une journée annotée (réouverture, clôture
                                  // tardive, incident) doit se voir : sinon la
                                  // trace existe en base sans que personne ne
                                  // la lise jamais.
                                  // Toutes les journées sont consultables, pas
                                  // seulement celles qui portent une note.
                                  onSelectChanged: (_) => _showClosingDetail(
                                    context,
                                    dateStr,
                                    closing,
                                  ),
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (hasNote) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.sticky_note_2_outlined,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(CurrencyFormatter.format(coutAchat)),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(
                                          closing.totalSales,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(
                                          closing.totalWithdrawals,
                                        ),
                                        style: TextStyle(
                                          color: closing.totalWithdrawals > 0
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(
                                          closing.cashGap ?? 0,
                                        ),
                                        style: TextStyle(
                                          color: (closing.cashGap ?? 0) < 0
                                              ? Colors.red
                                              : (closing.cashGap ?? 0) > 0
                                              ? Colors.blue
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(
                                          closing.netProfit,
                                        ),
                                        style: TextStyle(
                                          color: closing.netProfit > 0
                                              ? Colors.green.shade700
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapValue(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Ce que les commandes ont rapporté ce mois-ci.
///
/// Ne s'affiche pas du tout si la boutique n'a aucune commande : un bloc de
/// zéros dans un bilan est une invitation à croire qu'on a raté quelque chose.
class _BlocCommandes extends ConsumerWidget {
  const _BlocCommandes({required this.mois});

  final DateTime mois;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bilan = ref.watch(bilanCommandesProvider(mois)).value;
    if (bilan == null || bilan.estVide) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'COMMANDES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                '${bilan.nombreLivrees} livrée(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 22),
          _LigneBilan('Chiffre d\'affaires', bilan.chiffreAffaires),
          const SizedBox(height: 6),
          _LigneBilan('Ce que ça a coûté', bilan.cout),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bénéfice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                // Nul veut dire « on ne sait pas », et le dire vaut mieux
                // qu'afficher le chiffre d'affaires comme un bénéfice — le
                // mensonge le plus facile à faire dans ce module.
                bilan.benefice == null
                    ? 'Coût non saisi'
                    : CurrencyFormatter.format(bilan.benefice!.toDouble()),
                style: TextStyle(
                  fontSize: bilan.benefice == null ? 13 : 18,
                  fontWeight: FontWeight.bold,
                  color: bilan.benefice == null
                      ? AppColors.warningDark
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          // L'avertissement compte autant que les chiffres : si elle livre dix
          // commandes et n'en chiffre que huit, le bénéfice montré est trop
          // beau. Le taire la ferait décider sur un chiffre incomplet.
          if (bilan.livreesSansCout > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bilan.livreesSansCout == 1
                    ? 'Une commande livrée n\'a pas son coût : le bénéfice '
                          'affiché est plus beau que le vrai.'
                    : '${bilan.livreesSansCout} commandes livrées n\'ont pas '
                          'leur coût : le bénéfice affiché est plus beau que '
                          'le vrai.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warningDark,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (bilan.encoreDu > 0) ...[
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Encore dû par les clientes',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  CurrencyFormatter.format(bilan.encoreDu.toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Ni gagné ni perdu : attendu.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            // Les noms, pas seulement le total : une propriétaire à distance
            // ne peut ni appeler ni relancer un chiffre.
            for (final cliente in bilan.debitrices.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cliente.livree
                            // Livrée et impayée : la marchandise est partie, la
                            // dette n'est plus garantie par rien. C'est celle
                            // qu'on relance en premier.
                            ? '${cliente.nom} · déjà livrée'
                            : cliente.nom,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cliente.livree
                              ? AppColors.error
                              : Colors.grey.shade800,
                          fontWeight: cliente.livree
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cliente.montant.toDouble()),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            if (bilan.debitrices.length > 6)
              Text(
                'et ${bilan.debitrices.length - 6} autre(s)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
          if (bilan.semaines.isNotEmpty) ...[
            const Divider(height: 22),
            Text(
              'SEMAINE PAR SEMAINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            for (final semaine in bilan.semaines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Du ${DateFormat('dd/MM').format(semaine.debut)} '
                        'au ${DateFormat('dd/MM').format(semaine.fin)} · '
                        '${semaine.nombreLivrees} livrée(s)',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      semaine.benefice == null
                          ? '${CurrencyFormatter.format(semaine.chiffreAffaires.toDouble())} · coût ?'
                          : CurrencyFormatter.format(
                              semaine.benefice!.toDouble(),
                            ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LigneBilan extends StatelessWidget {
  const _LigneBilan(this.libelle, this.montant);

  final String libelle;
  final int montant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(libelle, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          CurrencyFormatter.format(montant.toDouble()),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
