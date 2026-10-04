import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
    locale: 'es_ES',
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM, HH:mm');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String dateTime(DateTime dt) {
    try {
      return _dateFormat.format(dt);
    } catch (_) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  static String shortDateTime(DateTime dt) {
    try {
      return _shortDateFormat.format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute}';
    }
  }
}
