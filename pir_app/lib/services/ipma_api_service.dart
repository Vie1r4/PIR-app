import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/risco_incendio.dart';
import '../utils/constants.dart';

/// Service for fetching fire risk data from the IPMA API
class IpmaApiService {
  final http.Client _client;

  IpmaApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch today's risk data
  Future<DadosRisco> fetchRiscoHoje() async {
    return _fetchRisco(ApiUrls.rcmHoje);
  }

  /// Fetch tomorrow's risk data
  Future<DadosRisco> fetchRiscoAmanha() async {
    return _fetchRisco(ApiUrls.rcmAmanha);
  }

  /// Fetch day after tomorrow's risk data (D+2)
  Future<DadosRisco> fetchRiscoDepoisDeAmanha() async {
    return _fetchRisco(ApiUrls.rcmDepoisDeAmanha);
  }

  /// Internal method to fetch and parse risk data from a URL with web CORS fallback
  Future<DadosRisco> _fetchRisco(String url) async {
    final urlsParaTentar = <String>[];

    // No nativo e como 1ª tentativa na web
    urlsParaTentar.add(url);

    // Na Web, adicionar proxies transparentes de fallback caso o browser bloqueie por CORS
    if (kIsWeb) {
      urlsParaTentar.addAll([
        'https://cors.eu.org/$url',
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}',
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}',
      ]);
    }

    Exception? ultimoErro;
    final timeout = kIsWeb ? const Duration(seconds: 4) : const Duration(seconds: 6);

    for (final targetUrl in urlsParaTentar) {
      try {
        final response = await _client
            .get(
              Uri.parse(targetUrl),
              headers: HttpHeadersConfig.defaultHeaders,
            )
            .timeout(timeout);

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return DadosRisco.fromJson(json);
        } else {
          ultimoErro = Exception(
            'Erro ao obter dados do IPMA (código ${response.statusCode}) em $targetUrl',
          );
        }
      } catch (e) {
        ultimoErro = Exception('Falha na comunicação com o IPMA em $targetUrl: $e');
        debugPrint('IpmaApiService: Falha na URL $targetUrl: $e');

        // Se for erro de ausência de rede no dispositivo, não insiste em proxies
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('xmlhttprequest') ||
            errStr.contains('socketexception') ||
            errStr.contains('failed to fetch') ||
            errStr.contains('networkerror') ||
            errStr.contains('clientexception')) {
          break;
        }
        continue;
      }
    }

    throw ultimoErro ?? Exception('Falha ao obter dados do IPMA.');
  }

  void dispose() {
    _client.close();
  }
}
