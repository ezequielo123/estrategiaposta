import 'package:flutter/material.dart';
import 'chat_sala_widget.dart';
import 'chat_toggle_widget.dart';

class ChatAdaptativoWidget extends StatelessWidget {
  const ChatAdaptativoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Umbral configurable (puede ser 600, 700, 800, etc.)
    const desktopThreshold = 700;

    if (screenWidth >= desktopThreshold) {
      return const ChatSalaWidget();   // 🖥️ Versión panel lateral
    } else {
      return const ChatToggleWidget(); // 📱 Versión flotante
    }
  }
}
