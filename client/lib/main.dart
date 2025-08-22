import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/socket_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'state/app_state.dart';
import 'screens/app_wrapper.dart';
import 'screens/ranking_screen.dart';

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
      routes: {
        '/ranking': (_) => const RankingScreen(),
        '/home': (_) => const AppWrapper(),
      },
      home: const AppWrapper(),
    );
  }
}
