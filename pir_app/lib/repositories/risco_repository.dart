import 'package:flutter/foundation.dart';

import '../models/risco_incendio.dart';
import '../services/cache_service.dart';
import '../services/ipma_api_service.dart';
import '../services/ipma_scraper_service.dart';
import '../utils/constants.dart';

/// Identifica a proveniência exata dos dados apresentados
enum OrigemDados {
  /// Dados frescos obtidos através da API central na Vercel (/api/v1/rcm-9dias)
  vercelApi,

  /// Dados obtidos por ligação direta ao IPMA (D0-D2 REST ou scraper nativo)
  ipmaDireto,

  /// Dados recuperados da persistência local NoSQL (Hive)
  cacheHive,

  /// Dados de contingência (modelo preditivo calibrado ou asset estático de emergência)
  estaticoFallback,
}

/// Objeto de transferência de dados que encapsula o estado de previsão
class ResultadoPrevisao {
  final DadosRisco? riscoHoje;
  final DadosRisco? riscoAmanha;
  final List<DadosRisco> previsaoAlargada;
  final OrigemDados origem;
  final bool isOnline;
  final DateTime? ultimaAtualizacao;
  final String? erro;

  const ResultadoPrevisao({
    this.riscoHoje,
    this.riscoAmanha,
    this.previsaoAlargada = const [],
    required this.origem,
    required this.isOnline,
    this.ultimaAtualizacao,
    this.erro,
  });

  bool get temDados => riscoHoje != null;
}

/// Repositório central (Repository Pattern) que orquestra fontes de dados
/// locais (Hive) e remotas (Vercel API / IPMA Oficial), garantindo resiliência.
class RiscoRepository {
  final IpmaApiService _apiService;
  final IpmaScraperService _scraperService;
  final CacheService _cacheService;

  RiscoRepository({
    IpmaApiService? apiService,
    IpmaScraperService? scraperService,
    CacheService? cacheService,
  })  : _apiService = apiService ?? IpmaApiService(),
        _scraperService = scraperService ?? IpmaScraperService(),
        _cacheService = cacheService ?? CacheService();

  /// Carrega os dados persistidos no Hive para arranque instantâneo sub-milissegundo
  ResultadoPrevisao carregarDadosLocais() {
    DadosRisco? riscoHoje;
    DadosRisco? riscoAmanha;
    List<DadosRisco> previsaoAlargada = [];
    DateTime? ultAtualizacao;

    try {
      // 1. Tentar primeiro o Snapshot Atómico Consolidado
      final snapshot = _cacheService.carregarSnapshotDiario();
      if (snapshot != null) {
        if (snapshot['rcm_d0'] != null) {
          riscoHoje = DadosRisco.fromJson(snapshot['rcm_d0'] as Map<String, dynamic>);
        }
        if (snapshot['rcm_d1'] != null) {
          riscoAmanha = DadosRisco.fromJson(snapshot['rcm_d1'] as Map<String, dynamic>);
        }
        final alargadaJson = snapshot['rcm_previsao_alargada'] as List<dynamic>?;
        if (alargadaJson != null && alargadaJson.isNotEmpty) {
          previsaoAlargada = alargadaJson
              .map((j) => DadosRisco.fromJson(j as Map<String, dynamic>))
              .toList();
        }
        if (snapshot['timestamp'] != null) {
          ultAtualizacao = DateTime.tryParse(snapshot['timestamp'] as String);
        }
      }

      // 2. Fallback retrocompatível se o snapshot ainda não existir
      if (riscoHoje == null) {
        final cacheHoje = _cacheService.carregarDadosRisco(CacheKeys.rcmD0);
        if (cacheHoje != null) {
          riscoHoje = DadosRisco.fromJson(cacheHoje);
        }
      }
      if (riscoAmanha == null) {
        final cacheAmanha = _cacheService.carregarDadosRisco(CacheKeys.rcmD1);
        if (cacheAmanha != null) {
          riscoAmanha = DadosRisco.fromJson(cacheAmanha);
        }
      }
      if (previsaoAlargada.isEmpty) {
        final cacheAlargada = _cacheService.carregarPrevisaoAlargada();
        if (cacheAlargada != null && cacheAlargada.isNotEmpty) {
          previsaoAlargada =
              cacheAlargada.map((j) => DadosRisco.fromJson(j)).toList();
        } else if (riscoHoje != null) {
          // Integridade: apenas dias oficiais disponíveis (sem projeção sintética)
          previsaoAlargada = [
            riscoHoje,
            if (riscoAmanha != null) riscoAmanha,
          ];
        }
      }

      ultAtualizacao ??= _cacheService.ultimaAtualizacao(CacheKeys.rcmD0);

      return ResultadoPrevisao(
        riscoHoje: riscoHoje,
        riscoAmanha: riscoAmanha,
        previsaoAlargada: previsaoAlargada,
        origem: riscoHoje != null ? OrigemDados.cacheHive : OrigemDados.estaticoFallback,
        isOnline: false,
        ultimaAtualizacao: ultAtualizacao,
      );
    } catch (e) {
      debugPrint('RiscoRepository: Erro ao carregar dados do Hive: $e');
      return const ResultadoPrevisao(
        origem: OrigemDados.estaticoFallback,
        isOnline: false,
        erro: 'Erro ao aceder à cache local.',
      );
    }
  }

  /// Sincroniza dados da rede (API oficial + Vercel /v1/) e atualiza a persistência local
  Future<ResultadoPrevisao> sincronizarRede({
    ResultadoPrevisao? estadoAtual,
  }) async {
    try {
      // 1. Dispara em simultâneo os pedidos à API oficial do IPMA e ao endpoint de 9 dias
      final apiFuture = Future.wait([
        _apiService.fetchRiscoHoje(),
        _apiService.fetchRiscoAmanha(),
        _apiService.fetchRiscoDepoisDeAmanha(),
      ]).then<List<DadosRisco>?>((v) => v).catchError((e) {
        debugPrint('RiscoRepository: Falha ao obter API oficial do IPMA: $e');
        return null;
      });

      final scraperFuture =
          _scraperService.fetchPrevisao9Dias().catchError((e) {
        debugPrint('RiscoRepository: Falha ao obter 9 dias da API central: $e');
        return <DadosRisco>[];
      });

      final apiResultados = await apiFuture;
      final scraperResultados = await scraperFuture;

      final redeSucesso =
          (apiResultados != null && apiResultados.length >= 2) ||
              scraperResultados.isNotEmpty;

      if (redeSucesso) {
        DadosRisco? riscoHoje;
        DadosRisco? riscoAmanha;
        List<DadosRisco> previsaoAlargada = [];

        if (apiResultados != null && apiResultados.length >= 2) {
          riscoHoje = apiResultados[0];
          riscoAmanha = apiResultados[1];
        } else if (scraperResultados.isNotEmpty) {
          riscoHoje = scraperResultados[0];
          if (scraperResultados.length > 1) {
            riscoAmanha = scraperResultados[1];
          }
        }

        if (scraperResultados.isNotEmpty) {
          previsaoAlargada = scraperResultados;
        } else if (riscoHoje != null) {
          // Integridade: Não fabricar FWI sintético para D+3..D+8.
          // Exibir estritamente os dias emitidos pelo IPMA (D0, D1 e D2 se disponível).
          final d2 = (apiResultados != null && apiResultados.length > 2)
              ? apiResultados[2]
              : null;
          previsaoAlargada = [
            riscoHoje,
            if (riscoAmanha != null) riscoAmanha,
            if (d2 != null) d2,
          ];
        }

        final agora = DateTime.now();

        // 2. Persiste atomicamente no Hive num Snapshot Único
        await _cacheService.salvarSnapshotDiario(
          d0: riscoHoje!.toJson(),
          d1: riscoAmanha?.toJson(),
          d2: (apiResultados != null && apiResultados.length > 2)
              ? apiResultados[2].toJson()
              : null,
          previsaoAlargada: previsaoAlargada.map((d) => d.toJson()).toList(),
          timestamp: agora,
        );

        final OrigemDados origemIdentificada;
        if (scraperResultados.isNotEmpty) {
          origemIdentificada = OrigemDados.vercelApi;
        } else if (apiResultados != null && apiResultados.isNotEmpty) {
          origemIdentificada = OrigemDados.ipmaDireto;
        } else {
          origemIdentificada = OrigemDados.estaticoFallback;
        }

        return ResultadoPrevisao(
          riscoHoje: riscoHoje,
          riscoAmanha: riscoAmanha,
          previsaoAlargada: previsaoAlargada,
          origem: origemIdentificada,
          isOnline: true,
          ultimaAtualizacao: agora,
        );
      } else {
        // Falha de rede: Preserva os dados do estado atual / cache
        final temDadosPrevios = estadoAtual?.temDados ?? false;
        return ResultadoPrevisao(
          riscoHoje: estadoAtual?.riscoHoje,
          riscoAmanha: estadoAtual?.riscoAmanha,
          previsaoAlargada: estadoAtual?.previsaoAlargada ?? [],
          origem: temDadosPrevios ? OrigemDados.cacheHive : OrigemDados.estaticoFallback,
          isOnline: false,
          ultimaAtualizacao: estadoAtual?.ultimaAtualizacao,
          erro: temDadosPrevios
              ? null
              : 'Sem ligação à internet. Serviço temporariamente inacessível.',
        );
      }
    } catch (e) {
      debugPrint('RiscoRepository: Exceção durante sincronização: $e');
      final temDadosPrevios = estadoAtual?.temDados ?? false;
      return ResultadoPrevisao(
        riscoHoje: estadoAtual?.riscoHoje,
        riscoAmanha: estadoAtual?.riscoAmanha,
        previsaoAlargada: estadoAtual?.previsaoAlargada ?? [],
        origem: temDadosPrevios ? OrigemDados.cacheHive : OrigemDados.estaticoFallback,
        isOnline: false,
        ultimaAtualizacao: estadoAtual?.ultimaAtualizacao,
        erro: temDadosPrevios
            ? null
            : 'Sem ligação à internet. A aguardar reconexão.',
      );
    }
  }

  void dispose() {
    _apiService.dispose();
    _scraperService.dispose();
  }
}
