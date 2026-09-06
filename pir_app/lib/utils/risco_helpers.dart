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
      return Icons.check_circle_outline;
    case 2:
      return Icons.info_outline;
    case 3:
      return Icons.warning_amber_rounded;
    case 4:
      return Icons.local_fire_department;
    case 5:
      return Icons.dangerous_outlined;
    default:
      return Icons.help_outline;
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

/// Formata o rótulo de um dia (Hoje, Amanhã ou 'Seg, 5 Set' / 'Seg, 5')
String formatarRotuloDia(String dataPrev, int diaIndex, {bool incluirMes = true}) {
  if (diaIndex == 0) return 'Hoje';
  if (diaIndex == 1) return 'Amanhã';
  try {
    final dt = DateTime.parse(dataPrev);
    final diaSemana = diasDaSemanaAbrev[dt.weekday - 1];
    if (incluirMes) {
      final mes = mesesAbrev[dt.month - 1];
      return '$diaSemana, ${dt.day} $mes';
    }
    return '$diaSemana, ${dt.day}';
  } catch (_) {
    return dataPrev;
  }
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

