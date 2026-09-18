import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/concelho.dart';
import 'map_geometry_service.dart';

/// Representa coordenadas geográficas com indicação da fonte (GPS ou Rede/IP)
class CoordenadasGps {
  final double latitude;
  final double longitude;
  final String fonte; // 'GPS' ou 'IP'

  const CoordenadasGps({
    required this.latitude,
    required this.longitude,
    required this.fonte,
  });

  @override
  String toString() => 'CoordenadasGps(lat: $latitude, lon: $longitude, fonte: $fonte)';
}

/// Serviço responsável por detetar a localização do utilizador (híbrido: GPS/Windows Location + Fallback IP)
/// e mapear diretamente para um dos 278 concelhos de Portugal Continental via geometria vetorial local.
class LocalizacaoService {
  static final LocalizacaoService _instance = LocalizacaoService._internal();
  factory LocalizacaoService() => _instance;
  LocalizacaoService._internal();

  final MapGeometryService _geometryService = MapGeometryService();
  final http.Client _httpClient = http.Client();

  /// Tenta obter a localização via GPS / Windows Location Service
  Future<CoordenadasGps?> obterPosicaoGPS({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        debugPrint('LocalizacaoService: Serviço de localização do sistema está desativado.');
        return null;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.denied) {
          debugPrint('LocalizacaoService: Permissão de localização recusada pelo utilizador.');
          return null;
        }
      }

      if (permissao == LocationPermission.deniedForever) {
        debugPrint('LocalizacaoService: Permissão de localização permanentemente recusada.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );

      return CoordenadasGps(
        latitude: position.latitude,
        longitude: position.longitude,
        fonte: 'GPS',
      );
    } catch (e) {
      debugPrint('LocalizacaoService: Erro ao obter posição via GPS: $e');
      return null;
    }
  }

  /// Fallback por IP caso o Windows Location esteja desativado ou sem permissão
  Future<CoordenadasGps?> obterPosicaoIP({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final uri = Uri.parse('http://ip-api.com/json/?fields=status,countryCode,lat,lon');
      final response = await _httpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num?)?.toDouble();
          final lon = (data['lon'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            return CoordenadasGps(
              latitude: lat,
              longitude: lon,
              fonte: 'IP',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('LocalizacaoService: Fallback por IP não disponível: $e');
    }
    return null;
  }

  /// Obtém a melhor localização disponível (GPS primeiro, fallback por IP de seguida)
  Future<CoordenadasGps?> obterMelhorLocalizacao() async {
    // 1. Tentar GPS nativo (rápido)
    final gps = await obterPosicaoGPS();
    if (gps != null) return gps;

    // 2. Fallback de contingência por IP
    return await obterPosicaoIP();
  }

  /// Deteta o concelho atual do utilizador contra a lista oficial de concelhos
  Future<Concelho?> detetarConcelhoAtual(List<Concelho> concelhos) async {
    final coords = await obterMelhorLocalizacao();
    if (coords == null) return null;

    final geom = await _geometryService.encontrarPorCoordenadas(
      coords.latitude,
      coords.longitude,
    );

    if (geom == null) return null;

    // Procura o concelho com o DICO correspondente
    return concelhos.where((c) => c.dico == geom.dico).firstOrNull;
  }
}
