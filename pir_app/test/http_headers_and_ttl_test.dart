import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/risco_incendio.dart';
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

    test('defaultHeaders e scraperHeaders incluem User-Agent obrigatorio e Compressao Gzip/Brotli', () {
      expect(HttpHeadersConfig.defaultHeaders['User-Agent'], equals(HttpHeadersConfig.userAgent));
      expect(HttpHeadersConfig.defaultHeaders['Accept-Encoding'], contains('gzip'));
      expect(HttpHeadersConfig.scraperHeaders['User-Agent'], equals(HttpHeadersConfig.userAgent));
      expect(HttpHeadersConfig.scraperHeaders['Accept-Language'], contains('pt-PT'));
      expect(HttpHeadersConfig.scraperHeaders['Accept-Encoding'], contains('gzip'));
    });

    test('RiscoProvider cacheTtl esta calibrado para 2 horas', () {
      expect(RiscoProvider.cacheTtl, equals(const Duration(hours: 2)));
    });

    test('RiscoProvider cooldownForcar anti-metralhadora esta calibrado para 30 segundos', () {
      expect(RiscoProvider.cooldownForcar, equals(const Duration(seconds: 30)));
    });

    test('IpmaScraperService inicia com circuit breaker inativo e aponta para endpoint direto HTTPS', () {
      final scraper = IpmaScraperService();
      expect(scraper.emBackoff, isFalse);
      expect(scraper.tempoRestanteBackoff, equals(Duration.zero));
      expect(IpmaScraperService.pageUrl, equals('https://www.ipma.pt/pt/riscoincendio/rcm.pt/index.jsp'));
      expect(IpmaScraperService.pageUrl, startsWith('https://'));
    });

    test('Accept-Encoding nao contem Brotli (br) para compatibilidade nativa com iOS HttpClient', () {
      expect(HttpHeadersConfig.defaultHeaders['Accept-Encoding'], isNot(contains('br')));
      expect(HttpHeadersConfig.scraperHeaders['Accept-Encoding'], isNot(contains('br')));
      expect(HttpHeadersConfig.scraperHeaders['Accept-Encoding'], equals('gzip, deflate'));
    });

    test('DadosRisco.dataAtualizacaoOficial faz parse correto do carimbo do IPMA', () {
      const dados = DadosRisco(
        dataPrev: '2026-09-18',
        dataRun: '2026-09-18',
        fileDate: '2026-09-18 09:35:02',
        locais: {},
      );
      expect(dados.dataAtualizacaoOficial, isNotNull);
      expect(dados.dataAtualizacaoOficial!.year, equals(2026));
      expect(dados.dataAtualizacaoOficial!.month, equals(9));
      expect(dados.dataAtualizacaoOficial!.day, equals(18));
      expect(dados.dataAtualizacaoOficial!.hour, equals(9));
      expect(dados.dataAtualizacaoOficial!.minute, equals(35));
    });
  });
}