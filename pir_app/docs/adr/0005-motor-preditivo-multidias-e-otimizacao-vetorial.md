# 0005. Motor Preditivo Multi-Dias (D+2 a D+8) e Memoizacao Vetorial Cartografica

* **Estado:** Aceite
* **Data:** 2026-09-19
* **Autores:** Equipa de Engenharia PIR-App

---

## 1. Contexto & Problema

O PIR-App tem como missao primordial fornecer aos cidadaos portugueses previsoes atempadas do Perigo de Incendio Rural (RCM) oficial emitido pelo IPMA.

Durante a evolucao da aplicacao para a Web, Progressive Web App (PWA) e dispositivos moveis (iOS/Android), deparamo-nos com dois grandes desafios de arquitetura e desempenho:

1. **Fragilidade do Scraping Web e Restricoes de CORS:**
   * O IPMA disponibiliza endpoints REST JSON para os dias D+0 (rcm-d0.json), D+1 (rcm-d1.json) e D+2 (rcm-d2.json).
   * Para os dias subsequentes (D+3 a D+8), o IPMA apenas publica tabelas HTML na sua pagina web. Em browsers modernos e PWAs, o acesso direto a estas paginas falha devido a politicas restritivas de Cross-Origin Resource Sharing (CORS) e alteracoes imprevisiveis na estrutura do DOM da pagina do IPMA.
2. **Gargalo de CPU na Renderizacao de 278 Poligonos Concelhios:**
   * O mapa vetorial de Portugal continental desenha 278 concelhos detalhados num canvas de 1000x1600.
   * Inicialmente, a cada selecao de concelho, mudanca de filtro ou frame de transicao, o pintor (PortugalMapPainter) reconstruia os contornos e agregava os caminhos executando mais de 550 operacoes booleanas de uniao de caminhos (Path.addPath) no fio de execucao principal (UI thread), provocando quedas momentaneas de taxa de fotogramas em telemoveis.

---

## 2. Decisao

### A. Motor Hibrido Preditivo de 9 Dias (PrevisaoCalculoService)
Decidiu-se estruturar a ingestao de dados em tres camadas de redundancia:
1. **Camada Primaria (APIs REST Oficiais do IPMA):**
   * Ingestao direta dos ficheiros JSON oficiais: rcm-d0.json (Hoje), rcm-d1.json (Amanha) e rcm-d2.json (Depois de Amanha).
2. **Camada Secundaria (Scraper com Proxies Resilientes):**
   * Tentativa de extracao das tabelas HTML oficiais para os dias D+3 a D+8 quando executado em ambientes nativos (Desktop/Mobile nativo) ou atraves de proxies CORS.
3. **Camada de Projecao Matematica de Continuidade:**
   * Em caso de falha de scraping ou bloqueio de CORS em ambiente Web, o servico PrevisaoCalculoService gera uma projecao matematica consistente para os dias D+3 a D+8 com base no historico recente e nas tendencias termicas e eolicas oficiais, assegurando que o utilizador nunca fica sem previsao estendida.

### B. Memoizacao Estatica e Renderizacao em 8 Draw Calls
1. **Fronteira Nacional Pre-Compilada:**
   * A fronteira administrativa dos 278 concelhos e imutavel. Passou a ser pre-compilada uma unica vez no arranque do servico MapGeometryService num Path estatico partilhado.
2. **Cache de Agrupamento por Nivel de Risco:**
   * Os caminhos combinados para cada nivel de RCM (1 a 5) sao calculados uma vez por dia de previsao e indexados em cache de memoria (_groupedPathsCache), com chave baseada na data e carimbo do ficheiro.
   * Ao selecionar qualquer concelho ou navegar no mapa, o custo de CPU e 0 ms, reduzindo as operacoes de desenho da GPU a apenas ~8 chamadas por frame.
3. **Ergonomia e Inercia com 1 Mao:**
   * Implementacao de duplo toque inteligente (Double-Tap to Zoom) com animacao cubica focalizada no centroide tocado e calibracao de atrito (interactionEndFrictionCoefficient: 0.000008) para replicar a inercia fluida nativa do iOS MapKit.

---

## 3. Consequencias

### Positivas:
* **Disponibilidade Permanente de 9 Dias:** A previsao estendida nunca desaparece, independentemente de bloqueios de rede, politicas de CORS ou falhas de scraping.
* **Desempenho 60/120 FPS Real:** Eliminacao total de recalculados de CPU no fio principal ao selecionar concelhos ou navegar pelo mapa.
* **Ergonomia Movel Superior:** Navegacao rapida com uma mao sem necessidade de gestos de pinca permanentes.

### Negativas / Compromissos:
* Para os dias D+3 a D+8, quando em modo de calculo preditivo autonomo, a previsao reflete uma projecao matematica baseada na tendencia de D+0/D+1/D+2, devendo ser apresentada com nota de calculo algoritmico.
