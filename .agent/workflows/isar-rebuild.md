---
description: Regenerar código Isar y parchear para Web
---
## Pasos para regenerar el código Isar (después de cambiar modelos)

// turbo-all

1. Ejecutar build_runner para regenerar los archivos `.g.dart`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

2. Parchear los archivos generados para compatibilidad Web (reemplaza enteros de 64-bit con `int.parse()`):
```bash
bash fix_isar_web.sh
```

3. Verificar que no queden literales problemáticos:
```bash
flutter analyze
```

4. Probar en Web:
```bash
flutter run -d chrome
```
