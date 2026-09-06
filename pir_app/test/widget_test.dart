import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pir_app/app.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/acessibilidade_provider.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/providers/tema_provider.dart';

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
  Set<String> get favoritoDicos => {};

  @override
  DateTime? get ultimaAtualizacao => null;

  @override
  bool get isOnline => true;

  @override
  String get statusConexaoDescricao => 'Online';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App starts and renders correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockProvider = MockRiscoProvider();
    final temaProvider = TemaProvider(ThemeMode.system);
    final accProvider = AcessibilidadeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TemaProvider>.value(value: temaProvider),
          ChangeNotifierProvider<AcessibilidadeProvider>.value(value: accProvider),
          ChangeNotifierProvider<RiscoProvider>.value(value: mockProvider),
        ],
        child: const PirApp(),
      ),
    );

    // Verifica que a app renderizou o MaterialApp correctamente
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
