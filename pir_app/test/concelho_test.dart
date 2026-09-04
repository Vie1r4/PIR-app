import 'package:flutter_test/flutter_test.dart';
import 'package:pir_app/models/concelho.dart';

void main() {
  group('Concelho matchesSearch', () {
    const agueda = Concelho(dico: '0101', nome: 'Águeda', distrito: 'Aveiro');
    const braganca = Concelho(dico: '0402', nome: 'Bragança', distrito: 'Bragança');
    const evora = Concelho(dico: '0705', nome: 'Évora', distrito: 'Évora');
    const santarem = Concelho(dico: '1416', nome: 'Santarém', distrito: 'Santarém');

    test('Exact match', () {
      expect(agueda.matchesSearch('Águeda'), isTrue);
    });

    test('Case-insensitive match', () {
      expect(agueda.matchesSearch('águeda'), isTrue);
      expect(agueda.matchesSearch('AGUEDA'), isTrue);
    });

    test('Accent-tolerant match', () {
      expect(agueda.matchesSearch('agueda'), isTrue);
      expect(braganca.matchesSearch('braganca'), isTrue);
      expect(evora.matchesSearch('evora'), isTrue);
      expect(santarem.matchesSearch('santarem'), isTrue);
    });

    test('Partial match', () {
      expect(santarem.matchesSearch('santa'), isTrue);
      expect(braganca.matchesSearch('ganc'), isTrue);
    });

    test('Distrito match', () {
      expect(agueda.matchesSearch('aveiro'), isTrue);
      expect(agueda.matchesSearch('Aveiro'), isTrue);
    });

    test('Non-matching query', () {
      expect(agueda.matchesSearch('Lisboa'), isFalse);
    });
  });
}
