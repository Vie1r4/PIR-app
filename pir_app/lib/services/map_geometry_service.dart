import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/concelho_geometry.dart';

/// Serviço que carrega e faz o parsing dos polígonos GeoJSON de Portugal Continental
class MapGeometryService {
  static final MapGeometryService _instance = MapGeometryService._internal();
  factory MapGeometryService() => _instance;
  MapGeometryService._internal();

  List<ConcelhoGeometry>? _geometries;

  // Dimensões do canvas virtual
  static const double canvasWidth = 1000.0;
  static const double canvasHeight = 1600.0;

  // Limites geográficos de Portugal Continental com margem
  static const double _minLon = -9.60;
  static const double _maxLon = -6.10;
  static const double _minLat = 36.90;
  static const double _maxLat = 42.20;

  // Parâmetros de projeção pré-calculados
  static const double _cosLat = 0.77162458; // cos(39.55 * pi / 180)
  static const double _spanX = (_maxLon - _minLon) * _cosLat;
  static const double _spanY = _maxLat - _minLat;
  static const double _padding = 30.0;
  static const double _availW = canvasWidth - (_padding * 2);
  static const double _availH = canvasHeight - (_padding * 2);

  static double get _scale => math.min(_availW / _spanX, _availH / _spanY);
  static double get _offsetX => _padding + (_availW - (_spanX * _scale)) / 2.0;
  static double get _offsetY => _padding + (_availH - (_spanY * _scale)) / 2.0;

  /// Projeta coordenadas geográficas (longitude, latitude) no sistema de coordenadas do Canvas (1000x1600)
  static Offset project(num lon, num lat) {
    final x = _offsetX + (lon - _minLon) * _cosLat * _scale;
    final y = _offsetY + (_maxLat - lat) * _scale;
    return Offset(x, y);
  }

  /// Encontra o concelho correspondente às coordenadas (latitude, longitude).
  /// 1. Tenta correspondência direta através de ponto-em-polígono (contains).
  /// 2. Se estiver ligeiramente fora do traçado dos polígonos (ex: na costa ou fronteira),
  ///    encontra o concelho continental com menor distância ao centroide.
  Future<ConcelhoGeometry?> encontrarPorCoordenadas(
    double lat,
    double lon, [
    List<ConcelhoGeometry>? geometrias,
  ]) async {
    // Verificação de limites aproximados para a Península Ibérica / Portugal
    if (lat < 35.0 || lat > 44.0 || lon < -12.0 || lon > -4.0) {
      return null;
    }

    final list = geometrias ?? await carregarGeometrias();
    if (list.isEmpty) return null;

    final pt = project(lon, lat);

    // 1. Verificação direta de polígono (ponto-em-polígono)
    for (final geom in list) {
      if (geom.contains(pt)) {
        return geom;
      }
    }

    // 2. Se estiver ligeiramente fora do traçado vetorial, procura o concelho mais próximo
    ConcelhoGeometry? maisProximo;
    double menorDistanciaSq = double.infinity;

    for (final geom in list) {
      final center = geom.bounds.center;
      final dx = center.dx - pt.dx;
      final dy = center.dy - pt.dy;
      final distSq = (dx * dx) + (dy * dy);
      if (distSq < menorDistanciaSq) {
        menorDistanciaSq = distSq;
        maisProximo = geom;
      }
    }

    return maisProximo;
  }

  Future<List<ConcelhoGeometry>> carregarGeometrias() async {
    if (_geometries != null) return _geometries!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/concelhos_geo.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;

      final list = <ConcelhoGeometry>[];

      for (final f in features) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final dico = (props['DICO'] ?? '').toString();
        final concelhoNome = (props['Concelho'] ?? '').toString();
        final distritoNome = (props['Distrito'] ?? '').toString();

        final geometry = feature['geometry'] as Map<String, dynamic>?;
        if (geometry == null) continue;

        final geomType = geometry['type'] as String?;
        final path = Path();

        if (geomType == 'Polygon') {
          final coords = geometry['coordinates'] as List<dynamic>;
          for (final ring in coords) {
            _adicionarRingAoPath(path, ring as List<dynamic>, project);
          }
        } else if (geomType == 'MultiPolygon') {
          final polys = geometry['coordinates'] as List<dynamic>;
          for (final poly in polys) {
            final polyList = poly as List<dynamic>;
            for (final ring in polyList) {
              _adicionarRingAoPath(path, ring as List<dynamic>, project);
            }
          }
        }

        path.fillType = PathFillType.evenOdd;
        final bounds = path.getBounds();

        list.add(ConcelhoGeometry(
          dico: dico,
          nome: concelhoNome,
          distrito: distritoNome,
          path: path,
          bounds: bounds,
        ));
      }

      _geometries = list;
      return list;
    } catch (e) {
      debugPrint('Erro ao carregar geometrias dos concelhos: $e');
      return [];
    }
  }

  void _adicionarRingAoPath(
    Path path,
    List<dynamic> ring,
    Offset Function(num lon, num lat) project,
  ) {
    if (ring.isEmpty) return;

    final first = ring[0] as List<dynamic>;
    final startPt = project(first[0] as num, first[1] as num);
    path.moveTo(startPt.dx, startPt.dy);

    for (int i = 1; i < ring.length; i++) {
      final pt = ring[i] as List<dynamic>;
      final offset = project(pt[0] as num, pt[1] as num);
      path.lineTo(offset.dx, offset.dy);
    }
    path.close();
  }
}
