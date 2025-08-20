class PuntajeJugador {
  final String nombre;
  final int puntos;
  final List<ResultadoRonda> historial;

  PuntajeJugador({
    required this.nombre,
    required this.puntos,
    this.historial = const [],
  });
}

class ResultadoRonda {
  final bool acerto;
  final int puntos;

  ResultadoRonda(this.acerto, this.puntos);
}
