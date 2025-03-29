import 'package:flutter/material.dart';

class MiniMesa extends StatelessWidget {
  final List<Map<String, dynamic>> jugadores;

  const MiniMesa({super.key, required this.jugadores});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      top: 10,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: jugadores.map((j) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    child: Text(j['nombre'][0]),
                  ),
                  SizedBox(width: 6),
                  Text(j['nombre'], style: TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
