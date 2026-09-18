import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/risco_incendio.dart';

/// Serviço isolado responsável por extrair a previsão alargada de 9 dias
/// a partir da página HTML do IPMA (web scraping).
///
/// Mantido completamente separado da API oficial para fácil manutenção
/// e garantia de fallback seguro caso o site mude.
class IpmaScraperService {
  static const String pageUrl = 'https://www.ipma.pt/pt/ambiente/risco.incendio/';

  final http.Client _client;

  IpmaScraperService({http.Client? client}) : _client = client ?? http.Client();

  /// Descarrega a página do IPMA e extrai a lista de previsões (até 9 dias).
  /// Na Web, utiliza proxies CORS transparentes de fallback para contornar
  /// a ausência de cabeçalhos CORS no servidor do IPMA.
  Future<List<DadosRisco>> fetchPrevisao9Dias() async {
    final urlsParaTentar = <String>[];

    if (!kIsWeb) {
      urlsParaTentar.add(pageUrl);
    }

    // Proxies CORS para Web ou fallback resiliente (com cors.eu.org prioritário)
    urlsParaTentar.addAll([
      'https://cors.eu.org/$pageUrl',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(pageUrl)}',
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(pageUrl)}',
    ]);

    if (kIsWeb) {
      // Também adiciona o direto no final caso o browser suporte ou ambiente permita
      urlsParaTentar.add(pageUrl);
    }

    for (final url in urlsParaTentar) {
      try {
        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final resultados = parseHtml(response.body);
          if (resultados.isNotEmpty) {
            return resultados;
          }
        }
      } catch (e) {
        debugPrint('IpmaScraperService: Falha na URL $url: $e');
        continue;
      }
    }

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
