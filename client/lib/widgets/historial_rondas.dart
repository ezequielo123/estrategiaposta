import 'package:flutter/material.dart';

class HistorialRondas extends StatelessWidget {
  final List<List<String>> historial;

  const HistorialRondas({super.key, required this.historial});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('📜 Historial de Rondas'),
      children: historial.map((ronda) {
        return ListTile(
          title: Text(ronda.join(' | ')),
        );
      }).toList(),
    );
  }
}
