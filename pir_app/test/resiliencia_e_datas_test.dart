import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/repositories/risco_repository.dart';
import 'package:pir_app/services/cache_service.dart';
import 'package:pir_app/services/ipma_api_service.dart';
import 'package:pir_app/services/ipma_scraper_service.dart';
import 'package:pir_app/services/previsao_calculo_service.dart';
import 'package:pir_app/utils/risco_helpers.dart';

void main() {
  group('Resiliência Temporal & DST Tests', () {
    test('Cálculo de calendário mantém progressão de dias na noite de mudança de hora (DST)', () {
      // Simulação da noite de mudança de hora de Outono (Outubro de 2026)
      final noiteDst = DateTime(2026, 10, 25);
      final diaSeguinte = DateTime(noiteDst.year, noiteDst.month, noiteDst.day + 1);

      expect(diaSeguinte.year, equals(2026));
      expect(diaSeguinte.month, equals(10));
      expect(diaSeguinte.day, equals(26));
      expect(diaSeguinte.difference(noiteDst).inDays, equals(1));
    });

    test('PrevisaoCalculoService projeta datas civis consecutivas sem repetição', () {
      final d0 = DadosRisco(
        dataPrev: '2026-10-24',
        dataRun: '2026-10-24',
        fileDate: '2026-10-24 09:00:00',
        locais: {
          '0307': const RiscoLocal(
            dico: '0307',
            rcm: 2,
            latitude: 41.44,
            longitude: -8.17,
            tMin: 12.0,
            tMax: 22.0,
          ),
        },
      );

      final noveDias = PrevisaoCalculoService.calcularPrevisao9Dias(d0: d0);

      expect(noveDias.length, equals(9));
      expect(noveDias[0].dataPrev, equals('2026-10-24'));
      expect(noveDias[1].dataPrev, equals('2026-10-25')); // Noite de DST
      expect(noveDias[2].dataPrev, equals('2026-10-26')); // Dia pós-DST
      expect(noveDias[3].dataPrev, equals('2026-10-27'));
      expect(noveDias[8].dataPrev, equals('2026-11-01')); // Transição de mês
    });

    test('formatarRotuloDia valida semanticamente o dia civil e identifica boletim desatualizado', () {
      final referenciaHoje = DateTime(2026, 10, 9);

      // Boletim do próprio dia civil (D0)
      expect(
        formatarRotuloDia('2026-10-09', 0, agoraReferencia: referenciaHoje),
        equals('Hoje'),
      );

      // Boletim do dia seguinte (D1)
      expect(
        formatarRotuloDia('2026-10-10', 1, agoraReferencia: referenciaHoje),
        equals('Amanhã'),
      );

      // Boletim retido na cache do dia anterior (ontem) não pode mentir como "Hoje"
      expect(
        formatarRotuloDia('2026-10-08', 0, agoraReferencia: referenciaHoje),
        equals('Ontem (Desatualizado)'),
      );

      // Boletim de há 2 dias
      expect(
        formatarRotuloDia('2026-10-07', 0, agoraReferencia: referenciaHoje),
        contains('Desatualizado'),
      );
    });
  });

  group('Invariantes de Integridade & Proteção Civil', () {
    test('INVARIANTE 1: Valores nulos, anómalos ou fora de 1..5 nunca podem retornar NivelRisco.reduzido', () {
      expect(NivelRisco.tryFromRcm(null), isNull);
      expect(NivelRisco.tryFromRcm(0), isNull);
      expect(NivelRisco.tryFromRcm(-1), isNull);
      expect(NivelRisco.tryFromRcm(6), isNull);
      expect(NivelRisco.tryFromRcm(99), isNull);

      // fromRcmStrict deve lançar FormatException em violações físicas
      expect(() => NivelRisco.fromRcmStrict(0), throwsA(isA<FormatException>()));
      expect(() => NivelRisco.fromRcmStrict(-5), throwsA(isA<FormatException>()));
      expect(() => NivelRisco.fromRcmStrict(6), throwsA(isA<FormatException>()));

      // fromRcm (legado) agora também é estrito e lança FormatException
      expect(() => NivelRisco.fromRcm(0), throwsA(isA<FormatException>()));
      expect(() => NivelRisco.fromRcm(99), throwsA(isA<FormatException>()));

      // Valores oficiais 1 a 5 devem resolver estritamente
      expect(NivelRisco.tryFromRcm(1), equals(NivelRisco.reduzido));
      expect(NivelRisco.tryFromRcm(5), equals(NivelRisco.maximo));
    });

    test('INVARIANTE 2: RiscoLocal com RCM inválido tem nivelValido nulo e não induz falsa segurança', () {
      const localAnomalo = RiscoLocal(
        dico: '1106',
        rcm: 0, // Falta de leitura do sensor
        latitude: 38.7,
        longitude: -9.1,
      );
      expect(localAnomalo.nivelValido, isNull);

      // Invocação direta do getter nivel deve lançar StateError em anomalias
      expect(() => localAnomalo.nivel, throwsA(isA<StateError>()));
    });

    test('INVARIANTE 3 (Não-Fabricação): RiscoRepository restringe previsão estritamente a D0..D2 quando scraper de 9 dias falha', () async {
      final d0 = DadosRisco(
        dataPrev: '2026-10-09',
        dataRun: '2026-10-09',
        fileDate: '2026-10-09 09:00:00',
        locais: {'0307': const RiscoLocal(dico: '0307', rcm: 2, latitude: 41.4, longitude: -8.1)},
      );
      final d1 = DadosRisco(
        dataPrev: '2026-10-10',
        dataRun: '2026-10-09',
        fileDate: '2026-10-09 09:00:00',
        locais: {'0307': const RiscoLocal(dico: '0307', rcm: 3, latitude: 41.4, longitude: -8.1)},
      );
      final d2 = DadosRisco(
        dataPrev: '2026-10-11',
        dataRun: '2026-10-09',
        fileDate: '2026-10-09 09:00:00',
        locais: {'0307': const RiscoLocal(dico: '0307', rcm: 1, latitude: 41.4, longitude: -8.1)},
      );

      final repo = RiscoRepository(
        apiService: _MockIpmaApiValido(d0: d0, d1: d1, d2: d2),
        scraperService: _MockIpmaScraperFalha(),
        cacheService: _MockCacheMemoria(),
      );

      final resultado = await repo.sincronizarRede();

      expect(resultado.isOnline, isTrue);
      expect(resultado.origem, equals(OrigemDados.ipmaDireto));
      // Deve conter estritamente os 3 dias oficiais emitidos pelo IPMA (D0, D1, D2)
      expect(resultado.previsaoAlargada.length, equals(3));
      expect(resultado.previsaoAlargada.length, lessThanOrEqualTo(3));
      // Garante ausência total de extrapolações ou dados sintéticos para D+3..D+8
      expect(resultado.previsaoAlargada.length, isNot(equals(9)));
      expect(resultado.previsaoAlargada[0].dataPrev, equals('2026-10-09'));
      expect(resultado.previsaoAlargada[1].dataPrev, equals('2026-10-10'));
      expect(resultado.previsaoAlargada[2].dataPrev, equals('2026-10-11'));
    });
  });

  group('Tratamento Defensivo de DICOs', () {
    test('DICO ausente ou inexistente no feed retorna null de forma segura sem crashar', () {
      final dados = DadosRisco(
        dataPrev: '2026-10-09',
        dataRun: '2026-10-09',
        fileDate: '2026-10-09 09:00:00',
        locais: {
          '0307': const RiscoLocal(
            dico: '0307',
            rcm: 1,
            latitude: 41.44,
            longitude: -8.17,
          ),
        },
      );

      // Concelho existente
      expect(dados.getRisco('0307'), isNotNull);
      expect(dados.getRisco('0307')!.rcm, equals(1));

      // DICO inexistente ou com código alterado
      final riscoDesconhecido = dados.getRisco('9999');
      expect(riscoDesconhecido, isNull);

      // Tratamento seguro padrão no mapa
      final rcmDefensivo = riscoDesconhecido?.rcm ?? 0;
      expect(rcmDefensivo, equals(0));
    });
  });

  group('Parser HTML Defensivo Edge Cases', () {
    final scraper = IpmaScraperService();

    test('HTML vazio ou truncado retorna lista vazia sem lançar exceção', () {
      expect(scraper.parseHtml(''), isEmpty);
      expect(scraper.parseHtml('<html><body>Em manutenção</body></html>'), isEmpty);
      expect(scraper.parseHtml('rcmF[0] = { corrupt;'), isEmpty);
    });

    test('HTML com bloco parcial rcmF extrai apenas os blocos válidos', () {
      const htmlParcial = '''
        <script>
          rcmF[0] = {"dataPrev":"2026-10-09","dataRun":"2026-10-09","fileDate":"2026-10-09 09:00:00","local":{}};
          rcmF[1] = { corrupt json };
          rcmF[2] = {"dataPrev":"2026-10-11","dataRun":"2026-10-09","fileDate":"2026-10-09 09:00:00","local":{}};
        </script>
      ''';

      final resultados = scraper.parseHtml(htmlParcial);
      expect(resultados.length, equals(2));
      expect(resultados[0].dataPrev, equals('2026-10-09'));
      expect(resultados[1].dataPrev, equals('2026-10-11'));
    });
  });

  group('Repository Pattern Contracts', () {
    test('ResultadoPrevisao encapsula proveniência e integridade dos dados', () {
      const resultadoVazio = ResultadoPrevisao(
        origem: OrigemDados.estaticoFallback,
        isOnline: false,
        erro: 'Serviço temporariamente indisponível',
      );

      expect(resultadoVazio.temDados, isFalse);
      expect(resultadoVazio.origem, equals(OrigemDados.estaticoFallback));
      expect(resultadoVazio.erro, contains('indisponível'));

      // Validação de todos os casos do enum solicitado
      expect(OrigemDados.values, containsAll([
        OrigemDados.vercelApi,
        OrigemDados.ipmaDireto,
        OrigemDados.cacheHive,
        OrigemDados.estaticoFallback,
      ]));
    });
  });
}

class _MockIpmaApiValido extends IpmaApiService {
  final DadosRisco d0;
  final DadosRisco d1;
  final DadosRisco d2;

  _MockIpmaApiValido({
    required this.d0,
    required this.d1,
    required this.d2,
  });

  @override
  Future<DadosRisco> fetchRiscoHoje() async => d0;

  @override
  Future<DadosRisco> fetchRiscoAmanha() async => d1;

  @override
  Future<DadosRisco> fetchRiscoDepoisDeAmanha() async => d2;

  @override
  void dispose() {}
}

class _MockIpmaScraperFalha extends IpmaScraperService {
  @override
  Future<List<DadosRisco>> fetchPrevisao9Dias() async => [];

  @override
  void dispose() {}
}

class _MockCacheMemoria extends CacheService {
  @override
  Future<void> salvarSnapshotDiario({
    required Map<String, dynamic> d0,
    Map<String, dynamic>? d1,
    Map<String, dynamic>? d2,
    List<Map<String, dynamic>> previsaoAlargada = const [],
    required DateTime timestamp,
  }) async {}

  @override
  Map<String, dynamic>? carregarSnapshotDiario() => null;
}
