import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('es_ES', null);
  final d = DateTime.utc(2026, 5, 20);
  final f = DateFormat.yMMMEd('es');
  print('UTC object formatted: ${f.format(d)}');
  print('Local object formatted: ${f.format(d.toLocal())}');
}
