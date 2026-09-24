import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/risco_incendio.dart';
import '../utils/constants.dart';

/// Serviço isolado responsável por extrair a previsão alargada de 9 dias
/// a partir da página HTML do IPMA (web scraping) ou asset estático pré-sincronizado.
///
/// Mantido completamente separado da API oficial para fácil manutenção
/// e garantia de fallback seguro caso o site mude.
class IpmaScraperService {
  /// Endpoint direto JSP que responde em HTTPS 200 OK sem redirecionamentos HTTP 302.
  /// Previne bloqueio por App Transport Security (ATS) no iOS.
  static const String pageUrl = 'https://www.ipma.pt/pt/riscoincendio/rcm.pt/index.jsp';
  static const String legacyPageUrl = 'https://www.ipma.pt/pt/ambiente/risco.incendio/';

  final http.Client _client;

  // Mecanismo de Circuit Breaker & Exponential Backoff anti-WAF
  int _falhasConsecutivas = 0;
  DateTime? _proximaTentativaPermitida;

  IpmaScraperService({http.Client? client}) : _client = client ?? http.Client();

  /// Indica se o scraper está em período de arrefecimento (cooldown/backoff)
  bool get emBackoff =>
      _proximaTentativaPermitida != null &&
      DateTime.now().isBefore(_proximaTentativaPermitida!);

  /// Tempo restante de backoff
  Duration get tempoRestanteBackoff =>
      emBackoff ? _proximaTentativaPermitida!.difference(DateTime.now()) : Duration.zero;

  /// Descarrega a página do IPMA ou o ficheiro de dados pré-sincronizado e extrai a lista de previsões (até 9 dias).
  /// Na Web, utiliza assets empacotados, raw GitHub (com CORS) ou proxies de fallback.
  Future<List<DadosRisco>> fetchPrevisao9Dias() async {
    // 1. Verificar Circuit Breaker / Backoff
    if (emBackoff) {
      debugPrint(
        'IpmaScraperService: Circuit Breaker ativo (faltam ${tempoRestanteBackoff.inSeconds}s). A poupar pedidos HTML.',
      );
      return [];
    }

    // 2. Tentar primeiro o asset empacotado pré-sincronizado (mesmo domínio no Web PWA ou nativo)
    try {
      final staticJson = await rootBundle.loadString('assets/data/rcm-9dias.json');
      if (staticJson.isNotEmpty) {
        final resultados = parsePayload(staticJson);
        if (resultados.isNotEmpty) {
          final dataPrimeiro = resultados.first.dataPrev;
          final dtPrimeiro = DateTime.tryParse(dataPrimeiro);
          if (dtPrimeiro != null &&
              dtPrimeiro.isAfter(DateTime.now().subtract(const Duration(days: 2)))) {
            debugPrint(
              'IpmaScraperService: 9 dias carregados com sucesso a partir de asset estático ($dataPrimeiro).',
            );
            return resultados;
          }
        }
      }
    } catch (e) {
      debugPrint('IpmaScraperService: Asset estático indisponível ou em carregamento: $e');
    }

    final urlsParaTentar = <String>[];

    // No nativo (iOS/Android/Desktop), tentar sempre o IPMA diretamente primeiro
    if (!kIsWeb) {
      urlsParaTentar.add(pageUrl);
      urlsParaTentar.add(legacyPageUrl);
    }

    // Fallbacks para Web (Raw GitHub CORS limpo, proxies)
    urlsParaTentar.addAll([
      'https://raw.githubusercontent.com/Vie1r4/PIR-app/main/pir_app/assets/data/rcm-9dias.json',
      'https://cors.eu.org/$pageUrl',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(pageUrl)}',
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(pageUrl)}',
      if (kIsWeb) pageUrl,
    ]);

    final timeout = kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 12);

    for (final url in urlsParaTentar) {
      try {
        final response = await _client.get(
          Uri.parse(url),
          headers: HttpHeadersConfig.scraperHeaders,
        ).timeout(timeout);

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final resultados = parsePayload(response.body);
          if (resultados.isNotEmpty) {
            _falhasConsecutivas = 0;
            _proximaTentativaPermitida = null;
            return resultados;
          }
        } else {
          debugPrint('IpmaScraperService: Código ${response.statusCode} em $url. A tentar próximo fallback...');
        }
      } catch (e) {
        debugPrint('IpmaScraperService: Falha na URL $url: $e');
        continue;
      }
    }

    _falhasConsecutivas++;
    final segundosEspera = (60 * (1 << (_falhasConsecutivas - 1))).clamp(60, 180);
    _proximaTentativaPermitida = DateTime.now().add(Duration(seconds: segundosEspera));
    debugPrint('IpmaScraperService: Todos os endpoints falharam. Arrefecimento de ${segundosEspera}s.');

    return [];
  }

  /// Processa o conteúdo (seja um JSON estático ou o HTML da página do IPMA)
  List<DadosRisco> parsePayload(String content) {
    if (content.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          final resultados = <DadosRisco>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              resultados.add(DadosRisco.fromJson(item));
            }
          }
          if (resultados.isNotEmpty) return resultados;
        }
      } catch (e) {
        debugPrint('IpmaScraperService: Falha ao fazer parse de JSON simples: $e');
      }
    }
    return parseHtml(content);
  }

  /// Extrai os blocos de dados `rcmF[0]` ... `rcmF[8]` a partir do código HTML.
  /// Método público para facilitar testes unitários independentes.
  List<DadosRisco> parseHtml(String html) {
    final resultados = <DadosRisco>[];

    // Expressão regular para capturar cada atribuição rcmF[x] = {...};
    final regex = RegExp(r'rcmF\[(\d+)\]\s*=\s*(\{.*?\});', dotAll: true);
    final matches = regex.allMatches(html).toList();

    // Ordenar pelas posições de índice (0, 1, 2, ..., 8)
    matches.sort((a, b) {
      final idxA = int.tryParse(a.group(1) ?? '') ?? 0;
      final idxB = int.tryParse(b.group(1) ?? '') ?? 0;
      return idxA.compareTo(idxB);
    });

    for (final match in matches) {
      final jsonStr = match.group(2);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          resultados.add(DadosRisco.fromJson(decoded));
        } catch (e) {
          debugPrint('IpmaScraperService: Erro ao fazer parse de um dos blocos JSON: $e');
        }
      }
    }

    return resultados;
  }

  void dispose() {
    _client.close();
  }
}
