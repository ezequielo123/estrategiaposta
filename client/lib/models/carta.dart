class Carta {
  final int numero;
  final String palo;

  Carta({required this.numero, required this.palo});

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'palo': palo,
      };

  factory Carta.fromJson(Map<String, dynamic> json) {
    return Carta(
      numero: json['numero'] is int ? json['numero'] : int.tryParse(json['numero'].toString()) ?? 0,
      palo: json['palo']?.toString() ?? 'desconocido',
    );
  }

}
