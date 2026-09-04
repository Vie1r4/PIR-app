import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pir_app/app.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/risco_provider.dart';

class MockRiscoProvider extends ChangeNotifier implements RiscoProvider {
  @override
  final List<Concelho> concelhos = [];

  @override
  final List<Concelho> favoritos = [];

  @override
  List<DadosRisco> get previsaoAlargada => [];

  @override
  DadosRisco? get riscoHoje => null;

  @override
  DadosRisco? get riscoAmanha => null;

  @override
  Concelho? get concelhoPrincipal => null;

  @override
  String? get erro => null;

  @override
  bool get isLoading => false;

  @override
  DateTime? get ultimaAtualizacao => null;

  @override
  List<RiscoPrevisaoDia> getPrevisaoDias(String dico) => [];

  @override
  bool isFavorito(String dico) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockProvider = MockRiscoProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<RiscoProvider>.value(
        value: mockProvider,
        child: const PirApp(),
      ),
    );

    expect(find.textContaining('Incêndio Rural'), findsAtLeastNWidgets(1));
  });
}
