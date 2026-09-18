import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/acessibilidade_provider.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/screens/favoritos_screen.dart';
import 'package:pir_app/widgets/concelho_tile.dart';
import 'package:provider/provider.dart';

class MockRiscoProvider extends ChangeNotifier implements RiscoProvider {
  @override
  List<Concelho> get favoritos => [
        const Concelho(dico: '1106', nome: 'Lisboa', distrito: 'Lisboa'),
        const Concelho(dico: '1312', nome: 'Porto', distrito: 'Porto'),
        const Concelho(dico: '0603', nome: 'Coimbra', distrito: 'Coimbra'),
      ];

  @override
  RiscoLocal? getRiscoHoje(String dico) => null;

  @override
  bool isFavorito(String dico) => true;

  @override
  void toggleFavorito(String dico) {}

  @override
  void selecionarConcelho(String dico) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('FavoritosScreen exibe campo de pesquisa e filtra favoritos',
      (WidgetTester tester) async {
    final mockProvider = MockRiscoProvider();
    final accProvider = AcessibilidadeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RiscoProvider>.value(value: mockProvider),
          ChangeNotifierProvider<AcessibilidadeProvider>.value(value: accProvider),
        ],
        child: const MaterialApp(
          home: FavoritosScreen(),
        ),
      ),
    );

    expect(find.byType(ConcelhoTile), findsNWidgets(3));

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Porto');
    await tester.pumpAndSettle();

    expect(find.byType(ConcelhoTile), findsOneWidget);

    await tester.enterText(searchField, 'Braga');
    await tester.pumpAndSettle();

    expect(find.byType(ConcelhoTile), findsNothing);
    expect(find.textContaining('Nenhum concelho encontrado'), findsOneWidget);
  });
}
