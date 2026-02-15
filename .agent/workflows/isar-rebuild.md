---
description: Regenerar código Isar y parchear para Web
---
## Pasos para regenerar el código Isar (después de cambiar modelos)

// turbo-all

1. Ejecutar build_runner para regenerar los archivos `.g.dart`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

> [!WARNING]
> **SOLO para Web**: Si vas a compilar para web, ejecuta el paso 2.
> **Para Android/Linux**: NO ejecutes el paso 2, ya que romperá la app nativa.
> Si ya lo ejecutaste y quieres volver a nativo, repite el paso 1.

2. (SOLO WEB) Parchear archivos para compatibilidad JS (reemplaza enteros de 64-bit con `int.parse()`):
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
