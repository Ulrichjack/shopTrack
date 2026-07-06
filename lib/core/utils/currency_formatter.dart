
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount){
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}