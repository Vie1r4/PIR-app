import 'package:flutter/material.dart';

/// Returns the background color for a given RCM risk level (Tons naturais e suaves)
Color corDoRisco(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF5BA836); // Verde natural mate
    case 2:
      return const Color(0xFFE5C032); // Amarelo mostarda dourado suave
    case 3:
      return const Color(0xFFE2802B); // Laranja quente equilibrado
    case 4:
      return const Color(0xFFCB4A4A); // Vermelho terracota suave
    case 5:
      return const Color(0xFF7A364C); // Bordeaux / Vinho fosco
    default:
      return Colors.grey;
  }
}

/// Cores especialmente calibradas para o mapa (tons pastel e repousantes para os olhos)
Color corDoRiscoMapa(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF98CA6D); // Verde pastel suave
    case 2:
      return const Color(0xFFF7E270); // Amarelo pastel suave (não encadeia)
    case 3:
      return const Color(0xFFEEA858); // Laranja pêssego suave
    case 4:
      return const Color(0xFFDA7070); // Vermelho coral suave
    case 5:
      return const Color(0xFF8D586A); // Ameixa / Vinho pastel fosco
    default:
      return const Color(0xFFDCDFE3); // Cinzento suave
  }
}

/// Returns the text color that contrasts well with the risk background color
Color corDoRiscoTexto(int rcm) {
  if (rcm == 2) {
    return const Color(0xFF1E1B18);
  }
  return Colors.white;
}

/// Cor contrastante para textos renderizados sobre fundos claros
Color corDoRiscoTextoEmFundoClaro(int rcm) {
  switch (rcm) {
    case 1:
      return const Color(0xFF2E7D32); // Verde legível
    case 2:
      return const Color(0xFF9A6B0A); // Ocre legível
    case 3:
      return const Color(0xFFC05E0E); // Laranja escuro
    case 4:
      return const Color(0xFFB72626); // Vermelho escuro
    case 5:
      return const Color(0xFF6F263D); // Bordeaux escuro
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
