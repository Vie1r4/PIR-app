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

  Future<List<ConcelhoGeometry>> carregarGeometrias() async {
    if (_geometries != null) return _geometries!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/concelhos_geo.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;

      // Projeção Equirretangular corrigida pela latitude média (~39.5°)
      const cosLat = 0.77162458; // cos(39.55 * pi / 180)
      const spanX = (_maxLon - _minLon) * cosLat;
      const spanY = _maxLat - _minLat;

      const padding = 30.0;
      const availW = canvasWidth - (padding * 2);
      const availH = canvasHeight - (padding * 2);

      final scale = math.min(availW / spanX, availH / spanY);
      final offsetX = padding + (availW - (spanX * scale)) / 2.0;
      final offsetY = padding + (availH - (spanY * scale)) / 2.0;

      Offset project(num lon, num lat) {
        final x = offsetX + (lon - _minLon) * cosLat * scale;
        final y = offsetY + (_maxLat - lat) * scale;
        return Offset(x, y);
      }

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
