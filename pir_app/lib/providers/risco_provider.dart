import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/concelho.dart';
import '../models/risco_incendio.dart';
import '../services/cache_service.dart';
import '../services/ipma_api_service.dart';
import '../services/ipma_scraper_service.dart';

class RiscoProvider extends ChangeNotifier {
  final IpmaApiService _apiService = IpmaApiService();
  final IpmaScraperService _scraperService = IpmaScraperService();
  final CacheService _cacheService = CacheService();

  List<Concelho> _concelhos = [];
  DadosRisco? _riscoHoje;
  DadosRisco? _riscoAmanha;
  List<DadosRisco> _previsaoAlargada = [];
  Concelho? _concelhoPrincipal;
  Set<String> _favoritoDicos = {};
  bool _isLoading = false;
  String? _erro;
  DateTime? _ultimaAtualizacao;

  // Getters
  List<Concelho> get concelhos => _concelhos;
  DadosRisco? get riscoHoje => _riscoHoje;
  DadosRisco? get riscoAmanha => _riscoAmanha;
  List<DadosRisco> get previsaoAlargada => _previsaoAlargada;
  Concelho? get concelhoPrincipal => _concelhoPrincipal;
  Set<String> get favoritoDicos => _favoritoDicos;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

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
    await _carregarDadosDoCache();
    await carregarDados();
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
      _concelhoPrincipal = _concelhos.cast<Concelho?>().firstWhere(
            (c) => c!.dico == dico,
            orElse: () => null,
          );
    }
  }

  /// Load cached risk data (for offline use)
  Future<void> _carregarDadosDoCache() async {
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
  Future<void> carregarDados() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      // 1. Puxar API oficial de Hoje e Amanhã
      final apiFuture = Future.wait([
        _apiService.fetchRiscoHoje(),
        _apiService.fetchRiscoAmanha(),
      ]);

      // 2. Em simultâneo, puxar a previsão alargada de 9 dias via Scraper
      final scraperFuture = _scraperService.fetchPrevisao9Dias();

      final resultados = await Future.wait([apiFuture, scraperFuture]);
      final apiResultados = resultados[0];
      final scraperResultados = resultados[1];

      _riscoHoje = apiResultados[0];
      _riscoAmanha = apiResultados[1];

      if (scraperResultados.isNotEmpty) {
        _previsaoAlargada = scraperResultados;
        await _cacheService.salvarPrevisaoAlargada(
          _previsaoAlargada.map((d) => d.toJson()).toList(),
        );
      }

      _ultimaAtualizacao = DateTime.now();

      // Guardar na cache
      await _cacheService.salvarDadosRisco('rcm_d0', _riscoHoje!.toJson());
      await _cacheService.salvarDadosRisco('rcm_d1', _riscoAmanha!.toJson());
      await _cacheService.salvarUltimaAtualizacao('rcm_d0');

      _erro = null;
    } catch (e) {
      // Se a API oficial falhou, tenta usar os dados do scraper como fallback
      try {
        final scraperResultados = await _scraperService.fetchPrevisao9Dias();
        if (scraperResultados.isNotEmpty) {
          _previsaoAlargada = scraperResultados;
          _riscoHoje = scraperResultados[0];
          if (scraperResultados.length > 1) {
            _riscoAmanha = scraperResultados[1];
          }
          _ultimaAtualizacao = DateTime.now();
          _erro = null;
        } else {
          _erro =
              'Não foi possível atualizar os dados. A mostrar última informação disponível.';
        }
      } catch (_) {
        _erro =
            'Não foi possível atualizar os dados. A mostrar última informação disponível.';
      }
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a concelho as the main/primary one
  void selecionarConcelho(String dico) {
    _concelhoPrincipal = _concelhos.cast<Concelho?>().firstWhere(
          (c) => c!.dico == dico,
          orElse: () => null,
        );
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
}
