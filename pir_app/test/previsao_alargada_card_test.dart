import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/widgets/previsao_alargada_card.dart';

void main() {
  group('PrevisaoAlargadaCard Widget Tests', () {
    late List<RiscoPrevisaoDia> diasTeste;

    setUp(() {
      diasTeste = [
        const RiscoPrevisaoDia(
          diaIndex: 1,
          dataPrev: '2026-09-20',
          risco: RiscoLocal(
            dico: '0307',
            rcm: 3,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 14,
            tMax: 26,
          ),
        ),
        const RiscoPrevisaoDia(
          diaIndex: 2,
          dataPrev: '2026-09-21',
          risco: RiscoLocal(
            dico: '0307',
            rcm: 4,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 15,
            tMax: 28,
          ),
        ),
        const RiscoPrevisaoDia(
          diaIndex: 3,
          dataPrev: '2026-09-22',
          risco: RiscoLocal(
            dico: '0307',
            rcm: 2,
            latitude: 41.45,
            longitude: -8.17,
            tMin: 13,
            tMax: 24,
          ),
        ),
      ];
    });

    testWidgets('renderiza em modo compacto inicialmente e alterna para expandido ao tocar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrevisaoAlargadaCard(
              dias: diasTeste,
              initialExpanded: false,
            ),
          ),
        ),
      );

      // Verifica cabeçalho e botão inicial "Ver lista"
      expect(find.text('PRÓXIMOS DIAS'), findsOneWidget);
      expect(find.text('3 dias'), findsOneWidget);
      expect(find.text('Ver lista'), findsOneWidget);

      // Toca no botão para expandir
      await tester.tap(find.text('Ver lista'));
      await tester.pumpAndSettle();

      // Agora deve exibir o botão "Minimizar"
      expect(find.text('Minimizar'), findsOneWidget);
      expect(find.text('Minimizar previsão'), findsOneWidget);

      // Toca em "Minimizar previsão" para recolher
      await tester.tap(find.text('Minimizar previsão'));
      await tester.pumpAndSettle();

      expect(find.text('Ver lista'), findsOneWidget);
    });
  });
}
