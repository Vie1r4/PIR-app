import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/acessibilidade_provider.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/widgets/modal_seletor_concelhos.dart';

class MockRiscoProviderParaModal extends ChangeNotifier implements RiscoProvider {
  String? concelhoSelecionadoDico;

  @override
  final List<Concelho> concelhos = const [
    Concelho(dico: '0101', nome: 'Águeda', distrito: 'Aveiro'),
    Concelho(dico: '0303', nome: 'Braga', distrito: 'Braga'),
    Concelho(dico: '1105', nome: 'Cascais', distrito: 'Lisboa'),
    Concelho(dico: '1312', nome: 'Porto', distrito: 'Porto'),
  ];

  @override
  final List<Concelho> favoritos = const [
    Concelho(dico: '0303', nome: 'Braga', distrito: 'Braga'),
  ];

  @override
  Concelho? get concelhoPrincipal => concelhos[1]; // Braga

  @override
  bool isFavorito(String dico) => dico == '0303';

  @override
  RiscoLocal? getRiscoHoje(String dico) => null;

  @override
  void selecionarConcelho(String dico) {
    concelhoSelecionadoDico = dico;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ModalSeletorConcelhos renderiza e filtra concelhos na pesquisa',
      (WidgetTester tester) async {
    final mockProvider = MockRiscoProviderParaModal();
    final accProvider = AcessibilidadeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AcessibilidadeProvider>.value(value: accProvider),
          ChangeNotifierProvider<RiscoProvider>.value(value: mockProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalSeletorConcelhos(),
          ),
        ),
      ),
    );

    // Verifica que o cabeçalho e campo de pesquisa estão visíveis
    expect(find.text('Trocar Concelho'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Inicialmente com a lista completa, os concelhos devem estar visíveis
    expect(find.text('Braga'), findsWidgets);
    expect(find.text('Cascais'), findsOneWidget);
    expect(find.text('Porto'), findsWidgets);

    // Digita "Cas" no campo de pesquisa
    await tester.enterText(find.byType(TextField), 'Cas');
    await tester.pumpAndSettle();

    // Deve encontrar Cascais e filtrar Porto
    expect(find.text('Cascais'), findsOneWidget);
    expect(find.text('Porto'), findsNothing);

    // Clica no concelho Cascais
    await tester.tap(find.text('Cascais'));
    await tester.pumpAndSettle();

    // Deve ter chamado selecionarConcelho('1105')
    expect(mockProvider.concelhoSelecionadoDico, '1105');
  });
}
