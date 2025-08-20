import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String mensaje;
  final bool esPropio;

  const ChatBubble({
    super.key,
    required this.mensaje,
    this.esPropio = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = esPropio ? Colors.amberAccent : Colors.white;
    final textColor = esPropio ? Colors.black : Colors.grey[900];
    final align = esPropio ? Alignment.centerRight : Alignment.centerLeft;
    final radius = esPropio
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          mensaje,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
