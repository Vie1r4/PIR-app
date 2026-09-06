import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Gere o modo de tema da aplicação (Claro / Escuro / Sistema)
/// com persistência local via Hive.
class TemaProvider extends ChangeNotifier {
  static const String _boxName = 'pir_cache';
  static const String _chave = 'tema_mode';
  static const MethodChannel _windowChannel = MethodChannel('pir_app/window');

  ThemeMode _themeMode;

  TemaProvider(ThemeMode inicial) : _themeMode = inicial;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Atualiza a barra de título nativa da janela (Windows) para coincidir com o tema.
  static Future<void> syncTitleBar(bool isDark) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _windowChannel.invokeMethod('updateTitleBarTheme', isDark);
    } catch (_) {}
  }

  /// Carrega a preferência guardada do Hive.
  static Future<TemaProvider> carregar() async {
    final box = await Hive.openBox(_boxName);
    final guardado = box.get(_chave) as String?;
    final modo = switch (guardado) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return TemaProvider(modo);
  }

  /// Muda o tema e persiste a preferência.
  Future<void> setTema(ThemeMode modo) async {
    if (_themeMode == modo) return;
    _themeMode = modo;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    final valor = switch (modo) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await box.put(_chave, valor);
  }
}
