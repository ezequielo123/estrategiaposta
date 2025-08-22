import 'package:flutter/material.dart';

class FinalScoreScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tablero; // [{id,nombre,puntos}]
  final Map<String, dynamic> ganador;       // {nombre,puntos}
  final int rondas;

  const FinalScoreScreen({
    super.key,
    required this.tablero,
    required this.ganador,
    required this.rondas,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...tablero]..sort((a,b) => (b['puntos']??0).compareTo(a['puntos']??0));
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de la partida')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Ganador: ${ganador['nombre']} (${ganador['puntos']})',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Rondas jugadas: $rondas'),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = sorted[i];
                    final isWinner = p['nombre'] == ganador['nombre'];
                    return ListTile(
                      leading: Text('${i + 1}'),
                      title: Text(
                        p['nombre'] ?? '',
                        style: TextStyle(
                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text('${p['puntos'] ?? 0}'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Salir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/ranking'),
                    child: const Text('Ver ranking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
