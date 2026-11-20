import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Police embarquée pour les accents et signes utilisés dans les bilans.
/// Les polices PDF de base n'incluent pas tous les glyphes Unicode.
Future<pw.ThemeData> chargerThemePdf() async {
  final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  return pw.ThemeData.withFont(
    base: pw.Font.ttf(regular),
    bold: pw.Font.ttf(bold),
  );
}
