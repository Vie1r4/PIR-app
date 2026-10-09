import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/concelho.dart';
import '../models/concelho_geometry.dart';
import '../models/risco_incendio.dart';
import '../repositories/risco_repository.dart';
import '../services/cache_service.dart';
import '../services/localizacao_service.dart';
import '../services/map_geometry_service.dart';

class RiscoProvider extends ChangeNotifier {
  final RiscoRepository _repository;
  final CacheService _cacheService;
  final LocalizacaoService _localizacaoService;

  RiscoProvider({
    RiscoRepository? repository,
    CacheService? cacheService,
    LocalizacaoService? localizacaoService,
  })  : _repository = repository ?? RiscoRepository(),
        _cacheService = cacheService ?? CacheService(),
        _localizacaoService = localizacaoService ?? LocalizacaoService();

  List<Concelho> _concelhos = [];
  DadosRisco? _riscoHoje;
  DadosRisco? _riscoAmanha;
  List<DadosRisco> _previsaoAlargada = [];
  Concelho? _concelhoPrincipal;
  Set<String> _favoritoDicos = {};
  bool _isLoading = false;
  bool _isOnline = false;
  OrigemDados _origem = OrigemDados.cacheHive;
  String? _erro;
  DateTime? _ultimaAtualizacao;
  Timer? _autoSyncTimer;

  // Estado de Geolocalização
  bool _autoLocalizacao = false;
  bool _isLocalizando = false;
  String? _mensagemLocalizacao;

  // Política de Cache Inteligente & Cooldown Anti-Metralhadora
  static const Duration cacheTtl = Duration(hours: 2);
  static const Duration cooldownForcar = Duration(seconds: 30);
  DateTime? _ultimoPedidoRede;

  // Getters
  List<Concelho> get concelhos => _concelhos;
  DadosRisco? get riscoHoje => _riscoHoje;
  DadosRisco? get riscoAmanha => _riscoAmanha;
  List<DadosRisco> get previsaoAlargada => _previsaoAlargada;
  Concelho? get concelhoPrincipal => _concelhoPrincipal;
  Set<String> get favoritoDicos => _favoritoDicos;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  OrigemDados get origem => _origem;
  String? get erro => _erro;
  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

  /// Retorna se o cache local se encontra dentro do período válido de 2 horas
  bool get isCacheValido =>
      _ultimaAtualizacao != null &&
      DateTime.now().difference(_ultimaAtualizacao!) < cacheTtl &&
      _riscoHoje != null;

  /// Retorna se o cooldown de refresh forçado (30s) se encontra ativo
  bool get isCooldownForcarAtivo =>
      _ultimoPedidoRede != null &&
      DateTime.now().difference(_ultimoPedidoRede!) < cooldownForcar &&
      _riscoHoje != null;

  bool get autoLocalizacao => _autoLocalizacao;
  bool get isLocalizando => _isLocalizando;
  String? get mensagemLocalizacao => _mensagemLocalizacao;

  String get statusConexaoDescricao {
    if (_isOnline) {
      if (_ultimaAtualizacao != null) {
        final h = _ultimaAtualizacao!.hour.toString().padLeft(2, '0');
        final m = _ultimaAtualizacao!.minute.toString().padLeft(2, '0');
        return 'Online • Atualizado às $h:$m';
      }
      return 'Online • IPMA atualizado';
    } else {
      if (_ultimaAtualizacao != null) {
        final diff = DateTime.now().difference(_ultimaAtualizacao!);
        if (diff.inMinutes < 60) {
          final m = diff.inMinutes.clamp(1, 59);
          return 'Offline • Dados de há ${m}m';
        } else if (diff.inHours < 24) {
          return 'Offline • Dados de há ${diff.inHours}h';
        } else {
          final d = _ultimaAtualizacao!.day.toString().padLeft(2, '0');
          final m = _ultimaAtualizacao!.month.toString().padLeft(2, '0');
          return 'Offline • Registo de $d/$m';
        }
      }
      return 'Modo Offline • A usar cache';
    }
  }

  List<Concelho> get favoritos {
    return _concelhos
        .where((c) => _favoritoDicos.contains(c.dico))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  /// Initialize the provider: load concelhos, cached data, and favorites
  Future<void> inicializar() async {
    await _cacheService.init();
    await _carregarConcelhos();
    _carregarFavoritos();
    _carregarConcelhoPrincipal();
    _carregarAutoLocalizacao();
    await _carregarDadosDoCache();
    // Pré-carrega assincronamente as geometrias do mapa em background para abertura instantânea
    MapGeometryService().carregarGeometrias().catchError((e) {
      debugPrint('Aviso: pré-carregamento de geometrias: $e');
      return <ConcelhoGeometry>[];
    });

    // Se auto-localização estiver ativa (ou se não houver concelho no primeiro arranque),
    // tenta detetar a localização em background de forma resiliente
    if (_autoLocalizacao || _concelhoPrincipal == null) {
      detetarEDefinirLocalizacaoAtual(silencioso: true).catchError((e) {
        debugPrint('Deteção de localização no arranque: $e');
        return null;
      });
    }

    // Carrega dados da rede (se falhar, mantém _isOnline = false e preserva o cache)
    await carregarDados(silencioso: true, forcar: true);
    _iniciarAutoSync();
  }

  /// Inicia timer periódico para sincronização automática em segundo plano
  void _iniciarAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      verificarEAtualizarAutomatico();
    });
  }

  /// Verifica se os dados precisam de atualização automática (apenas quando o TTL expira)
  Future<void> verificarEAtualizarAutomatico() async {
    final agora = DateTime.now();
    final precisaAtualizar = _ultimaAtualizacao == null ||
        agora.difference(_ultimaAtualizacao!) >= cacheTtl ||
        !_isOnline;

    if (precisaAtualizar && !_isLoading) {
      debugPrint('Sincronização automática periódica (TTL de 2h expirado)...');
      await carregarDados(silencioso: true, forcar: true);
    }
  }

  /// Load concelhos from bundled asset
  Future<void> _carregarConcelhos() async {
    try {
      final jsonString = await rootBundle.loadString('assets/concelhos.json');
      final jsonList = json.decode(jsonString) as List<dynamic>;
      _concelhos = Concelho.fromJsonList(jsonList);
    } catch (e) {
      debugPrint('Erro ao carregar concelhos: $e');
    }
  }

  /// Load favorites from cache
  void _carregarFavoritos() {
    final dicos = _cacheService.carregarFavoritos();
    _favoritoDicos = dicos.toSet();
  }

  /// Load selected main concelho from cache
  void _carregarConcelhoPrincipal() {
    final dico = _cacheService.carregarConcelhoPrincipal();
    if (dico != null && _concelhos.isNotEmpty) {
      _concelhoPrincipal =
          _concelhos.where((c) => c.dico == dico).firstOrNull;
    }
  }

  /// Carrega os dados persistidos em cache via repositório para arranque imediato
  Future<void> _carregarDadosDoCache() async {
    _isOnline = false;
    final res = _repository.carregarDadosLocais();
    _riscoHoje = res.riscoHoje;
    _riscoAmanha = res.riscoAmanha;
    _previsaoAlargada = res.previsaoAlargada;
    _origem = res.origem;
    _isOnline = res.isOnline;
    _ultimaAtualizacao = res.ultimaAtualizacao;
    _erro = res.erro;
  }

  /// Sincroniza dados da rede via repositório mantendo o estado reativo da interface
  Future<void> carregarDados({bool silencioso = false, bool forcar = false}) async {
    if (_isLoading) return;

    if (!silencioso) {
      _isLoading = true;
      _erro = null;
      notifyListeners();
    }

    _ultimoPedidoRede = DateTime.now();

    try {
      final estadoAtual = ResultadoPrevisao(
        riscoHoje: _riscoHoje,
        riscoAmanha: _riscoAmanha,
        previsaoAlargada: _previsaoAlargada,
        origem: _origem,
        isOnline: _isOnline,
        ultimaAtualizacao: _ultimaAtualizacao,
      );

      final res = await _repository.sincronizarRede(estadoAtual: estadoAtual);

      _riscoHoje = res.riscoHoje;
      _riscoAmanha = res.riscoAmanha;
      _previsaoAlargada = res.previsaoAlargada;
      _origem = res.origem;
      _isOnline = res.isOnline;
      _ultimaAtualizacao = res.ultimaAtualizacao;

      if (!silencioso && _riscoHoje == null) {
        _erro = res.erro;
      } else {
        _erro = null;
      }
    } catch (e) {
      debugPrint('RiscoProvider: Erro ao carregar dados: $e');
      _isOnline = false;
      if (!silencioso && _riscoHoje == null) {
        _erro = 'Sem ligação à internet. A aguardar reconexão.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  /// Select a concelho as the main/primary one
  void selecionarConcelho(String dico) {
    _concelhoPrincipal =
        _concelhos.where((c) => c.dico == dico).firstOrNull;
    _cacheService.salvarConcelhoPrincipal(dico);
    notifyListeners();
  }

  /// Toggle a concelho as favorite
  void toggleFavorito(String dico) {
    if (_favoritoDicos.contains(dico)) {
      _favoritoDicos.remove(dico);
    } else {
      _favoritoDicos.add(dico);
    }
    _cacheService.salvarFavoritos(_favoritoDicos.toList());
    notifyListeners();
  }

  /// Check if a DICO is a favorite
  bool isFavorito(String dico) {
    return _favoritoDicos.contains(dico);
  }

  /// Get today's risk for a specific concelho
  RiscoLocal? getRiscoHoje(String dico) {
    return _riscoHoje?.getRisco(dico);
  }

  /// Get tomorrow's risk for a specific concelho
  RiscoLocal? getRiscoAmanha(String dico) {
    return _riscoAmanha?.getRisco(dico);
  }

  /// Get full multi-day forecast for a specific concelho
  List<RiscoPrevisaoDia> getPrevisaoDias(String dico) {
    if (_previsaoAlargada.isNotEmpty) {
      final list = <RiscoPrevisaoDia>[];
      for (int i = 0; i < _previsaoAlargada.length; i++) {
        final dados = _previsaoAlargada[i];
        final risco = dados.getRisco(dico);
        if (risco != null) {
          list.add(RiscoPrevisaoDia(
            diaIndex: i,
            dataPrev: dados.dataPrev,
            risco: risco,
          ));
        }
      }
      if (list.isNotEmpty) return list;
    }

    // Fallback: caso o scraper ainda não tenha corrido ou esteja vazio
    final list = <RiscoPrevisaoDia>[];
    final rHoje = getRiscoHoje(dico);
    if (rHoje != null) {
      list.add(RiscoPrevisaoDia(
        diaIndex: 0,
        dataPrev: _riscoHoje?.dataPrev ?? '',
        risco: rHoje,
      ));
    }
    final rAmanha = getRiscoAmanha(dico);
    if (rAmanha != null) {
      list.add(RiscoPrevisaoDia(
        diaIndex: 1,
        dataPrev: _riscoAmanha?.dataPrev ?? '',
        risco: rAmanha,
      ));
    }
    return list;
  }

  /// Carrega preferência de auto-localização do cache
  void _carregarAutoLocalizacao() {
    _autoLocalizacao = _cacheService.carregarAutoLocalizacao();
  }

  /// Alterna a opção de auto-localização e dispara deteção imediata se ativada
  Future<void> alternarAutoLocalizacao(bool ativo) async {
    _autoLocalizacao = ativo;
    await _cacheService.salvarAutoLocalizacao(ativo);
    notifyListeners();
    if (ativo) {
      await detetarEDefinirLocalizacaoAtual();
    }
  }

  /// Deteta o concelho atual do utilizador via GPS/IP e define como concelho principal
  Future<Concelho?> detetarEDefinirLocalizacaoAtual({bool silencioso = false}) async {
    if (_isLocalizando) return null;

    _isLocalizando = true;
    _mensagemLocalizacao = null;
    notifyListeners();

    try {
      final concelhoDetetado =
          await _localizacaoService.detetarConcelhoAtual(_concelhos);
      if (concelhoDetetado != null) {
        selecionarConcelho(concelhoDetetado.dico);
        _mensagemLocalizacao = 'Concelho detetado: ${concelhoDetetado.nome}';
        return concelhoDetetado;
      } else {
        if (!silencioso) {
          _mensagemLocalizacao =
              'Não foi possível determinar o concelho a partir da localização.';
        }
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao detetar concelho por localização: $e');
      if (!silencioso) {
        _mensagemLocalizacao = 'Erro ao aceder ao serviço de localização.';
      }
      return null;
    } finally {
      _isLocalizando = false;
      notifyListeners();
    }
  }
}
