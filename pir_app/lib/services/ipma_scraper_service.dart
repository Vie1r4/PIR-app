import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/risco_incendio.dart';
import '../utils/constants.dart';

/// Serviço isolado responsável por extrair a previsão alargada de 9 dias
/// a partir da página HTML do IPMA (web scraping).
///
/// Mantido completamente separado da API oficial para fácil manutenção
/// e garantia de fallback seguro caso o site mude.
class IpmaScraperService {
  static const String pageUrl = 'https://www.ipma.pt/pt/ambiente/risco.incendio/';

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

  /// Descarrega a página do IPMA e extrai a lista de previsões (até 9 dias).
  /// Na Web, utiliza proxies CORS transparentes de fallback para contornar
  /// a ausência de cabeçalhos CORS no servidor do IPMA.
  Future<List<DadosRisco>> fetchPrevisao9Dias() async {
    // 1. Verificar Circuit Breaker / Backoff
    if (emBackoff) {
      debugPrint(
        'IpmaScraperService: Circuit Breaker ativo (faltam ${tempoRestanteBackoff.inSeconds}s). A poupar pedidos HTML.',
      );
      return [];
    }

    final urlsParaTentar = <String>[];

    // No nativo (iOS/Android/Desktop), tentar sempre o IPMA diretamente primeiro
    if (!kIsWeb) {
      urlsParaTentar.add(pageUrl);
    }

    // Proxies CORS para Web e fallback resiliente
    urlsParaTentar.addAll([
      'https://cors.eu.org/$pageUrl',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(pageUrl)}',
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(pageUrl)}',
      if (kIsWeb) pageUrl,
    ]);

    for (final url in urlsParaTentar) {
      try {
        final response = await _client.get(
          Uri.parse(url),
          headers: HttpHeadersConfig.scraperHeaders,
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final resultados = parseHtml(response.body);
          if (resultados.isNotEmpty) {
            // Sucesso: repor contadores de backoff
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

    // Se todos os proxies falharem, ativar backoff curto de 1 minuto
    _falhasConsecutivas++;
    final segundosEspera = (60 * (1 << (_falhasConsecutivas - 1))).clamp(60, 600);
    _proximaTentativaPermitida = DateTime.now().add(Duration(seconds: segundosEspera));
    debugPrint('IpmaScraperService: Todos os endpoints falharam. Backoff de ${segundosEspera}s.');

    return [];
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
