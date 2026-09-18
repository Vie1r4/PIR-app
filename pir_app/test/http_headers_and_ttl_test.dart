import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/utils/constants.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/services/ipma_scraper_service.dart';

void main() {
  group('HttpHeadersConfig & Best Practices Tests', () {
    test('User-Agent contem identificacao do PIR-App e email de contacto', () {
      expect(HttpHeadersConfig.userAgent, contains('PIR-App/1.1.0'));
      expect(HttpHeadersConfig.userAgent, contains('shovieira@gmail.com'));
      expect(HttpHeadersConfig.userAgent, contains('github.com/Vie1r4/PIR-app'));
    });

    test('defaultHeaders e scraperHeaders incluem User-Agent obrigatorio', () {
      expect(HttpHeadersConfig.defaultHeaders['User-Agent'], equals(HttpHeadersConfig.userAgent));
      expect(HttpHeadersConfig.scraperHeaders['User-Agent'], equals(HttpHeadersConfig.userAgent));
      expect(HttpHeadersConfig.scraperHeaders['Accept-Language'], contains('pt-PT'));
    });

    test('RiscoProvider cacheTtl esta calibrado para 2 horas', () {
      expect(RiscoProvider.cacheTtl, equals(const Duration(hours: 2)));
    });

    test('RiscoProvider cooldownForcar anti-metralhadora esta calibrado para 30 segundos', () {
      expect(RiscoProvider.cooldownForcar, equals(const Duration(seconds: 30)));
    });

    test('IpmaScraperService inicia com circuit breaker inativo', () {
      final scraper = IpmaScraperService();
      expect(scraper.emBackoff, isFalse);
      expect(scraper.tempoRestanteBackoff, equals(Duration.zero));
    });
  });
}