import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    print('Recolhendo previsao de 9 dias do IPMA...');
    final req = await client.getUrl(Uri.parse('https://www.ipma.pt/pt/riscoincendio/rcm.pt/index.jsp'));
    final res = await req.close();
    final html = await res.transform(utf8.decoder).join();

    final regex = RegExp(r'rcmF\[(\d+)\]\s*=\s*(\{.*?\});', dotAll: true);
    final matches = regex.allMatches(html).toList();

    matches.sort((a, b) {
      final idxA = int.tryParse(a.group(1) ?? '') ?? 0;
      final idxB = int.tryParse(b.group(1) ?? '') ?? 0;
      return idxA.compareTo(idxB);
    });

    final resultadosJson = <Map<String, dynamic>>[];
    for (final match in matches) {
      final jsonStr = match.group(2);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          resultadosJson.add(decoded);
        } catch (e) {
          print('Erro no parse do bloco: $e');
        }
      }
    }

    if (resultadosJson.isNotEmpty) {
      final targetDir = Directory('assets/data');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }
      final file = File('assets/data/rcm-9dias.json');
      file.writeAsStringSync(jsonEncode(resultadosJson));
      print('Sucesso: ${resultadosJson.length} dias extraidos e guardados em ${file.path}!');
      print('Primeiro dia: ${resultadosJson.first['dataPrev']} | Ultimo dia: ${resultadosJson.last['dataPrev']}');
    } else {
      print('Aviso: Nenhum bloco rcmF foi encontrado no HTML.');
    }
  } catch (e) {
    print('Erro ao sincronizar dados do IPMA: $e');
  } finally {
    client.close();
  }
}
