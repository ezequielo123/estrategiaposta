import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'training_screen.dart'; // Aún disponible si lo querés usar después

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // ✅ Modo FULL ONLINE
    return const HomeScreen();

    // 🔁 Si querés lógica condicional:
    // return appState.nombreJugador.isNotEmpty
    //     ? const LobbyScreen()
    //     : const HomeScreen();

    // 🔀 Si querés un switch modo-entrenamiento, podés usar algo como:
    // return appState.modoEntrenamiento ? const TrainingScreen() : const HomeScreen();
  }
}
