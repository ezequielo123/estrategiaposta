import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/socket_service.dart'; // 👈 FALTA ESTO

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado por FlutterFire CLI

import 'state/app_state.dart';
import 'screens/app_wrapper.dart';
import 'screens/ranking_screen.dart'; // 🏆 Agregado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EstrategiaApp(),
    ),
  );
}

class EstrategiaApp extends StatelessWidget {
  const EstrategiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SocketService().registerContext(context);
    });
    return MaterialApp(
      title: 'Estrategia 🃏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),

      // 🧭 Ruta inicial
      home: const AppWrapper(),

      // 🌍 Rutas globales
      routes: {
        '/ranking': (context) => const RankingScreen(), // 🏆 Ruta Ranking
      },
    );
  }
}
