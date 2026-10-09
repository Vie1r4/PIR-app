# 0006. API Unificada Serverless na Vercel com Edge CDN Cache e CORS Universal

* **Estado:** Aceite
* **Data:** 2026-10-09
* **Autores:** Equipa de Engenharia PIR-App

---

## 1. Contexto & Problema

O IPMA disponibiliza endpoints REST JSON apenas para os dias D+0 (`rcm-d0.json`), D+1 (`rcm-d1.json`) e D+2 (`rcm-d2.json`). A previsão estendida de 9 dias (D+3 a D+8) é publicada exclusivamente como tabelas e scripts JavaScript na página pública HTML do IPMA (`rcmF[0]` a `rcmF[8]`).

Isto criava uma divergência crítica entre plataformas:
* **Desktop / Nativo:** Fazia Web Scraping direto com sucesso em runtime (sem restrições de browser).
* **Web PWA / iOS Safari:** Sofria bloqueio de segurança CORS do browser ao contactar o IPMA diretamente. Recorria a proxies públicos instáveis (`cors.eu.org`, `allorigins`) ou a assets estáticos no GitHub que podiam ficar desfasados no tempo, resultando em dados inconsistentes entre o PC e o telemóvel.

## 2. Decisão

Adotou-se a arquitetura de **API Serverless Unificada com Edge CDN Cache**:

1. **Endpoint Centralizado (`landing_page/api/rcm-9dias.js`):**
   * Uma função Node.js na Vercel extrai os 9 dias oficiais diretamente da página JSP do IPMA.
   * Devolve JSON estruturado com cabeçalhos de CORS universais (`Access-Control-Allow-Origin: *`).
   * Configuração de cache CDN Edge: `Cache-Control: public, s-maxage=3600, stale-while-revalidate=1800` (1 hora).
   * **Custo 0 € perpétuo:** Graças ao Edge Cache, milhares de acessos de utilizadores correspondem a apenas ~24 execuções reais por dia no IPMA, consumindo uma fração ínfima do limite gratuito de 100.000 requisições/mês da Vercel.

2. **Consumo Unificado na App Flutter ([`IpmaScraperService`](../../lib/services/ipma_scraper_service.dart)):**
   * Todas as plataformas (Web, Windows Desktop, iOS e Android) consomem a mesma rota: `https://pir-app.vercel.app/api/rcm-9dias`.
   * **Validação Estrita de Frescura:** A app valida que o primeiro dia do payload não seja anterior a 2 dias atrás, rejeitando dados obsoletos.
   * **Remoção de Legado:** Eliminaram-se proxies CORS de terceiros instáveis e URLs estáticos do GitHub.

3. **Fallback Resiliente:**
   * Se a Vercel falhar, o Desktop mantém fallback para scraping direto ao IPMA.
   * Se ambos falharem, a app utiliza D0/D1/D2 da API REST oficial do IPMA e o `PrevisaoCalculoService`.

## 3. Consequências

* **Positivas:**
  * **100% de Consistência:** Os dados de risco são idênticos em tempo real no PC, telemóvel (Android/iOS) e Web.
  * **Zero CORS:** Navegadores acedem sem qualquer bloqueio ou dependência de proxies lentos.
  * **Código Limpo:** Redução de complexidade no cliente Flutter.
  * **Manutenção Centralizada:** Qualquer ajuste à página do IPMA é resolvido na função JavaScript em minutos, sem necessitar de atualizar binários da aplicação nos utilizadores.
