# ADR 0003: Projeção Cartográfica Vetorial no Canvas Direto (1000x1600)

* **Status:** Aceite
* **Data:** 2026-09-06
* **Decisores:** Equipa PIR-App

---

## Contexto
O PIR-app requer uma visualização interativa do mapa de Portugal continental dividida pelos seus 278 concelhos, com coloração dinâmica correspondente ao nível de risco de incêndio rural (1 a 5).

As abordagens tradicionais para mapas incluem:
1. **Mapas Baseados em Tiles / SDKs de Terceiros (Mapbox, Google Maps, Leaflet):**
   - Exigem ligação constante à Internet para carregar tiles de satélite/arruamentos;
   - Requerem chaves de API, cobrança por visualizações ou licenças pagas;
   - São muito pesados para uma aplicação utilitária leve focada apenas no risco municipal;
   - Dificuldade em colorir 278 polígonos vetoriais com atualização instantânea a 60/120 FPS.
2. **Desenho Vetorial Direto no Canvas via Flutter CustomPainter:**
   - Vetores dos concelhos de Portugal convertidos previamente para o espaço de coordenadas canónico do Canvas (`1000 x 1600`);
   - Renderização acelerada por GPU através dos motores gráficos nativos do Flutter (Impeller / Skia).

## Decisão
Adotou-se o modelo de **desenho vetorial direto no Canvas** com [`MapGeometryService`](../../lib/services/map_geometry_service.dart), [`PortugalMapPainter`](../../lib/widgets/portugal_map_painter.dart) e [`InteractiveViewer`](../../lib/screens/map_screen.dart):

1. **Espaço de Coordenadas Canónico:**
   - Canvas fixo de `1000 x 1600` cobrindo com precisão Portugal Continental.
   - Os 278 concelhos são convertidos em objetos nativos `Path` e armazenados em memória durante o arranque.
2. **Gestos e Navegação Suave:**
   - O `InteractiveViewer` gere a matriz de transformação 2D (escala e translação) com `constrained: false` e `boundaryMargin: EdgeInsets.all(double.infinity)`.
   - Um `Listener` dedicado trata o scroll da roda do rato aplicando ampliação centrada com precisão sob o cursor do utilizador.
   - Suporte a arrasto (pan) contínuo com o rato e atalhos de teclado (`+`, `-`, `0`).
3. **Pintura com Alto Desempenho:**
   - `PortugalMapPainter` utiliza `isComplex: true`, `willChange: false` e um comparador `shouldRepaint` rigoroso, minimizando ciclos de redesenho da GPU.

## Consequências
* **Positivas:**
  * **100% Autónomo e Offline:** O mapa não precisa de descarregar nenhuma imagem de fundo nem depende de servidores de mapas externos.
  * **Performance Máxima:** 60/120 FPS fluidos em qualquer computador Windows com consumo mínimo de RAM e CPU.
  * **Zero Custos:** Sem limites de requisições nem dependência de chaves de API pagas.
* **Negativas / Limitações:**
  * Focado em Portugal Continental (não inclui arruamentos nem detalhe ao nível da freguesia, o que se alinha com o escopo do Risco RCM do IPMA que é de âmbito municipal).
