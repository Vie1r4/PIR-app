import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/services/previsao_calculo_service.dart';

void main() {
  group('PrevisaoCalculoService Tests', () {
    late DadosRisco d0;
    late DadosRisco d1;
    late DadosRisco d2;

    setUp(() {
      d0 = DadosRisco(
        dataPrev: '2026-09-19',
        dataRun: '2026-09-19 09:30:00',
        fileDate: '2026-09-19 09:30:00',
        locais: {
          '0307': const RiscoLocal(
            dico: '0307',
            rcm: 3,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 14.0,
            tMax: 26.0,
          ),
          '1106': const RiscoLocal(
            dico: '1106',
            rcm: 2,
            latitude: 38.72,
            longitude: -9.14,
            tMin: 16.0,
            tMax: 24.0,
          ),
        },
      );

      d1 = DadosRisco(
        dataPrev: '2026-09-20',
        dataRun: '2026-09-19 09:30:00',
        fileDate: '2026-09-19 09:30:00',
        locais: {
          '0307': const RiscoLocal(
            dico: '0307',
            rcm: 4,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 15.0,
            tMax: 28.0,
          ),
          '1106': const RiscoLocal(
            dico: '1106',
            rcm: 2,
            latitude: 38.72,
            longitude: -9.14,
            tMin: 17.0,
            tMax: 25.0,
          ),
        },
      );

      d2 = DadosRisco(
        dataPrev: '2026-09-21',
        dataRun: '2026-09-19 09:30:00',
        fileDate: '2026-09-19 09:30:00',
        locais: {
          '0307': const RiscoLocal(
            dico: '0307',
            rcm: 4,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 15.0,
            tMax: 29.0,
          ),
          '1106': const RiscoLocal(
            dico: '1106',
            rcm: 3,
            latitude: 38.72,
            longitude: -9.14,
            tMin: 18.0,
            tMax: 27.0,
          ),
        },
      );
    });

    test('calcularPrevisao9Dias gera exatamente 9 dias', () {
      final resultado = PrevisaoCalculoService.calcularPrevisao9Dias(
        d0: d0,
        d1: d1,
        d2: d2,
      );

      expect(resultado.length, equals(9));
      expect(resultado[0].dataPrev, equals('2026-09-19'));
      expect(resultado[1].dataPrev, equals('2026-09-20'));
      expect(resultado[2].dataPrev, equals('2026-09-21'));
      expect(resultado[3].dataPrev, equals('2026-09-22'));
      expect(resultado[8].dataPrev, equals('2026-09-27'));
    });

    test('preserva concelhos e mantem RCM dentro do intervalo [1, 5]', () {
      final resultado = PrevisaoCalculoService.calcularPrevisao9Dias(
        d0: d0,
        d1: d1,
        d2: d2,
      );

      for (int i = 0; i < resultado.length; i++) {
        final dia = resultado[i];
        expect(dia.locais.containsKey('0307'), isTrue);
        expect(dia.locais.containsKey('1106'), isTrue);

        final rcmFafe = dia.locais['0307']!.rcm;
        final rcmLisboa = dia.locais['1106']!.rcm;

        expect(rcmFafe, inInclusiveRange(1, 5));
        expect(rcmLisboa, inInclusiveRange(1, 5));
      }
    });

    test('funciona mesmo quando apenas d0 e d1 estao disponiveis', () {
      final resultado = PrevisaoCalculoService.calcularPrevisao9Dias(
        d0: d0,
        d1: d1,
      );

      expect(resultado.length, equals(9));
      expect(resultado[0].dataPrev, equals('2026-09-19'));
      expect(resultado[1].dataPrev, equals('2026-09-20'));
      expect(resultado[2].dataPrev, equals('2026-09-21'));
      expect(resultado.every((d) => d.locais.containsKey('0307')), isTrue);
    });

    test('funciona mesmo quando apenas d0 esta disponivel', () {
      final resultado = PrevisaoCalculoService.calcularPrevisao9Dias(
        d0: d0,
      );

      expect(resultado.length, equals(9));
      expect(resultado[0].dataPrev, equals('2026-09-19'));
      expect(resultado[8].dataPrev, equals('2026-09-27'));
      expect(resultado.every((d) => d.locais.containsKey('0307')), isTrue);
    });
  });
}
