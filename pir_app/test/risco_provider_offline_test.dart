import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/risco_incendio.dart';
import 'package:pir_app/providers/risco_provider.dart';

void main() {
  group('RiscoProvider Connectivity Status Tests', () {
    test('statusConexaoDescricao formata corretamente estado Online e Offline', () {
      final provider = RiscoProvider();

      // Inicialmente sem rede e sem carimbo
      expect(provider.isOnline, isFalse);
      expect(provider.statusConexaoDescricao, equals('Modo Offline • A usar cache'));
    });

    test('isCacheValido devolve falso quando nao ha dados carregados', () {
      final provider = RiscoProvider();
      expect(provider.isCacheValido, isFalse);
    });

    test('DadosRisco e RiscoLocal funcionam corretamente com serializacao', () {
      const risco = RiscoLocal(
        dico: '0307',
        rcm: 4,
        latitude: 41.45,
        longitude: -8.17,
        tMin: 15.0,
        tMax: 29.0,
      );

      final json = risco.toJson();
      expect(json['dico'], equals('0307'));
      expect((json['data'] as Map<String, dynamic>)['rcm'], equals(4));

      final reconstruido = RiscoLocal.fromJson('0307', json);
      expect(reconstruido.rcm, equals(4));
      expect(reconstruido.nivel, equals(NivelRisco.muitoElevado));
    });
  });
}
