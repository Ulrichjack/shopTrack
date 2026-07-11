import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../providers/monthly_report_provider.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _previousMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  // --- WIDGETS UI ---

  Widget _buildTopCard(String title, double amount, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(CurrencyFormatter.format(amount), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekBar(String label, double amount, double maxAmount) {
    // Calcul du pourcentage pour la barre (évite la division par zéro)
    final double percent = maxAmount > 0 ? (amount / maxAmount) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(CurrencyFormatter.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              // Fond gris
              Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              // Barre verte proportionnelle
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(height: 8, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
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
              // En-tête
              pw.Text('ShopTrack - Récapitulatif des Ventes', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Période : $monthName', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 24),

              // Résumé
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfSummaryBox('Vente Réalisée', report.totalSales),
                  _buildPdfSummaryBox('Dépenses', report.totalWithdrawals),
                  _buildPdfSummaryBox('Bénéfice Net', report.totalNetProfit, isGreen: true),
                ],
              ),
              pw.SizedBox(height: 32),

              // Tableau détaillé
              pw.Text('Détail par jour', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Montant Achat', 'Vente Réal.', 'Dépenses', 'Marge Nette'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1D9E75)), // Vert ShopTrack
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {0: pw.Alignment.centerLeft}, // La date à gauche
                data: report.dailyClosings.map((closing) {
                  final dateStr = DateFormat('dd/MM/yyyy').format(closing.closingDate);
                  final coutAchat = closing.totalSales - closing.grossProfit;
                  return [
                    dateStr,
                    CurrencyFormatter.format(coutAchat),
                    CurrencyFormatter.format(closing.totalSales),
                    CurrencyFormatter.format(closing.totalWithdrawals),
                    CurrencyFormatter.format(closing.netProfit),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Ouvre l'aperçu PDF et permet d'imprimer ou partager
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bilan_ShopTrack_$monthName.pdf',
    );
  }

  pw.Widget _buildPdfSummaryBox(String title, double amount, {bool isGreen = false}) {
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
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isGreen ? PdfColors.green700 : PdfColors.black),
          ),
        ],
      ),
    );
  }

  // --- BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(_selectedMonth));
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth);
    final capitalizedMonth = "${monthName[0].toUpperCase()}${monthName.substring(1)}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bilan — $capitalizedMonth', style: const TextStyle(fontSize: 18)),
        elevation: 0,
        actions: [
          // Bouton PDF
          reportAsync.maybeWhen(
            data: (report) => IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: report.dailyClosings.isEmpty ? null : () => _generatePdf(report, capitalizedMonth),
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
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: _previousMonth),
                Text(capitalizedMonth, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  onPressed: _selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year ? null : _nextMonth,
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: reportAsync.when(
              skipError: true, // 👈 On ajoute ça
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => NetworkErrorWidget(
                error: err.toString(),
                onRetry: () => ref.invalidate(monthlyReportProvider(_selectedMonth)),
              ),
              data: (report) {
                if (report.dailyClosings.isEmpty) {
                  return const Center(child: Text('Aucune donnée pour ce mois.', style: TextStyle(color: Colors.grey)));
                }

                // --- Calcul des Ventes par Semaine ---
                List<double> weeklySales = [0, 0, 0, 0];
                for (var closing in report.dailyClosings) {
                  int day = closing.closingDate.day;
                  if (day <= 7) weeklySales[0] += closing.totalSales;
                  else if (day <= 14) weeklySales[1] += closing.totalSales;
                  else if (day <= 21) weeklySales[2] += closing.totalSales;
                  else weeklySales[3] += closing.totalSales;
                }
                double maxWeekSale = weeklySales.reduce(max);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Les deux grosses cartes
                      Row(
                        children: [
                          _buildTopCard('Encaissé', report.totalSales, AppColors.primaryLight, AppColors.primaryDark),
                          const SizedBox(width: 12),
                          _buildTopCard('Bénéfice net', report.totalNetProfit, AppColors.success, AppColors.successDark),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Carte des sorties de caisse
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sorties de caisse ce mois', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('- ${CurrencyFormatter.format(report.totalWithdrawals)}', style: TextStyle(color: Colors.red.shade700, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 3. VENTES PAR SEMAINE (Barres de progression)
                      const Text('VENTES PAR SEMAINE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      _buildWeekBar('Sem. 1 (1-7)', weeklySales[0], maxWeekSale),
                      _buildWeekBar('Sem. 2 (8-14)', weeklySales[1], maxWeekSale),
                      _buildWeekBar('Sem. 3 (15-21)', weeklySales[2], maxWeekSale),
                      _buildWeekBar('Sem. 4 (22-Fin)', weeklySales[3], maxWeekSale),
                      const SizedBox(height: 30),

                      // 4. Le tableau détaillé
                      const Text('DÉTAIL PAR JOUR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Achat', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Vente Réal.', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Dépenses', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Marge Nette', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: report.dailyClosings.map((closing) {
                              final dateStr = DateFormat('dd/MM').format(closing.closingDate);
                              final coutAchat = closing.totalSales - closing.grossProfit;

                              return DataRow(
                                cells: [
                                  DataCell(Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(CurrencyFormatter.format(coutAchat))),
                                  DataCell(Text(CurrencyFormatter.format(closing.totalSales))),
                                  DataCell(Text(CurrencyFormatter.format(closing.totalWithdrawals), style: TextStyle(color: closing.totalWithdrawals > 0 ? Colors.red : Colors.black))),
                                  DataCell(Text(CurrencyFormatter.format(closing.netProfit), style: TextStyle(color: closing.netProfit > 0 ? Colors.green.shade700 : Colors.black, fontWeight: FontWeight.bold))),
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
        ],
      ),
    );
  }
}