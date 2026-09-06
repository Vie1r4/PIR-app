import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Nível de escala de texto da aplicação
enum EscalaTextoApp {
  pequeno(0.88, 'Pequeno'),
  normal(1.0, 'Normal'),
  grande(1.20, 'Grande'),
  gigante(1.40, 'Gigante');

  final double fator;
  final String rotulo;
  const EscalaTextoApp(this.fator, this.rotulo);

  static EscalaTextoApp fromString(String? val) {
    return switch (val) {
      'pequeno' => EscalaTextoApp.pequeno,
      'grande' => EscalaTextoApp.grande,
      'gigante' || 'muitoGrande' => EscalaTextoApp.gigante,
      _ => EscalaTextoApp.normal,
    };
  }

  String toChave() {
    return switch (this) {
      EscalaTextoApp.pequeno => 'pequeno',
      EscalaTextoApp.normal => 'normal',
      EscalaTextoApp.grande => 'grande',
      EscalaTextoApp.gigante => 'gigante',
    };
  }
}

/// Gere preferências de Acessibilidade com persistência no Hive
class AcessibilidadeProvider extends ChangeNotifier {
  static const String _boxName = 'pir_cache';
  static const String _chaveEscalaTexto = 'acc_escala_texto';
  static const String _chaveAltoContraste = 'acc_alto_contraste';
  static const String _chaveElementosGrandes = 'acc_elementos_grandes';
  static const String _chaveReduzirAnimacoes = 'acc_reduzir_animacoes';
  static const String _chaveDicasContextuais = 'acc_dicas_contextuais';

  EscalaTextoApp _escalaTexto;
  bool _altoContraste;
  bool _elementosGrandes;
  bool _reduzirAnimacoes;
  bool _dicasContextuais;

  AcessibilidadeProvider({
    EscalaTextoApp escalaTexto = EscalaTextoApp.normal,
    bool altoContraste = false,
    bool elementosGrandes = false,
    bool reduzirAnimacoes = false,
    bool dicasContextuais = true,
  })  : _escalaTexto = escalaTexto,
        _altoContraste = altoContraste,
        _elementosGrandes = elementosGrandes,
        _reduzirAnimacoes = reduzirAnimacoes,
        _dicasContextuais = dicasContextuais;

  // Getters
  EscalaTextoApp get escalaTexto => _escalaTexto;
  double get textScaleFactor => _escalaTexto.fator;
  bool get altoContraste => _altoContraste;
  bool get elementosGrandes => _elementosGrandes;
  bool get reduzirAnimacoes => _reduzirAnimacoes;
  bool get dicasContextuais => _dicasContextuais;

  /// Retorna o padding ou altura adicional para botões/toques quando elementos grandes estão ativados
  double get paddingExtra => _elementosGrandes ? 4.0 : 0.0;
  double get minTouchTarget => _elementosGrandes ? 52.0 : 44.0;

  /// Carregar definições persistidas do Hive
  static Future<AcessibilidadeProvider> carregar() async {
    final box = await Hive.openBox(_boxName);

    final escalaStr = box.get(_chaveEscalaTexto) as String?;
    final altoContraste = box.get(_chaveAltoContraste, defaultValue: false) as bool;
    final elementosGrandes = box.get(_chaveElementosGrandes, defaultValue: false) as bool;
    final reduzirAnimacoes = box.get(_chaveReduzirAnimacoes, defaultValue: false) as bool;
    final dicasContextuais = box.get(_chaveDicasContextuais, defaultValue: true) as bool;

    return AcessibilidadeProvider(
      escalaTexto: EscalaTextoApp.fromString(escalaStr),
      altoContraste: altoContraste,
      elementosGrandes: elementosGrandes,
      reduzirAnimacoes: reduzirAnimacoes,
      dicasContextuais: dicasContextuais,
    );
  }

  /// Alterar tamanho do texto
  Future<void> setEscalaTexto(EscalaTextoApp escala) async {
    if (_escalaTexto == escala) return;
    _escalaTexto = escala;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_chaveEscalaTexto, escala.toChave());
  }

  /// Ativar/desativar modo de alto contraste
  Future<void> setAltoContraste(bool ativo) async {
    if (_altoContraste == ativo) return;
    _altoContraste = ativo;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_chaveAltoContraste, ativo);
  }

  /// Ativar/desativar elementos e botões maiores
  Future<void> setElementosGrandes(bool ativo) async {
    if (_elementosGrandes == ativo) return;
    _elementosGrandes = ativo;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_chaveElementosGrandes, ativo);
  }

  /// Ativar/desativar redução de animações
  Future<void> setReduzirAnimacoes(bool ativo) async {
    if (_reduzirAnimacoes == ativo) return;
    _reduzirAnimacoes = ativo;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_chaveReduzirAnimacoes, ativo);
  }

  /// Ativar/desativar dicas explicativas contextuais
  Future<void> setDicasContextuais(bool ativo) async {
    if (_dicasContextuais == ativo) return;
    _dicasContextuais = ativo;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_chaveDicasContextuais, ativo);
  }

  /// Repor todos os valores para o padrão
  Future<void> reporPredefinicoes() async {
    _escalaTexto = EscalaTextoApp.normal;
    _altoContraste = false;
    _elementosGrandes = false;
    _reduzirAnimacoes = false;
    _dicasContextuais = true;
    notifyListeners();

    final box = await Hive.openBox(_boxName);
    await box.delete(_chaveEscalaTexto);
    await box.delete(_chaveAltoContraste);
    await box.delete(_chaveElementosGrandes);
    await box.delete(_chaveReduzirAnimacoes);
    await box.delete(_chaveDicasContextuais);
  }
}
