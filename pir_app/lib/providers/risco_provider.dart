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
import '../services/previsao_calculo_service.dart';

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

    // Carrega dados respeitando o TTL do cache local
    await carregarDados();
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
      } else if (_riscoHoje != null) {
        // Se a previsão alargada não estava em cache, projeta imediatamente para nunca ficar com 2 dias
        _previsaoAlargada = PrevisaoCalculoService.calcularPrevisao9Dias(
          d0: _riscoHoje!,
          d1: _riscoAmanha,
        );
      }

      _ultimaAtualizacao = _cacheService.ultimaAtualizacao('rcm_d0');
    } catch (e) {
      debugPrint('Erro ao carregar cache: $e');
    }
  }

  /// Fetch fresh data from the IPMA API and Scraper.
  /// Se [forcar] for false e o cache local for válido (< 2 horas), evita pedidos de rede desnecessários.
  Future<void> carregarDados({bool silencioso = false, bool forcar = false}) async {
    // 1. Se o cache for válido (< 2h) e não for um pedido forçado, usa os dados locais
    if (!forcar && isCacheValido) {
      debugPrint('RiscoProvider: Cache local válido (< 2h). Pedido HTTP ao IPMA poupado.');
      _isOnline = true;
      _isLoading = false;
      _erro = null;
      notifyListeners();
      return;
    }

    // 2. Proteção Anti-Metralhadora: Cooldown de 30s para pull-to-refresh
    if (forcar && isCooldownForcarAtivo) {
      debugPrint('RiscoProvider: Cooldown de pull-to-refresh ativo (< 30s). A responder via cache local.');
      if (!silencioso) {
        _isLoading = true;
        notifyListeners();
        // Pequena animação suave de 300ms para feedback tátil antes de retornar
        await Future.delayed(const Duration(milliseconds: 300));
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (!silencioso) {
      _isLoading = true;
      _erro = null;
      notifyListeners();
    }

    // Registar timestamp da tentativa de rede
    _ultimoPedidoRede = DateTime.now();

    try {
      // 1. Executar API oficial (D0, D1 e D2) e Scraper em paralelo
      final apiFuture = Future.wait([
        _apiService.fetchRiscoHoje(),
        _apiService.fetchRiscoAmanha(),
        _apiService.fetchRiscoDepoisDeAmanha(),
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

      if (apiResultados != null && apiResultados.length >= 2) {
        _riscoHoje = apiResultados[0];
        _riscoAmanha = apiResultados[1];
        final d2 = apiResultados.length > 2 ? apiResultados[2] : null;

        // Se ainda não temos a previsão de 9 dias (ou era vazia),
        // calcula imediatamente a partir da base oficial (0ms de latência percebida)
        if (_previsaoAlargada.isEmpty || _previsaoAlargada.length < 9) {
          _previsaoAlargada = PrevisaoCalculoService.calcularPrevisao9Dias(
            d0: _riscoHoje!,
            d1: _riscoAmanha,
            d2: d2,
          );
          _isOnline = true;
          _ultimaAtualizacao = DateTime.now();
          notifyListeners();
        }
      }

      final scraperResultados = await scraperFuture;

      final redeSucesso = (apiResultados != null && apiResultados.length >= 2) ||
          scraperResultados.isNotEmpty;

      if (scraperResultados.isNotEmpty) {
        // Fallback gracioso: usar os dados do scraper já descarregados
        _riscoHoje ??= scraperResultados[0];
        if (scraperResultados.length > 1) {
          _riscoAmanha ??= scraperResultados[1];
        }
        // Se o scraper do site do IPMA obteve os 9 dias, adota esses valores
        _previsaoAlargada = scraperResultados;
      } else if (_riscoHoje != null && (_previsaoAlargada.isEmpty || _previsaoAlargada.length < 9)) {
        // Garantia de 9 dias: cálculo algorítmico robusto a partir da base oficial
        final d2 = (apiResultados != null && apiResultados.length > 2)
            ? apiResultados[2]
            : null;
        _previsaoAlargada = PrevisaoCalculoService.calcularPrevisao9Dias(
          d0: _riscoHoje!,
          d1: _riscoAmanha,
          d2: d2,
        );
      }

      if (_previsaoAlargada.isNotEmpty) {
        await _cacheService.salvarPrevisaoAlargada(
          _previsaoAlargada.map((d) => d.toJson()).toList(),
        );
      }

      // Se obtivemos dados novos com sucesso
      if (redeSucesso && _riscoHoje != null && _riscoAmanha != null) {
        _isOnline = true;
        _ultimaAtualizacao = DateTime.now();
        await _cacheService.salvarDadosRisco('rcm_d0', _riscoHoje!.toJson());
        await _cacheService.salvarDadosRisco('rcm_d1', _riscoAmanha!.toJson());
        if (apiResultados != null && apiResultados.length > 2) {
          await _cacheService.salvarDadosRisco('rcm_d2', apiResultados[2].toJson());
        }
        await _cacheService.salvarUltimaAtualizacao('rcm_d0');
        _erro = null;
      } else {
        // Stale-While-Revalidate: preserva dados em cache anteriores intactos
        _isOnline = false;
        _ultimaAtualizacao ??= _cacheService.ultimaAtualizacao('rcm_d0');
        if (!silencioso && _riscoHoje == null) {
          _erro = 'Sem ligação à internet. Não existem dados em cache.';
        } else {
          _erro = null; // Mantém os dados visíveis com aviso de idade no badge
        }
      }
    } catch (e) {
      // Stale-While-Revalidate: falha de socket/rede não apaga cache
      _isOnline = false;
      _ultimaAtualizacao ??= _cacheService.ultimaAtualizacao('rcm_d0');
      debugPrint('Erro ao carregar dados: $e');
      if (!silencioso && _riscoHoje == null) {
        _erro = 'Sem ligação à internet. A aguardar reconexão.';
      } else {
        _erro = null;
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
