import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/utils/risco_helpers.dart';

void main() {
  group('formatarRotuloDia', () {
    test('Dia 0 é Hoje e Dia 1 é Amanhã', () {
      expect(formatarRotuloDia('2026-09-05', 0), equals('Hoje'));
      expect(formatarRotuloDia('2026-09-06', 1), equals('Amanhã'));
    });

    test('Dias subsequentes formatam semana e dia/mês', () {
      // 2026-09-07 é Segunda-feira
      final rotuloCompleto = formatarRotuloDia('2026-09-07', 2, incluirMes: true);
      expect(rotuloCompleto, contains('Seg'));
      expect(rotuloCompleto, contains('7'));
      expect(rotuloCompleto, contains('Set'));

      final rotuloCurto = formatarRotuloDia('2026-09-07', 2, incluirMes: false);
      expect(rotuloCurto, equals('Seg, 7'));
    });
  });

  group('obterRestricoesRisco', () {
    test('Nível Reduzido e Moderado autorizam queimas com comunicação prévia', () {
      final r1 = obterRestricoesRisco(1);
      final r2 = obterRestricoesRisco(2);

      expect(r1.queimasPermitidas, isTrue);
      expect(r2.queimasPermitidas, isTrue);
      expect(r1.maquinariaCondicionada, isFalse);
    });

    test('Nível Elevado (3) tem condicionantes e autorização', () {
      final r3 = obterRestricoesRisco(3);
      expect(r3.queimasPermitidas, isTrue);
      expect(r3.maquinariaCondicionada, isTrue);
      expect(r3.queimas, contains('autorização municipal'));
    });

    test('Nível Muito Elevado (4) e Máximo (5) proíbem queimas e pirotecnia', () {
      final r4 = obterRestricoesRisco(4);
      final r5 = obterRestricoesRisco(5);

      expect(r4.queimasPermitidas, isFalse);
      expect(r5.queimasPermitidas, isFalse);
      expect(r4.pirotecniaPermitida, isFalse);
      expect(r5.pirotecniaPermitida, isFalse);
      expect(r4.queimas, contains('PROIBIDAS'));
      expect(r5.queimas, contains('PROIBIDAS'));
    });
  });
}
