import 'dart:convert';
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

  /// Internal method to fetch and parse risk data from a URL
  Future<DadosRisco> _fetchRisco(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DadosRisco.fromJson(json);
      } else {
        throw Exception(
          'Erro ao obter dados do IPMA (código ${response.statusCode})',
        );
      }
    } on Exception catch (e) {
      throw Exception('Falha na comunicação com o IPMA: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
