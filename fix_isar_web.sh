#!/bin/bash
# Script para parchear los archivos .g.dart generados por Isar
# Reemplaza literales enteros de 64-bit con su equivalente seguro para JavaScript
# (el valor mas cercano representable exactamente como double IEEE 754)
#
# Uso: ejecutar despues de cada `flutter pub run build_runner build`
#   bash fix_isar_web.sh
#
# ¿Por que funciona? En Web, Dart usa double de JS para int.
# Isar calcula los hashes con la misma aritmetica, asi que el hash en runtime
# coincide con el literal parcheado.

echo "🔧 Parcheando archivos .g.dart para compatibilidad Web..."

BASE="lib/models/entities"

# Mapeo: valor original del generador -> valor seguro para JS (del compilador)
# journal_entry.g.dart
sed -i 's/-8443410721192565146/-8443410721192564736/g' "$BASE/journal_entry.g.dart"
sed -i 's/2134397340427724972/2134397340427725056/g'  "$BASE/journal_entry.g.dart"
sed -i 's/-6773496565145745994/-6773496565145746432/g' "$BASE/journal_entry.g.dart"
sed -i 's/-39763503327887510/-39763503327887512/g'    "$BASE/journal_entry.g.dart"
echo "  ✅ journal_entry.g.dart"

# sticker_data.g.dart
sed -i 's/6175958651886258843/6175958651886259200/g' "$BASE/sticker_data.g.dart"
echo "  ✅ sticker_data.g.dart"

# text_box_data.g.dart
sed -i 's/5471231240745787860/5471231240745787392/g' "$BASE/text_box_data.g.dart"
echo "  ✅ text_box_data.g.dart"

# habit_record.g.dart
sed -i 's/-8253752743009167416/-8253752743009167360/g' "$BASE/habit_record.g.dart"
echo "  ✅ habit_record.g.dart"

# habit_definition.g.dart
sed -i 's/970403525843598740/970403525843598720/g'   "$BASE/habit_definition.g.dart"
sed -i 's/2134397340427724972/2134397340427725056/g' "$BASE/habit_definition.g.dart"
echo "  ✅ habit_definition.g.dart"

echo ""
echo "✨ Listo! Los archivos .g.dart ahora son compatibles con Web."
echo "   Ejecuta: flutter run -d chrome"
