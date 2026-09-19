import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pir_app/models/concelho.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/acessibilidade_provider.dart';
import 'package:pir_app/providers/risco_provider.dart';
import 'package:pir_app/screens/map_screen.dart';
import 'package:pir_app/services/map_geometry_service.dart';

class TestRiscoProvider extends ChangeNotifier implements RiscoProvider {
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
  bool get isLoading => false;
  @override
  DateTime? get ultimaAtualizacao => null;
  @override
  bool get isCacheValido => false;
  @override
  String get statusConexaoDescricao => 'Online';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Map drag test with mouse on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.runAsync(() async {
      await MapGeometryService().carregarGeometrias();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RiscoProvider>(create: (_) => TestRiscoProvider()),
          ChangeNotifierProvider<AcessibilidadeProvider>(create: (_) => AcessibilidadeProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MapScreen(showAppBar: false)),
        ),
      ),
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final ivFinder = find.byType(InteractiveViewer);
    expect(ivFinder, findsOneWidget);

    final iv = tester.widget<InteractiveViewer>(ivFinder);
    final initialMatrix = iv.transformationController?.value.clone() ?? Matrix4.identity();
    final initialTranslation = initialMatrix.getTranslation();

    // Drag with mouse left (-100, 0)
    final center = tester.getCenter(ivFinder);
    final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    final afterDragLeft = iv.transformationController?.value.clone() ?? Matrix4.identity();

    // Drag with mouse right (+200, 0)
    final gesture2 = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
    await gesture2.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture2.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture2.up();
    await tester.pump(const Duration(milliseconds: 100));

    final afterDragRight = iv.transformationController?.value.clone() ?? Matrix4.identity();
    expect(afterDragLeft.getTranslation().x, lessThan(initialTranslation.x));
    expect(afterDragRight.getTranslation().x, greaterThan(afterDragLeft.getTranslation().x));
  });
}
