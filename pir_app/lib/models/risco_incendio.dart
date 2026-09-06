import '../utils/risco_helpers.dart';

/// Nível de risco de incêndio rural
enum NivelRisco {
  reduzido(1, 'Reduzido'),
  moderado(2, 'Moderado'),
  elevado(3, 'Elevado'),
  muitoElevado(4, 'Muito Elevado'),
  maximo(5, 'Máximo');

  final int valor;
  final String label;

  const NivelRisco(this.valor, this.label);

  static NivelRisco fromRcm(int rcm) {
    return NivelRisco.values.firstWhere(
      (n) => n.valor == rcm,
      orElse: () => NivelRisco.reduzido,
    );
  }
}

/// Risco de incêndio para um local específico
class RiscoLocal {
  final String dico;
  final int rcm;
  final double latitude;
  final double longitude;
  final double? tMin;
  final double? tMax;
  final String? ffDir;
  final int? ffInt;
  final int? rrId;

  const RiscoLocal({
    required this.dico,
    required this.rcm,
    required this.latitude,
    required this.longitude,
    this.tMin,
    this.tMax,
    this.ffDir,
    this.ffInt,
    this.rrId,
  });

  NivelRisco get nivel => NivelRisco.fromRcm(rcm);

  factory RiscoLocal.fromJson(String dico, Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final tMinVal = (data['tMin'] as num?)?.toDouble();
    final tMaxVal = (data['tMax'] as num?)?.toDouble();
    return RiscoLocal(
      dico: dico,
      rcm: data['rcm'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      tMin: (tMinVal != null && tMinVal > -90) ? tMinVal : null,
      tMax: (tMaxVal != null && tMaxVal > -90) ? tMaxVal : null,
      ffDir: data['ff_dir_id'] as String?,
      ffInt: data['ff_int_id'] as int?,
      rrId: data['rr_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'rcm': rcm,
          if (tMin != null) 'tMin': tMin,
          if (tMax != null) 'tMax': tMax,
          if (ffDir != null) 'ff_dir_id': ffDir,
          if (ffInt != null) 'ff_int_id': ffInt,
          if (rrId != null) 'rr_id': rrId,
        },
        'dico': dico,
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// Dados de risco completos de uma resposta da API
class DadosRisco {
  final String dataPrev;
  final String dataRun;
  final String fileDate;
  final Map<String, RiscoLocal> locais;

  const DadosRisco({
    required this.dataPrev,
    required this.dataRun,
    required this.fileDate,
    required this.locais,
  });

  /// Get risk data for a specific concelho by DICO code
  RiscoLocal? getRisco(String dico) => locais[dico];

  factory DadosRisco.fromJson(Map<String, dynamic> json) {
    final localMap = json['local'] as Map<String, dynamic>;
    final locais = <String, RiscoLocal>{};

    for (final entry in localMap.entries) {
      locais[entry.key] = RiscoLocal.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }

    return DadosRisco(
      dataPrev: json['dataPrev'] as String,
      dataRun: json['dataRun'] as String,
      fileDate: json['fileDate'] as String,
      locais: locais,
    );
  }

  Map<String, dynamic> toJson() => {
        'dataPrev': dataPrev,
        'dataRun': dataRun,
        'fileDate': fileDate,
        'local': {
          for (final entry in locais.entries) entry.key: entry.value.toJson(),
        },
      };
}

/// Representa a previsão de risco de um concelho para um dia específico da semana
class RiscoPrevisaoDia {
  final int diaIndex; // 0 = Hoje, 1 = Amanhã, etc.
  final String dataPrev;
  final RiscoLocal risco;

  const RiscoPrevisaoDia({
    required this.diaIndex,
    required this.dataPrev,
    required this.risco,
  });

  String get rotuloDia => formatarRotuloDia(dataPrev, diaIndex);
}

