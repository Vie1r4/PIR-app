import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/constants.dart';

/// Local cache service using Hive for offline support and persistence
class CacheService {
  Box? _box;

  /// Initialize the Hive box
  Future<void> init() async {
    _box = await Hive.openBox(CacheKeys.boxName);
  }

  /// Save risk data JSON to cache
  Future<void> salvarDadosRisco(String key, Map<String, dynamic> json) async {
    await _box?.put(key, jsonEncode(json));
  }

  /// Load cached risk data JSON
  Map<String, dynamic>? carregarDadosRisco(String key) {
    final data = _box?.get(key) as String?;
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save extended 9-day forecast to cache
  Future<void> salvarPrevisaoAlargada(List<Map<String, dynamic>> list) async {
    await _box?.put('rcm_previsao_alargada', jsonEncode(list));
  }

  /// Load cached extended 9-day forecast
  List<Map<String, dynamic>>? carregarPrevisaoAlargada() {
    final data = _box?.get('rcm_previsao_alargada') as String?;
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return null;
    }
  }

  /// Save list of favorite DICO codes
  Future<void> salvarFavoritos(List<String> dicos) async {
    await _box?.put(CacheKeys.favoritos, jsonEncode(dicos));
  }

  /// Load list of favorite DICO codes
  List<String> carregarFavoritos() {
    final data = _box?.get(CacheKeys.favoritos) as String?;
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Save the selected main concelho DICO
  Future<void> salvarConcelhoPrincipal(String dico) async {
    await _box?.put(CacheKeys.concelhoPrincipal, dico);
  }

  /// Load the selected main concelho DICO
  String? carregarConcelhoPrincipal() {
    return _box?.get(CacheKeys.concelhoPrincipal) as String?;
  }

  /// Get the timestamp of the last cache save for a key
  DateTime? ultimaAtualizacao(String key) {
    final timestamp =
        _box?.get('${CacheKeys.ultimaAtualizacaoPrefix}$key') as String?;
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Save the current timestamp for a cache key
  Future<void> salvarUltimaAtualizacao(String key) async {
    await _box?.put(
      '${CacheKeys.ultimaAtualizacaoPrefix}$key',
      DateTime.now().toIso8601String(),
    );
  }
}
