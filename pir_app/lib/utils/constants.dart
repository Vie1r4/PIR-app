/// URLs da API do IPMA
class ApiUrls {
  static const String rcmHoje =
      'https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d0.json';
  static const String rcmAmanha =
      'https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d1.json';

  ApiUrls._();
}

/// Strings da aplicação em Português
class AppStrings {
  static const String appTitle = 'PIR - Incêndio Rural';
  static const String hoje = 'Hoje';
  static const String amanha = 'Amanhã';
  static const String selecioneConcelho = 'Selecione um concelho';
  static const String pesquisar = 'Pesquisar concelho...';
  static const String favoritos = 'Favoritos';
  static const String semFavoritos = 'Sem favoritos';
  static const String semFavoritosDescricao =
      'Adicione concelhos aos favoritos para acesso rápido';
  static const String ultimaAtualizacao = 'Última atualização';
  static const String erroCarregar =
      'Não foi possível atualizar os dados.\nA mostrar última informação disponível.';
  static const String semDados = 'Sem dados disponíveis';
  static const String fonteDados = 'Fonte: IPMA';
  static const String abrirPesquisa = 'Pesquisar';

  AppStrings._();
}

/// Chaves para o cache local (Hive)
class CacheKeys {
  static const String boxName = 'pir_cache';
  static const String rcmD0 = 'rcm_d0';
  static const String rcmD1 = 'rcm_d1';
  static const String favoritos = 'favoritos';
  static const String concelhoPrincipal = 'concelho_principal';
  static const String ultimaAtualizacaoPrefix = 'ultima_atualizacao_';

  CacheKeys._();
}
