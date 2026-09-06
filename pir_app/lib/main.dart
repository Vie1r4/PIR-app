import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/acessibilidade_provider.dart';
import 'providers/risco_provider.dart';
import 'providers/tema_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Load persisted theme and accessibility preferences before rendering
  final temaProvider = await TemaProvider.carregar();
  final acessibilidadeProvider = await AcessibilidadeProvider.carregar();
  final riscoProvider = RiscoProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: temaProvider),
        ChangeNotifierProvider.value(value: acessibilidadeProvider),
        ChangeNotifierProvider.value(value: riscoProvider),
      ],
      child: const PirApp(),
    ),
  );

  // Initialize data after the app is running
  riscoProvider.inicializar();
}
