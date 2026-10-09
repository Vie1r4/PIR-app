import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cores base (para cartões e indicadores em modo claro)
Color corDoRisco(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF38A169); // Verde natural equilibrado
    case 2:
      return const Color(0xFFD69E2E); // Âmbar dourado quente
    case 3:
      return const Color(0xFFDD6B20); // Laranja queimado
    case 4:
      return const Color(0xFFE53E3E); // Vermelho carmim
    case 5:
      return const Color(0xFF805AD5); // Púrpura nobre
    default:
      return Colors.grey;
  }
}

/// Variantes elegantes para dark mode (visíveis e repousantes, sem saturação agressiva)
Color corDoRiscoDark(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF48BB78); // Verde fresco
    case 2:
      return const Color(0xFFECC94B); // Âmbar luminoso
    case 3:
      return const Color(0xFFF6AD55); // Laranja suave
    case 4:
      return const Color(0xFFFC8181); // Coral / Vermelho equilibrado
    case 5:
      return const Color(0xFFB794F4); // Violeta suave
    default:
      return Colors.grey;
  }
}


/// Cor de fundo do cartão tendo em conta o tema (claro vs escuro)
Color corDoRiscoContextual(int rcm, Brightness brightness) {
  return brightness == Brightness.dark
      ? corDoRiscoDark(rcm)
      : corDoRisco(rcm);
}

/// Cores especialmente calibradas para o mapa (tons pastel)
Color corDoRiscoMapa(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF98CA6D); // Verde pastel suave
    case 2:
      return const Color(0xFFF7E270); // Amarelo pastel
    case 3:
      return const Color(0xFFEEA858); // Laranja pêssego
    case 4:
      return const Color(0xFFDA7070); // Vermelho coral
    case 5:
      return const Color(0xFF8D586A); // Ameixa / Vinho pastel
    default:
      return const Color(0xFFDCDFE3); // Cinzento suave
  }
}

/// Cor do texto sobre fundo de risco colorido
Color corDoRiscoTexto(int rcm) {
  if (rcm == 2) return const Color(0xFF1E1B18); // Amarelo -> texto escuro
  return Colors.white;
}

/// Cor contrastante para textos sobre fundos claros
Color corDoRiscoTextoEmFundoClaro(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF2E7D32);
    case 2:
      return const Color(0xFF9A6B0A);
    case 3:
      return const Color(0xFFC05E0E);
    case 4:
      return const Color(0xFFB72626);
    case 5:
      return const Color(0xFF6F263D);
    default:
      return Colors.grey.shade700;
  }
}



/// Returns an appropriate icon for the risk level
IconData iconeDoRisco(int rcm) {
  switch (rcm) {
    case 1:
      return CupertinoIcons.checkmark_shield;
    case 2:
      return CupertinoIcons.info_circle;
    case 3:
      return CupertinoIcons.exclamationmark_triangle;
    case 4:
      return CupertinoIcons.flame;
    case 5:
      return CupertinoIcons.flame_fill;
    default:
      return CupertinoIcons.question_circle;
  }
}

/// Returns the risk level text in Portuguese
String textoDoRisco(int rcm) {
  switch (rcm) {
    case 1:
      return 'Reduzido';
    case 2:
      return 'Moderado';
    case 3:
      return 'Elevado';
    case 4:
      return 'Muito Elevado';
    case 5:
      return 'Máximo';
    default:
      return 'Desconhecido';
  }
}

/// Portuguese month names
const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Formats a date string like '2026-09-03' to '3 de setembro de 2026'
String formatarData(String dateStr) {
  try {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final ano = parts[0];
    final mes = int.parse(parts[1]);
    final dia = int.parse(parts[2]);
    return '$dia de ${_meses[mes - 1]} de $ano';
  } catch (_) {
    return dateStr;
  }
}

/// Formats a datetime string like '2026-09-03 09:35:02' to a readable format
String formatarDataHora(String fileDate) {
  try {
    final parts = fileDate.split(' ');
    if (parts.length != 2) return fileDate;
    final data = formatarData(parts[0]);
    final hora = parts[1].substring(0, 5); // HH:MM
    return '$data às $hora';
  } catch (_) {
    return fileDate;
  }
}

/// Formats a DateTime to a readable Portuguese string
String formatarDateTime(DateTime dt) {
  final dia = dt.day;
  final mes = _meses[dt.month - 1];
  final hora = dt.hour.toString().padLeft(2, '0');
  final minuto = dt.minute.toString().padLeft(2, '0');
  return '$dia de $mes às $hora:$minuto';
}

/// Nomes abreviados dos dias da semana
const diasDaSemanaAbrev = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Nomes abreviados dos meses
const mesesAbrev = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
];

/// Devolve a data e hora corrente calibrada para o fuso horário de Portugal Continental (Europe/Lisbon).
/// Trata automaticamente a alternância entre Horário de Verão (WEST = UTC+1) e Inverno (WET = UTC+0)
/// de forma consistente e determinística em qualquer sistema operativo ou browser.
DateTime agoraPortugal([DateTime? baseUtc]) {
  final utc = baseUtc ?? DateTime.now().toUtc();
  final ano = utc.year;

  // Início DST UE (último domingo de março às 01:00 UTC)
  final ultimoDiaMarco = DateTime.utc(ano, 3, 31);
  final ultimoDomingoMarco =
      ultimoDiaMarco.subtract(Duration(days: ultimoDiaMarco.weekday % 7));
  final inicioDst = DateTime.utc(ano, 3, ultimoDomingoMarco.day, 1, 0);

  // Fim DST UE (último domingo de outubro às 01:00 UTC)
  final ultimoDiaOutubro = DateTime.utc(ano, 10, 31);
  final ultimoDomingoOutubro =
      ultimoDiaOutubro.subtract(Duration(days: ultimoDiaOutubro.weekday % 7));
  final fimDst = DateTime.utc(ano, 10, ultimoDomingoOutubro.day, 1, 0);

  final isDst = (utc.isAfter(inicioDst) || utc.isAtSameMomentAs(inicioDst)) &&
      utc.isBefore(fimDst);
  return utc.add(Duration(hours: isDst ? 1 : 0));
}

/// Formata o rótulo de um dia validando semanticamente contra o dia civil de Portugal Continental.
/// Impede que boletins da cache referentes a dias passados (ex: ontem) sejam falsamente rotulados como "Hoje".
String formatarRotuloDia(
  String dataPrev,
  int diaIndex, {
  bool incluirMes = true,
  DateTime? agoraReferencia,
}) {
  DateTime? dtPrev;
  try {
    final partes = dataPrev.trim().split('-');
    if (partes.length == 3) {
      dtPrev = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
    } else {
      dtPrev = DateTime.tryParse(dataPrev);
    }
  } catch (_) {}

  if (dtPrev != null) {
    final ref = agoraReferencia ?? agoraPortugal();
    final hojeCivil = DateTime(ref.year, ref.month, ref.day);
    final dataCivil = DateTime(dtPrev.year, dtPrev.month, dtPrev.day);
    final diffDias = dataCivil.difference(hojeCivil).inDays;

    if (diffDias == 0) return 'Hoje';
    if (diffDias == 1) return 'Amanhã';
    if (diffDias == -1) return 'Ontem (Desatualizado)';
    if (diffDias < -1) {
      final mes = mesesAbrev[dtPrev.month - 1];
      return '${dtPrev.day} $mes (Desatualizado)';
    }

    // Dias futuros (D+2 em diante)
    final diaSemana = diasDaSemanaAbrev[dtPrev.weekday - 1];
    if (incluirMes) {
      final mes = mesesAbrev[dtPrev.month - 1];
      return '$diaSemana, ${dtPrev.day} $mes';
    }
    return '$diaSemana, ${dtPrev.day}';
  }

  // Fallback seguro caso a dataPrev seja inválida ou vazia
  if (diaIndex == 0) return 'Hoje';
  if (diaIndex == 1) return 'Amanhã';
  return dataPrev;
}

/// Condicionantes e restrições legais associadas ao nível de risco (ICNF / DL 82/2021)
class RestricoesRisco {
  final String queimas;
  final bool queimasPermitidas;
  final String maquinaria;
  final bool maquinariaCondicionada;
  final String pirotecnia;
  final bool pirotecniaPermitida;

  const RestricoesRisco({
    required this.queimas,
    required this.queimasPermitidas,
    required this.maquinaria,
    required this.maquinariaCondicionada,
    required this.pirotecnia,
    required this.pirotecniaPermitida,
  });
}

/// Devolve as orientações e restrições legais para o nível de risco PIR
RestricoesRisco obterRestricoesRisco(int rcm) {
  switch (rcm) {
    case 1:
    case 2:
      return const RestricoesRisco(
        queimas: 'Permitidas com comunicação prévia obrigatória ao ICNF.',
        queimasPermitidas: true,
        maquinaria: 'Permitida com extintor e dispositivos de retenção de faíscas.',
        maquinariaCondicionada: false,
        pirotecnia: 'Permitida mediante licença da Câmara Municipal.',
        pirotecniaPermitida: true,
      );
    case 3:
      return const RestricoesRisco(
        queimas: 'Condicionadas a autorização municipal e meios de extinção no local.',
        queimasPermitidas: true,
        maquinaria: 'Permitida com vigilância reforçada e meios de 1ª intervenção.',
        maquinariaCondicionada: true,
        pirotecnia: 'Sujeita a autorização municipal e presença de bombeiros.',
        pirotecniaPermitida: true,
      );
    case 4:
    case 5:
    default:
      return const RestricoesRisco(
        queimas: 'PROIBIDAS. É estritamente interdito realizar queimas e queimadas.',
        queimasPermitidas: false,
        maquinaria: 'Interdito o uso de alfaias geradoras de faíscas nas horas de maior calor.',
        maquinariaCondicionada: true,
        pirotecnia: 'PROIBIDA. Suspensas todas as licenças de fogo de artifício.',
        pirotecniaPermitida: false,
      );
  }
}

