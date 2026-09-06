import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/providers/acessibilidade_provider.dart';

void main() {
  group('EscalaTextoApp Enum Tests', () {
    test('Valores de escala e rótulos estão calibrados corretamente', () {
      expect(EscalaTextoApp.pequeno.fator, 0.88);
      expect(EscalaTextoApp.pequeno.rotulo, 'Pequeno');

      expect(EscalaTextoApp.normal.fator, 1.0);
      expect(EscalaTextoApp.normal.rotulo, 'Normal');

      expect(EscalaTextoApp.grande.fator, 1.20);
      expect(EscalaTextoApp.grande.rotulo, 'Grande');

      expect(EscalaTextoApp.gigante.fator, 1.40);
      expect(EscalaTextoApp.gigante.rotulo, 'Gigante');
    });

    test('fromString mapeia chaves e garante compatibilidade retroativa', () {
      expect(EscalaTextoApp.fromString('pequeno'), EscalaTextoApp.pequeno);
      expect(EscalaTextoApp.fromString('normal'), EscalaTextoApp.normal);
      expect(EscalaTextoApp.fromString('grande'), EscalaTextoApp.grande);
      expect(EscalaTextoApp.fromString('gigante'), EscalaTextoApp.gigante);
      // Compatibilidade legada com 'muitoGrande'
      expect(EscalaTextoApp.fromString('muitoGrande'), EscalaTextoApp.gigante);
      // Valores nulos ou desconhecidos revertem para normal
      expect(EscalaTextoApp.fromString(null), EscalaTextoApp.normal);
      expect(EscalaTextoApp.fromString('invalido'), EscalaTextoApp.normal);
    });

    test('toChave serializa corretamente para persistência', () {
      expect(EscalaTextoApp.pequeno.toChave(), 'pequeno');
      expect(EscalaTextoApp.normal.toChave(), 'normal');
      expect(EscalaTextoApp.grande.toChave(), 'grande');
      expect(EscalaTextoApp.gigante.toChave(), 'gigante');
    });
  });

  group('AcessibilidadeProvider Tests', () {
    test('Valores iniciais por defeito', () {
      final provider = AcessibilidadeProvider();
      expect(provider.escalaTexto, EscalaTextoApp.normal);
      expect(provider.textScaleFactor, 1.0);
      expect(provider.altoContraste, false);
      expect(provider.elementosGrandes, false);
      expect(provider.reduzirAnimacoes, false);
      expect(provider.dicasContextuais, true);
      expect(provider.paddingExtra, 0.0);
      expect(provider.minTouchTarget, 44.0);
    });

    test('Construtor com parâmetros personalizados', () {
      final provider = AcessibilidadeProvider(
        escalaTexto: EscalaTextoApp.gigante,
        altoContraste: true,
        elementosGrandes: true,
        reduzirAnimacoes: true,
        dicasContextuais: false,
      );
      expect(provider.escalaTexto, EscalaTextoApp.gigante);
      expect(provider.textScaleFactor, 1.40);
      expect(provider.altoContraste, true);
      expect(provider.elementosGrandes, true);
      expect(provider.reduzirAnimacoes, true);
      expect(provider.dicasContextuais, false);
      expect(provider.paddingExtra, 4.0);
      expect(provider.minTouchTarget, 52.0);
    });
  });
}
