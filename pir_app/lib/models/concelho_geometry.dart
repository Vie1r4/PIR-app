import 'package:flutter/material.dart';

/// Representa a geometria vetorial de um concelho para desenho no mapa
class ConcelhoGeometry {
  final String dico;
  final String nome;
  final String distrito;
  final Path path;
  final Rect bounds;

  ConcelhoGeometry({
    required this.dico,
    required this.nome,
    required this.distrito,
    required this.path,
    required this.bounds,
  });

  /// Verifica se um determinado ponto toca dentro do concelho
  bool contains(Offset point) {
    if (!bounds.contains(point)) return false;
    return path.contains(point);
  }
}
