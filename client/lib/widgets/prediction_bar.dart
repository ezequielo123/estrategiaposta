// lib/widgets/prediction_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class PredictionBar extends StatelessWidget {
  const PredictionBar({
    super.key,
    required this.esMiTurno,
    required this.turnoNombre,
    required this.countdown,
    required this.opciones,
    required this.seleccion,
    required this.onSelect,
    required this.onEnviar,
  });

  final bool esMiTurno;
  final String turnoNombre;
  final int countdown;
  final List<int> opciones;
  final int? seleccion;
  final void Function(int) onSelect;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final collapsedText = esMiTurno
        ? 'Tu predicción ($countdown s)'
        : (turnoNombre.isNotEmpty
            ? 'Esperando predicción de $turnoNombre…'
            : 'Esperando turno de predicción…');

    return Align(
      alignment: Alignment.topCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.only(top: 68),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.65),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header compacto
                Row(
                  children: [
                    Icon(Icons.flag,
                        size: 18,
                        color: esMiTurno ? Colors.amberAccent : Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        collapsedText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (esMiTurno) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: opciones.map((i) {
                        final selected = (seleccion == i);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$i'),
                            selected: selected,
                            onSelected: (_) => onSelect(i),
                            selectedColor: Colors.deepPurple,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      onPressed: (seleccion != null) ? onEnviar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
