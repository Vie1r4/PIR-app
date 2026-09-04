import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/screens/search_screen.dart';
import 'package:pir_app/widgets/concelho_tile.dart';

// Simple mock/fake provider for testing search screen
class FakeRiscoProvider extends ChangeNotifier implements RiscoProvider {
  @override
  final List<Concelho> concelhos = [
    const Concelho(dico: '0101', nome: 'Águeda', distrito: 'Aveiro'),
    const Concelho(dico: '0303', nome: 'Braga', distrito: 'Braga'),
    const Concelho(dico: '0705', nome: 'Évora', distrito: 'Évora'),
    const Concelho(dico: '1106', nome: 'Lisboa', distrito: 'Lisboa'),
  ];

  @override
  bool isFavorito(String dico) => false;

  @override
  RiscoLocal? getRiscoHoje(String dico) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SearchScreen filters concelhos without throwing errors', (tester) async {
    final fakeProvider = FakeRiscoProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<RiscoProvider>.value(
        value: fakeProvider,
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    // Initial state: shows 4 concelhos
    expect(find.byType(ConcelhoTile), findsNWidgets(4));

    // Type 'evora' (without accents)
    await tester.enterText(find.byType(TextField), 'evora');
    await tester.pump();

    // Should find Évora and filter out others without any blank screen or exception
    expect(find.byType(ConcelhoTile), findsOneWidget);
    expect(find.text('Évora'), findsNWidgets(2));
  });
}
