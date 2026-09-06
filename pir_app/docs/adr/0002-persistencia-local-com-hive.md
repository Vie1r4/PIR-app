# ADR 0002: Persistência Local e Cache NoSQL com Hive

* **Status:** Aceite
* **Data:** 2026-09-06
* **Decisores:** Equipa PIR-App

---

## Contexto
O PIR-app necessita de persistir em disco:
1. Os dados da última previsão meteorológica recolhida (para suporte a modo offline);
2. A lista de concelhos favoritos do utilizador;
3. O concelho principal selecionado;
4. As preferências de tema e de acessibilidade (tamanho de texto, alto contraste, animações).

As alternativas em Flutter incluem:
- `shared_preferences` (apenas tipos primitivos simples, pouco apropriado para guardar JSONs de múltiplos dias);
- `sqflite` (relacional, exige compilação de binários nativos C++ de SQLite no Windows Desktop e migrações de schema rígidas);
- `hive_flutter` (banco de dados NoSQL de chave-valor, escrito em Dart puro, ultrarrápido e com zero dependências nativas de C++).

## Decisão
Optou-se pela utilização do **Hive** (`hive_flutter`) através do [`CacheService`](../../lib/services/cache_service.dart) e [`AcessibilidadeProvider`](../../lib/providers/acessibilidade_provider.dart).

1. **Caixa Única de Cache:** Os dados são guardados numa caixa NoSQL indexada (`pir_cache`), permitindo leituras e escritas instantâneas em memória com sincronização em ficheiro binário.
2. **Zero Dependências Nativas Externas:** Por ser Dart puro, o Hive funciona nativamente em Windows, macOS, Linux, Android e iOS sem risco de conflito de compilação de DLLs ou headers de C/C++.
3. **Serialização Flexível:** Dados de risco em formato Map/JSON são armazenados diretamente sem necessidade de tabelas relacionais ou parsing pesado.

## Consequências
* **Positivas:**
  * Arranque da aplicação quase instantâneo (< 20ms para leitura da cache).
  * Manutenção simples: adicionar novas definições de utilizador (ex: preferências de acessibilidade) não requer scripts de migração SQL `ALTER TABLE`.
  * Excelente estabilidade em ambiente desktop Windows.
* **Negativas:**
  * Não suporta queries SQL relacionais complexas (joins), o que não representa limitação no contexto desta aplicação, onde os acessos são por chave directa (`rcm_d0`, `favoritos`, `acc_escala_texto`).
