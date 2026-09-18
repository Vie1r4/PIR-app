import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/concelho.dart';
import '../models/concelho_geometry.dart';
import '../models/risco_incendio.dart';
import '../services/cache_service.dart';
import '../services/ipma_api_service.dart';
import '../services/ipma_scraper_service.dart';
import '../services/localizacao_service.dart';
import '../services/map_geometry_service.dart';

class RiscoProvider extends ChangeNotifier {
  final IpmaApiService _apiService = IpmaApiService();
  final IpmaScraperService _scraperService = IpmaScraperService();
  final CacheService _cacheService = CacheService();
  final LocalizacaoService _localizacaoService = LocalizacaoService();

  List<Concelho> _concelhos = [];
  DadosRisco? _riscoHoje;
  DadosRisco? _riscoAmanha;
  List<DadosRisco> _previsaoAlargada = [];
  Concelho? _concelhoPrincipal;
  Set<String> _favoritoDicos = {};
  bool _isLoading = false;
  bool _isOnline = false;
  String? _erro;
  DateTime? _ultimaAtualizacao;
  Timer? _autoSyncTimer;

  // Estado de Geolocalização
  bool _autoLocalizacao = false;
  bool _isLocalizando = false;
  String? _mensagemLocalizacao;

  // Getters
  List<Concelho> get concelhos => _concelhos;
  DadosRisco? get riscoHoje => _riscoHoje;
  DadosRisco? get riscoAmanha => _riscoAmanha;
  List<DadosRisco> get previsaoAlargada => _previsaoAlargada;
  Concelho? get concelhoPrincipal => _concelhoPrincipal;
  Set<String> get favoritoDicos => _favoritoDicos;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get erro => _erro;
  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

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
        final d = _ultimaAtualizacao!.day.toString().padLeft(2, '0');
        final m = _ultimaAtualizacao!.month.toString().padLeft(2, '0');
        final h = _ultimaAtualizacao!.hour.toString().padLeft(2, '0');
        final min = _ultimaAtualizacao!.minute.toString().padLeft(2, '0');
        return 'Modo Offline • Registo de $d/$m às $h:$min';
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

    await carregarDados();
    _iniciarAutoSync();
  }

  /// Inicia timer periódico para sincronização automática em segundo plano a cada 30 minutos
  void _iniciarAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      verificarEAtualizarAutomatico();
    });
  }

  /// Verifica se os dados precisam de atualização automática (ao abrir a app ou após 20 min)
  Future<void> verificarEAtualizarAutomatico() async {
    final agora = DateTime.now();
    final precisaAtualizar = _ultimaAtualizacao == null ||
        agora.difference(_ultimaAtualizacao!) >= const Duration(minutes: 20) ||
        !_isOnline;

    if (precisaAtualizar && !_isLoading) {
      debugPrint('Sincronização automática em segundo plano iniciada...');
      await carregarDados(silencioso: true);
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

  /// Load cached risk data (for offline use)
  Future<void> _carregarDadosDoCache() async {
    _isOnline = false;
    try {
      final cacheHoje = _cacheService.carregarDadosRisco('rcm_d0');
      if (cacheHoje != null) {
        _riscoHoje = DadosRisco.fromJson(cacheHoje);
      }

      final cacheAmanha = _cacheService.carregarDadosRisco('rcm_d1');
      if (cacheAmanha != null) {
        _riscoAmanha = DadosRisco.fromJson(cacheAmanha);
      }

      final cacheAlargada = _cacheService.carregarPrevisaoAlargada();
      if (cacheAlargada != null && cacheAlargada.isNotEmpty) {
        _previsaoAlargada =
            cacheAlargada.map((j) => DadosRisco.fromJson(j)).toList();
      }

      _ultimaAtualizacao = _cacheService.ultimaAtualizacao('rcm_d0');
    } catch (e) {
      debugPrint('Erro ao carregar cache: $e');
    }
  }

  /// Fetch fresh data from the IPMA API and Scraper
  Future<void> carregarDados({bool silencioso = false}) async {
    if (!silencioso) {
      _isLoading = true;
      _erro = null;
      notifyListeners();
    }

    try {
      // 1. Executar API oficial e Scraper em simultâneo com tratamento isolado
      final apiFuture = Future.wait([
        _apiService.fetchRiscoHoje(),
        _apiService.fetchRiscoAmanha(),
      ]).then<List<DadosRisco>?>((v) => v).catchError((e) {
        debugPrint('Falha ao obter API oficial do IPMA: $e');
        return null;
      });

      final scraperFuture =
          _scraperService.fetchPrevisao9Dias().catchError((e) {
        debugPrint('Falha ao obter Scraper de 9 dias do IPMA: $e');
        return <DadosRisco>[];
      });

      final apiResultados = await apiFuture;
      final scraperResultados = await scraperFuture;

      final redeSucesso = (apiResultados != null && apiResultados.length >= 2) ||
          scraperResultados.isNotEmpty;

      if (apiResultados != null && apiResultados.length >= 2) {
        _riscoHoje = apiResultados[0];
        _riscoAmanha = apiResultados[1];
      } else if (scraperResultados.isNotEmpty) {
        // Fallback gracioso: usar os dados do scraper já descarregados sem 2º pedido HTTP
        _riscoHoje = scraperResultados[0];
        if (scraperResultados.length > 1) {
          _riscoAmanha = scraperResultados[1];
        }
      }

      if (scraperResultados.isNotEmpty) {
        _previsaoAlargada = scraperResultados;
        await _cacheService.salvarPrevisaoAlargada(
          _previsaoAlargada.map((d) => d.toJson()).toList(),
        );
      }

      // Se obtivemos dados (seja por API oficial ou Scraper fallback)
      if (redeSucesso && _riscoHoje != null && _riscoAmanha != null) {
        _isOnline = true;
        _ultimaAtualizacao = DateTime.now();
        await _cacheService.salvarDadosRisco('rcm_d0', _riscoHoje!.toJson());
        await _cacheService.salvarDadosRisco('rcm_d1', _riscoAmanha!.toJson());
        await _cacheService.salvarUltimaAtualizacao('rcm_d0');
        _erro = null;
      } else if (_riscoHoje == null) {
        _isOnline = false;
        if (!silencioso) {
          _erro =
              'Não foi possível atualizar os dados. A mostrar última informação disponível.';
        }
      } else {
        _isOnline = false;
      }
    } catch (e) {
      _isOnline = false;
      debugPrint('Erro ao carregar dados: $e');
      if (!silencioso) {
        _erro =
            'Não foi possível atualizar os dados. A mostrar última informação disponível.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
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
