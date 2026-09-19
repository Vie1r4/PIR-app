import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/services/map_geometry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapGeometryService Tests', () {
    final service = MapGeometryService();

    test('project converte coordenadas geográficas em Offsets válidos', () {
      final p1 = MapGeometryService.project(-9.1393, 38.7223); // Lisboa
      expect(p1.dx.isFinite, isTrue);
      expect(p1.dy.isFinite, isTrue);
      expect(p1.dx, greaterThan(0));
      expect(p1.dx, lessThan(MapGeometryService.canvasWidth));
      expect(p1.dy, greaterThan(0));
      expect(p1.dy, lessThan(MapGeometryService.canvasHeight));
    });

    test('carregarGeometrias carrega os 278 concelhos de Portugal Continental', () async {
      final geometrias = await service.carregarGeometrias();
      expect(geometrias.length, equals(278));

      final lisboa = geometrias.where((g) => g.dico == '1106').firstOrNull;
      expect(lisboa, isNotNull);
      expect(lisboa!.nome.toUpperCase(), equals('LISBOA'));
    });

    test('encontrarPorCoordenadas identifica corretamente Lisboa', () async {
      final geom = await service.encontrarPorCoordenadas(38.7223, -9.1393);
      expect(geom, isNotNull);
      expect(geom!.nome.toUpperCase(), equals('LISBOA'));
      expect(geom.dico, equals('1106'));
    });

    test('encontrarPorCoordenadas identifica corretamente Porto', () async {
      final geom = await service.encontrarPorCoordenadas(41.1579, -8.6291);
      expect(geom, isNotNull);
      expect(geom!.nome.toUpperCase(), equals('PORTO'));
      expect(geom.dico, equals('1312'));
    });

    test('encontrarPorCoordenadas identifica corretamente Coimbra', () async {
      final geom = await service.encontrarPorCoordenadas(40.2033, -8.4103);
      expect(geom, isNotNull);
      expect(geom!.nome.toUpperCase(), equals('COIMBRA'));
      expect(geom.dico, equals('0603'));
    });

    test('encontrarPorCoordenadas identifica corretamente Faro', () async {
      final geom = await service.encontrarPorCoordenadas(37.0194, -7.9304);
      expect(geom, isNotNull);
      expect(geom!.nome.toUpperCase(), equals('FARO'));
      expect(geom.dico, equals('0805'));
    });

    test('encontrarPorCoordenadas identifica corretamente Évora', () async {
      final geom = await service.encontrarPorCoordenadas(38.5714, -7.9135);
      expect(geom, isNotNull);
      expect(geom!.nome.toUpperCase(), equals('ÉVORA'));
      expect(geom.dico, equals('0705'));
    });

    test('encontrarPorCoordenadas devolve null para coordenadas fora de Portugal', () async {
      // Nova Iorque
      final fora1 = await service.encontrarPorCoordenadas(40.7128, -74.0060);
      expect(fora1, isNull);

      // Paris
      final fora2 = await service.encontrarPorCoordenadas(48.8566, 2.3522);
      expect(fora2, isNull);

      // Tóquio
      final fora3 = await service.encontrarPorCoordenadas(35.6762, 139.6503);
      expect(fora3, isNull);
    });

    test('allBordersPath está pré-compilado e contém as fronteiras de Portugal', () async {
      await service.carregarGeometrias();
      final borders = service.allBordersPath;
      expect(borders.getBounds().isEmpty, isFalse);
      expect(borders.getBounds().width, greaterThan(200));
      expect(borders.getBounds().height, greaterThan(400));
    });

    test('obterGroupedPaths memoiza caminhos por carimbo e dados de risco', () async {
      await service.carregarGeometrias();
      final paths1 = service.obterGroupedPaths(null);
      expect(paths1, isNotEmpty);
      expect(paths1.containsKey(0), isTrue);

      // Chamar uma segunda vez deve devolver a mesma instância em cache
      final paths2 = service.obterGroupedPaths(null);
      expect(identical(paths1, paths2), isTrue);

      service.limparCacheCaminhos();
      final paths3 = service.obterGroupedPaths(null);
      expect(paths3, isNotEmpty);
    });
  });
}
