import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _currency3 =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 3);
final _decimal = NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2);
final _integer = NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 0);
final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
final _date = DateFormat('dd/MM', 'pt_BR');

String formatCurrency(double value) => _currency.format(value);
String formatPricePerLiter(double value) => _currency3.format(value);
String formatDecimal(double value) => _decimal.format(value);
String formatKm(double value) => '${_integer.format(value)} km';
String formatDateTime(DateTime value) => _dateTime.format(value);
String formatShortDate(DateTime value) => _date.format(value);

/// Converte texto digitado (aceita vírgula ou ponto) em número.
double? parseDecimal(String? text) {
  if (text == null) return null;
  var t = text.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}
