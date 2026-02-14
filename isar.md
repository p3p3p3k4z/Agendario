# Isar Database

**Isar** es una base de datos NoSQL ultra rápida diseñada específicamente para el desarrollo en Flutter. A diferencia de las soluciones basadas en SQLite (que requieren mapeo relacional), Isar permite persistir objetos de Dart directamente, ofreciendo un rendimiento superior y una experiencia de desarrollo "Type-Safe" (segura en tipos).

### Características Principales

* **Alto Rendimiento:** Escrita en Rust, optimizada para manejar cientos de miles de registros con latencia mínima.
* **ACID Compliant:** Garantiza la integridad de los datos mediante transacciones atómicas (Atomicidad, Consistencia, Aislamiento y Durabilidad).
* **Reactividad:** Permite escuchar cambios en la base de datos en tiempo real mediante `Streams`, ideal para la gestión de estado en Flutter.
* **Búsqueda Full-Text:** Soporte nativo para índices de texto y búsquedas complejas sin configuraciones externas.

---

## 2. Flujo de Trabajo

El desarrollo con Isar se basa en la **Generación de Código**. El flujo consiste en:

1. Definir los modelos de datos (Clases de Dart).
2. Anotar las clases con decoradores de Isar (`@collection`).
3. Ejecutar `build_runner` para generar el código de vinculación (`.g.dart`).

---

## 3. Implementación y Sintaxis

A continuación se presentan los patrones estándar para definir, escribir y consultar datos.

### 3.1. Definición del Esquema (Schema)

Isar utiliza el concepto de **Colecciones**. Una colección es análoga a una tabla en SQL, pero almacena documentos (objetos).

**Ejemplo Genérico: Entidad "Usuario"**

```dart
import 'package:isar/isar.dart';

// Archivo generado automáticamente por build_runner
part 'user.g.dart'; 

@collection
class User {
  // Isar gestiona automáticamente los IDs numéricos
  Id id = Isar.autoIncrement; 

  // Indexar campos permite búsquedas ultra rápidas
  @Index(type: IndexType.value) 
  late String name;

  int? age;

  // Soporte para listas y tipos complejos
  List<String> tags = []; 
}

```

### 3.2. Apertura de la Instancia

Para interactuar con la base de datos, se debe abrir una instancia especificando los esquemas a utilizar.

```dart
final dir = await getApplicationDocumentsDirectory();

final isar = await Isar.open(
  [UserSchema], // Se registran los esquemas generados
  directory: dir.path,
  inspector: true, // Habilita la herramienta de visualización en debug
);

```

### 3.3. Escritura de Datos (Transacciones)

Todas las operaciones de escritura (crear, actualizar, eliminar) **deben** realizarse dentro de una transacción. Esto previene condiciones de carrera y corrupción de datos.

```dart
final newUser = User()
  ..name = "Carlos Pérez"
  ..age = 30;

// Escritura síncrona (bloqueante) o asíncrona
await isar.writeTxn(() async {
  await isar.users.put(newUser); // .put() crea o actualiza si el ID ya existe
});

```

### 3.4. Consultas (Queries)

Isar ofrece una sintaxis fluida y legible para filtrar datos. No se requiere SQL string, sino métodos encadenados generados por el compilador.

**Ejemplo: Filtrado simple**

```dart
// Obtener todos los usuarios mayores de 18 años
final adults = await isar.users
    .filter()
    .ageGreaterThan(18)
    .findAll();

```

**Ejemplo: Consultas complejas**

```dart
// Usuarios llamados "Ana" ordenados por edad descendente
final result = await isar.users
    .filter()
    .nameEqualTo("Ana")
    .sortByAgeDesc()
    .findAll();

```

### 3.5. Reactividad (Streams)

Esta es una de las funciones más potentes para Flutter. Permite reconstruir la UI automáticamente cuando los datos cambian, sin necesidad de llamar a `setState` manualmente tras cada escritura.

```dart
Stream<List<User>> streamUsers() {
  // Emite una nueva lista cada vez que se agrega/edita/borra un usuario
  return isar.users.where().watch(fireImmediately: true);
}

```

---

## 4. Tipos de Datos Soportados

Isar soporta nativamente la mayoría de los tipos de datos de Dart, eliminando la necesidad de convertidores:

* **Primitivos:** `bool`, `int`, `double`, `String`.
* **Fechas:** `DateTime` (almacenado con precisión de microsegundos).
* **Listas:** `List<String>`, `List<int>`, etc.
* **Objetos Embebidos:** Clases anotadas con `@embedded` que viven dentro de un objeto padre (ideal para estructuras JSON complejas).

## 5. Herramientas: Isar Inspector

Isar incluye una herramienta de inspección visual que funciona en el navegador web mientras la aplicación se ejecuta en modo `debug`. Permite:

* Visualizar las colecciones como tablas.
* Ejecutar consultas de prueba.
* Modificar o eliminar registros manualmente para pruebas.
