# ADR 0004: Geolocalização Híbrida e Mapeamento Poligonal Offline

* **Status:** Aceite
* **Data:** 2026-09-18
* **Decisores:** Equipa PIR-App

---

## Contexto
O utilizador do PIR-app necessita de saber imediatamente o perigo de incêndio no local onde se encontra, sem ter de procurar manualmente o seu concelho numa lista de 278 municípios ao iniciar a aplicação ou quando se desloca.

Desafios identificados:
1. **Diversidade de Hardware Desktop e Sistemas Operativos:**
   - Em computadores desktop Windows, muitos utilizadores não possuem chip GPS dedicado ou têm a funcionalidade "Localização" desativada nas Definições de Privacidade do Windows.
   - Em dispositivos móveis (Android/iOS), o GPS é a fonte predominante e de elevada precisão.
2. **Privacidade e Dependência de Serviços Externos de Geocodificação Reversa:**
   - As soluções comuns enviam as coordenadas `(lat, lon)` para APIs de terceiros (Google Geocoding, Nominatim/OpenStreetMap, Mapbox) para saber o nome do município.
   - Isso introduziria latência de rede, limites de quota, dependência externa e exposição desnecessária da localização do utilizador.

## Decisão
Implementou-se uma arquitetura em duas camadas complementares:

1. **Camada de Deteção Híbrida de Coordenadas ([`LocalizacaoService`](../../lib/services/localizacao_service.dart)):**
   - **Nativo (GPS / Windows Location):** Utilização do plugin oficial `geolocator` com backend nativo `geolocator_windows` no ambiente de trabalho. Respeita as permissões do sistema operativo e configurações de privacidade.
   - **Fallback Resiliente por Rede/IP:** Se o serviço de localização estiver desativado no Windows ou as permissões forem recusadas, a aplicação consulta um endpoint leve de contingência com timeout estrito de 3 a 4 segundos, obtendo uma aproximação geográfica sem bloquear a interface.

2. **Mapeamento Poligonal Local no Cliente ([`MapGeometryService`](../../lib/services/map_geometry_service.dart)):**
   - Aproveita-se o modelo de geometria vetorial já carregado em memória dos 278 concelhos de Portugal Continental.
   - As coordenadas `(lon, lat)` são projetadas para o sistema de coordenadas do Canvas e validadas diretamente contra os caminhos fechados (`Path.contains(point)`).
   - Se o ponto estiver em zona costeira ou imediatamente adjacente, o algoritmo calcula a distância euclidiana mínima aos limites (`bounds.center`) dos concelhos para atribuir o concelho continental mais próximo.
   - **Zero chamadas a APIs de geocodificação externa.** O mapeamento é instantâneo (< 5 ms), 100% privado e funciona em modo offline se o GPS estiver disponível.

3. **Controlo Explícito do Utilizador:**
   - A deteção no arranque é opcional e configurável nas **Definições**, com estado persistido no Hive NoSQL (`auto_localizacao`).
   - Botões de ação direta "Usar a minha localização atual" estão acessíveis no **Modal de Seleção**, no **Dashboard Inicial** e nas **Definições**.

## Consequências
* **Positivas:**
  * **Privacidade Absoluta:** Nenhuma coordenada é enviada para serviços de geocoding ou servidores proprietários.
  * **Resiliência Total:** Funciona em computadores portáteis com GPS, em desktops fixos sem GPS (via fallback) e em smartphones móveis.
  * **Zero Latência:** Resolução ponto-em-polígono executada localmente no dispositivo em microssegundos.
* **Negativas / Limitações:**
  * A precisão baseada em IP (quando o GPS não está disponível) pode aproximar o concelho da central da operadora de telecomunicações do utilizador. O utilizador mantém sempre o controlo manual para selecionar o concelho exato se assim o desejar.
