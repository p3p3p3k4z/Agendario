// tipo de medicion: determina que widget de input se muestra
// y como se interpreta el valor numerico en HabitRecord
enum HabitType {
  boolean,   // si/no, renderiza un checkbox (value: 0.0 o 1.0)
  scale_1_5, // escala de satisfaccion 1 a 5, renderiza slider
  counter,   // incremento libre (+/-), valor absoluto (ej: ml, paginas)
  time,      // duracion en minutos, renderiza time picker
}
