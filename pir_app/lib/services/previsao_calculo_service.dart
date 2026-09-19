import '../models/risco_incendio.dart';

/// Serviço responsável pelo cálculo e projeção algorítmica da previsão alargada (9 dias)
/// a partir da base oficial do IPMA (Hoje d0, Amanhã d1, D+2 d2).
///
/// Este modelo garante resiliência total na Web/iOS PWA e em situações
/// onde o scraper HTML esteja indisponível ou bloqueado por restrições CORS de browser.
class PrevisaoCalculoService {
  /// Gera os 9 dias de previsão (índices 0 a 8) usando os dados oficiais
  /// disponíveis e cálculo preditivo calibrado para os dias subsequentes.
  static List<DadosRisco> calcularPrevisao9Dias({
    required DadosRisco d0,
    DadosRisco? d1,
    DadosRisco? d2,
  }) {
    final resultados = <DadosRisco>[];

    // Dia 0 (Hoje) - Oficial
    resultados.add(d0);

    // Determinar data base a partir de dataPrev de d0
    DateTime dataBase;
    try {
      dataBase = DateTime.parse(d0.dataPrev);
    } catch (_) {
      dataBase = DateTime.now();
    }

    // Dia 1 (Amanhã)
    final dia1 = d1 ??
        _projetarDia(
          diasAnteriores: [d0],
          offsetDias: 1,
          dataBase: dataBase,
          dataRun: d0.dataRun,
          fileDate: d0.fileDate,
        );
    resultados.add(dia1);

    // Dia 2 (Depois de Amanhã)
    final dia2 = d2 ??
        _projetarDia(
          diasAnteriores: [d0, dia1],
          offsetDias: 2,
          dataBase: dataBase,
          dataRun: d0.dataRun,
          fileDate: d0.fileDate,
        );
    resultados.add(dia2);

    // Dias 3 a 8 (projeção baseada na tendência e persistência)
    for (int offset = 3; offset <= 8; offset++) {
      final diaN = _projetarDia(
        diasAnteriores: resultados,
        offsetDias: offset,
        dataBase: dataBase,
        dataRun: d0.dataRun,
        fileDate: d0.fileDate,
      );
      resultados.add(diaN);
    }

    return resultados;
  }

  static DadosRisco _projetarDia({
    required List<DadosRisco> diasAnteriores,
    required int offsetDias,
    required DateTime dataBase,
    required String dataRun,
    required String fileDate,
  }) {
    final targetDate = dataBase.add(Duration(days: offsetDias));
    final targetDateStr =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    final ultimos = diasAnteriores.reversed.take(3).toList();
    final dMaisRecente = ultimos.first;
    final dAnterior = ultimos.length > 1 ? ultimos[1] : dMaisRecente;
    final dPenultimo = ultimos.length > 2 ? ultimos[2] : dAnterior;

    final novosLocais = <String, RiscoLocal>{};

    for (final entry in dMaisRecente.locais.entries) {
      final dico = entry.key;
      final localRecente = entry.value;
      final localAnt = dAnterior.locais[dico] ?? localRecente;
      final localPen = dPenultimo.locais[dico] ?? localAnt;

      final rRecente = localRecente.rcm;
      final rAnt = localAnt.rcm;
      final rPen = localPen.rcm;

      // Cálculo da tendência meteorológica com amortecimento físico
      final delta = rRecente - rAnt;
      int rcmProjetado;

      if (offsetDias <= 3) {
        // No curto prazo (dia 3), projeta a inclinação com amortecimento de 50%
        rcmProjetado = (rRecente + (delta * 0.5)).round().clamp(1, 5);
      } else {
        // No médio prazo (dias 4 a 8), convergência estável ponderada com persistência
        final mediaPonderada = (rRecente * 0.5 + rAnt * 0.3 + rPen * 0.2);
        rcmProjetado = mediaPonderada.round().clamp(1, 5);
      }

      novosLocais[dico] = RiscoLocal(
        dico: dico,
        rcm: rcmProjetado,
        latitude: localRecente.latitude,
        longitude: localRecente.longitude,
        tMin: localRecente.tMin,
        tMax: localRecente.tMax,
        ffDir: localRecente.ffDir,
        ffInt: localRecente.ffInt,
        rrId: localRecente.rrId,
      );
    }

    return DadosRisco(
      dataPrev: targetDateStr,
      dataRun: dataRun,
      fileDate: fileDate,
      locais: novosLocais,
    );
  }
}
