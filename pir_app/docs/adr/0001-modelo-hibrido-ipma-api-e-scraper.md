# ADR 0001: Modelo Híbrido de Dados IPMA (API Oficial + Web Scraper)

* **Status:** Aceite
* **Data:** 2026-09-06
* **Decisores:** Equipa PIR-App

---

## Contexto
O Instituto Português do Mar e da Atmosfera (IPMA) disponibiliza informação diária sobre o Perigo de Incêndio Rural (RCM - Risco de Concelho de Meteorologia). 
No entanto, as opções de acesso a estes dados apresentam restrições técnicas:

1. **API REST Oficial (`api.ipma.pt`):**
   - Fornece endpoints estruturados em JSON para o dia atual (`rcm-d0.json`) e para o dia seguinte (`rcm-d1.json`).
   - **Limitação:** Não disponibiliza endpoints públicos documentados para os restantes dias da previsão alargada (dias 2 a 8).
2. **Página Web Pública do IPMA:**
   - A página pública oficial (`ipma.pt/pt/ambiente/risco.incendio/`) contém no seu código-fonte as variáveis JavaScript `rcmF[0]` a `rcmF[8]`, contendo as previsões completas para **até 9 dias consecutivos** em formato JSON estruturado.

## Decisão
Adotou-se uma arquitetura de dados **híbrida e resiliente** implementada em [`RiscoProvider`](../../lib/providers/risco_provider.dart), [`IpmaApiService`](../../lib/services/ipma_api_service.dart) e [`IpmaScraperService`](../../lib/services/ipma_scraper_service.dart):

1. **Chamadas Concorrentes:** Ao sincronizar dados, a aplicação dispara em simultâneo (`Future.wait`) o pedido à API oficial (Hoje e Amanhã) e ao Web Scraper (Previsão Alargada de 9 dias).
2. **Fallback em Cascata:**
   - Se a API oficial responder, os dias 0 e 1 são alimentados pela API e os dias subsequentes (2 a 8) pelo Scraper.
   - Se a API oficial falhar ou estiver indisponível, o Scraper assume a totalidade dos dados (dias 0 a 8) sem qualquer impacto perceptível para o utilizador.
   - Se ambos falharem (ex: ausência total de ligação à Internet), a aplicação recorre automaticamente à cache local armazenada no **Hive**.
3. **Resiliência e Timeouts:** Ambas as fontes operam com timeouts de rede estritos (15s e 20s) e tratamento de exceções independente.

## Consequências
* **Positivas:**
  * Disponibilização ao utilizador de previsões meteorológicas de risco até 9 dias (em vez de apenas 2 dias).
  * Tolerância a falhas de rede de nível elevado: a app nunca fica bloqueada por indisponibilidade de um dos endpoints do IPMA.
* **Negativas / Riscos:**
  * Se o IPMA reestruturar radicalmente o código HTML da sua página web, o `IpmaScraperService` pode necessitar de ajuste na expressão regular. No entanto, mesmo nesse cenário, a API oficial continua a alimentar a app com os dados de Hoje e Amanhã.
