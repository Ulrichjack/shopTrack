import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/domain/entities/daily_closing_entity.dart';
import '../../../../core/sync/sync_service.dart'; // 👈 AJOUT POUR LA SYNCHRO
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

  Future<void> _generatePdf(MonthlyReportState report, String monthName) async {
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
                    gap == 0
                        ? 'Écart'
                        : (gap < 0 ? 'Manquant' : 'Surplus'),
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
                  : () => _generatePdf(report, capitalizedMonth),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
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
