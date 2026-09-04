class Concelho {
  final String dico;
  final String nome;
  final String distrito;

  const Concelho({
    required this.dico,
    required this.nome,
    required this.distrito,
  });

  factory Concelho.fromJson(Map<String, dynamic> json) {
    return Concelho(
      dico: json['dico'] as String,
      nome: json['nome'] as String,
      distrito: json['distrito'] as String,
    );
  }

  static List<Concelho> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Concelho.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Check if this concelho matches a search query (case-insensitive, accent-tolerant)
  bool matchesSearch(String query) {
    final q = _normalize(query);
    return _normalize(nome).contains(q) || _normalize(distrito).contains(q);
  }

  /// Simple accent normalization for search
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }

  @override
  String toString() => '$nome ($distrito)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Concelho && dico == other.dico;

  @override
  int get hashCode => dico.hashCode;
}
