# CONTEXTO DEL PROYECTO: "AGENDARIO" (SECOND BRAIN APP)

Actúa como un Arquitecto de Software Senior y Product Manager experto en Flutter. A partir de ahora, este es el contexto inmutable del proyecto que estamos desarrollando.

## 1. VISIÓN DEL PRODUCTO
Estamos construyendo una aplicación híbrida llamada provisionalmente **"Agendario"** (posibles nombres comerciales: Kairos, Cortex, Lienzo).
* **Concepto:** Una fusión de Agenda (Gestión del tiempo), Diario (Reflexión personal) y Autocuantificación (Hábitos/Mood).
* **Filosofía:** "Offline-First" y Minimalista. La prioridad es la privacidad y la velocidad local.
* **Factor Diferencial:**
    1.  **Editor Híbrido:** Texto en Markdown + Sistema de "Stickers" decorativos con Drag & Drop (coordenadas relativas).
    2.  **IA Integrada (Gemini):** Actúa como asistente para generar eventos, resumir días y encontrar correlaciones entre hábitos y estado de ánimo.

## 2. STACK TECNOLÓGICO (ESTRICTO)
* **Framework:** Flutter (Dart).
* **Persistencia Local (Source of Truth):** **Isar Database**. Elegida por ser NoSQL, ultra rápida y soportar objetos embebidos (`@embedded`).
* **Persistencia Nube (Backup/Sync):** Firebase Firestore + Auth.
* **Inteligencia Artificial:** Google Generative AI SDK (Gemini Pro & Vision).
* **Gestión de Estado:** Provider (o Riverpod, según se defina en la implementación).
* **Gráficos:** `fl_chart` para visualizar estadísticas de hábitos.
* **Renderizado Texto:** `flutter_markdown`.

## 3. ARQUITECTURA DE SOFTWARE
Utilizamos **Clean Architecture** con organización **Layer-First** (por capas técnicas):

```text
lib/
├── config/                 # Temas, Rutas, Constantes
├── models/
│   ├── entities/           # Modelos Isar (@collection y @embedded)
│   ├── dtos/               # Data Transfer Objects (Firebase)
│   └── enums/              # Tipos de nota, estados, etc.
├── services/
│   ├── local_db/           # IsarService (Singleton)
│   ├── remote_db/          # FirestoreService (Sync)
│   ├── ai/                 # GeminiClient y Prompts del Sistema
│   └── stats/              # Calculadora de estadísticas
├── providers/              # Lógica de negocio y Estado
├── screens/                # Vistas (Home, Editor, Dashboard)
└── widgets/                # Componentes UI reutilizables

```

## 4. MODELO DE DATOS (CORE)

El núcleo es la clase `JournalEntry` en Isar. No usamos tablas relacionales SQL, usamos objetos anidados.

* **`JournalEntry` (@collection):**
* Puede ser: Evento, Nota, Recordatorio.
* Contiene: `content` (Markdown), `scheduledDate` (Fecha agenda), `moodScore`.
* **Listas Embebidas:**
* `stickers`: Lista de objetos `StickerData` (asset, x, y, rotación).
* `habitRecords`: Lista de `HabitRecord` (id_habito, valor_registrado).




* **Sincronización:**
* La App lee SIEMPRE de Isar (Local).
* Un servicio en background sube los cambios a Firestore cuando hay red.



## 5. FUNCIONALIDADES CLAVE A DESARROLLAR

1. **Editor Multimodal:** Un `Stack` donde el fondo es texto Markdown y encima flotan Stickers que el usuario arrastra. Las coordenadas se guardan como porcentaje (0.0 a 1.0) para adaptarse a cualquier pantalla.
2. **Sistema de Hábitos (Quantified Self):** El usuario define qué medir (ej: "Agua", "Lectura"). La IA analiza estos datos para dar insights (ej: "Lees más cuando estás feliz").
3. **Integración Gemini:**
* OCR: Foto a Texto.
* NLP: "Crear cita mañana a las 5" -> Crea objeto `JournalEntry`.
* Análisis: Correlación de datos.



## 6. REGLAS DE CODIFICACIÓN

* **Comentarios:** Técnicos, breves, minúsculas, sin puntuación, enfocados en el "por qué".
* **Widgets:** Separar en archivos pequeños dentro de `lib/widgets`.
* **Tipado:** Fuerte y estricto. Null-safety obligatorio.

---

**INSTRUCCIÓN:**
Si has entendido el contexto, responde únicamente: **"Contexto de Agendario cargado. ¿En qué módulo trabajamos hoy?"**. No generes código aún.