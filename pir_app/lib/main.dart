import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/risco_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Create and initialize the provider
  final riscoProvider = RiscoProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: riscoProvider,
      child: const PirApp(),
    ),
  );

  // Initialize data after the app is running
  riscoProvider.inicializar();
}
