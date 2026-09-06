import 'package:flutter/material.dart';
import 'modal_seletor_concelhos.dart';

export 'modal_seletor_concelhos.dart';

/// Redirecionamento retrocompatível para o seletor completo de concelhos.
class ModalSeletorFavoritos {
  static Future<void> exibir(BuildContext context, {VoidCallback? onIrParaPesquisa}) {
    return ModalSeletorConcelhos.exibir(
      context,
      onIrParaPesquisa: onIrParaPesquisa,
    );
  }
}
