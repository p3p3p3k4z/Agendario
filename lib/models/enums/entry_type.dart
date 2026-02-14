// discriminador de entradas: la ui y la logica de negocio
// cambian segun este valor (icono, color, campos visibles)
enum EntryType {
  event,     // cita con fecha y hora en la agenda
  note,      // nota rapida sin fecha especifica
  journal,   // entrada de diario reflexiva (mood + contenido largo)
  reminder,  // recordatorio con posible notificacion futura
}
