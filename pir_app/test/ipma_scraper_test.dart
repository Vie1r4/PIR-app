import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/services/ipma_scraper_service.dart';

void main() {
  group('IpmaScraperService', () {
    test('parseHtml extrai corretamente os blocos rcmF', () {
      const htmlSnippet = '''
      <html>
      <script>
      var rcmF= new Array();
      rcmF[0] = {"dataPrev": "2026-09-03", "dataRun": "2026-09-02", "fileDate": "2026-09-03 09:35:02", "local": {"1106": {"data": {"rcm": 4, "tMax": 30.5, "tMin": 18.2}, "latitude": 38.7, "longitude": -9.1}}};
      rcmF[1] = {"dataPrev": "2026-09-04", "dataRun": "2026-09-02", "fileDate": "2026-09-03 09:35:02", "local": {"1106": {"data": {"rcm": 5, "tMax": 32.0, "tMin": 19.0}, "latitude": 38.7, "longitude": -9.1}}};
      </script>
      </html>
      ''';

      final scraper = IpmaScraperService();
      final resultados = scraper.parseHtml(htmlSnippet);

      expect(resultados.length, equals(2));
      expect(resultados[0].dataPrev, equals('2026-09-03'));
      expect(resultados[1].dataPrev, equals('2026-09-04'));

      final riscoHoje = resultados[0].getRisco('1106');
      expect(riscoHoje, isNotNull);
      expect(riscoHoje!.rcm, equals(4));
      expect(riscoHoje.tMax, equals(30.5));
      expect(riscoHoje.tMin, equals(18.2));

      final riscoAmanha = resultados[1].getRisco('1106');
      expect(riscoAmanha, isNotNull);
      expect(riscoAmanha!.rcm, equals(5));
      expect(riscoAmanha.tMax, equals(32.0));
    });

    test('parseHtml com o ficheiro real do IPMA extrai 9 dias e 278 concelhos', () {
      final file = File('ipma_page.html');
      if (!file.existsSync()) return;

      final bytes = file.readAsBytesSync();
      // Tenta decodificar com utf-8 ou latin1 dependendo de como o ficheiro foi guardado
      String html;
      try {
        html = utf8.decode(bytes);
      } catch (_) {
        html = latin1.decode(bytes);
      }
      final scraper = IpmaScraperService();
      final resultados = scraper.parseHtml(html);

      expect(resultados.length, equals(9));
      for (final dados in resultados) {
        expect(dados.locais.length, equals(278));
        expect(dados.dataPrev, isNotEmpty);
      }
    });
  });
}
