class Concelho {
  final String dico;
  final String nome;
  final String distrito;

  final String? _nomeNormalizado;
  final String? _distritoNormalizado;

  const Concelho({
    required this.dico,
    required this.nome,
    required this.distrito,
    String? nomeNormalizado,
    String? distritoNormalizado,
  })  : _nomeNormalizado = nomeNormalizado,
        _distritoNormalizado = distritoNormalizado;

  String get nomeNormalizado => _nomeNormalizado ?? normalize(nome);
  String get distritoNormalizado => _distritoNormalizado ?? normalize(distrito);

  factory Concelho.fromJson(Map<String, dynamic> json) {
    final nome = json['nome'] as String;
    final distrito = json['distrito'] as String;
    return Concelho(
      dico: json['dico'] as String,
      nome: nome,
      distrito: distrito,
      nomeNormalizado: normalize(nome),
      distritoNormalizado: normalize(distrito),
    );
  }

  static List<Concelho> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Concelho.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static final _regexA = RegExp(r'[àáâãäå]');
  static final _regexE = RegExp(r'[èéêë]');
  static final _regexI = RegExp(r'[ìíîï]');
  static final _regexO = RegExp(r'[òóôõö]');
  static final _regexU = RegExp(r'[ùúûü]');

  /// Accent and case normalization for search
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(_regexA, 'a')
        .replaceAll(_regexE, 'e')
        .replaceAll(_regexI, 'i')
        .replaceAll(_regexO, 'o')
        .replaceAll(_regexU, 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }

  /// Check if this concelho matches a search query (case-insensitive, accent-tolerant)
  bool matchesSearch(String query, {bool queryIsNormalized = false}) {
    final q = queryIsNormalized ? query : normalize(query);
    return nomeNormalizado.contains(q) || distritoNormalizado.contains(q);
  }

  @override
  String toString() => '$nome ($distrito)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Concelho && dico == other.dico;

  @override
  int get hashCode => dico.hashCode;
}
