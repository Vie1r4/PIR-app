import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pir_app/services/cache_service.dart';
import 'package:pir_app/services/localizacao_service.dart';

void main() {
  group('Localizacao Model & Cache Tests', () {
    late Directory tempDir;
    late CacheService cacheService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pir_test_cache_');
      Hive.init(tempDir.path);
      cacheService = CacheService();
      await cacheService.init();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('CoordenadasGps inicializa e formata toString corretamente', () {
      const coords = CoordenadasGps(
        latitude: 38.7223,
        longitude: -9.1393,
        fonte: 'GPS',
      );

      expect(coords.latitude, equals(38.7223));
      expect(coords.longitude, equals(-9.1393));
      expect(coords.fonte, equals('GPS'));
      expect(coords.toString(), contains('38.7223'));
      expect(coords.toString(), contains('GPS'));
    });

    test('CacheService persiste e recupera preferência de auto-localização', () async {
      // Valor por defeito deve ser falso
      expect(cacheService.carregarAutoLocalizacao(), isFalse);

      // Salvar como verdadeiro
      await cacheService.salvarAutoLocalizacao(true);
      expect(cacheService.carregarAutoLocalizacao(), isTrue);

      // Salvar como falso novamente
      await cacheService.salvarAutoLocalizacao(false);
      expect(cacheService.carregarAutoLocalizacao(), isFalse);
    });
  });
}
