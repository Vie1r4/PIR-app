# PIR - Perigo de Incêndio Rural (IPMA)

Aplicação multiplataforma moderna (**Web PWA / iOS, Android e Windows Desktop**) concebida para consultar de forma rápida, simples e direta o **Perigo de Incêndio Rural (PIR)** oficial disponibilizado pelo **IPMA (Instituto Português do Mar e da Atmosfera)**.

🌐 **Versão Web / PWA Online:** [https://vie1r4.github.io/PIR-app/](https://vie1r4.github.io/PIR-app/)

---

## 📌 Índice
1. [Sobre o Projeto](#-sobre-o-projeto)
2. [Funcionalidades](#-funcionalidades)
3. [Fonte de Dados & Escala RCM](#-fonte-de-dados)
4. [Como Usar (Web, iOS, Desktop)](#-como-usar)
5. [Widget iOS (Scriptable)](#-widget-ios-scriptable)
6. [Decisões de Arquitetura (ADRs)](#-decisões-de-arquitetura-adrs)
7. [Distribuição e Instalador (Windows)](#-distribuição-e-instalador-windows)
8. [Estrutura do Projeto](#-estrutura-do-projeto)
9. [Para Programadores (Desenvolvimento & Testes)](#-para-programadores)

---

## 🌲 Sobre o Projeto

O objetivo não é reinventar um modelo de risco nem adicionar sobrecarga de autenticação ou servidores proprietários. A aplicação consome diretamente a API pública do IPMA e modelos cartográficos oficiais, transformando dados técnicos em interfaces visuais legíveis e operacionais:
- **Execução ultrarrápida e fluida:** Suporte completo para 60/120 FPS em ecrãs táteis de alta taxa de atualização.
- **Armazenamento em cache local e resiliência offline:** Consulta dos últimos dados conhecidos mesmo em serras ou zonas rurais sem cobertura de rede móvel.
- **Previsão Estendida Garantida (9 Dias):** Modelo de projeção matemática e APIs oficiais (D0, D1 e D2) para contornar limitações de rede ou CORS em ambiente Web.
- **Foco no cidadão e na prevenção:** Visualização do concelho do utilizador, regras legais para queimas/queimadas e atalhos de emergência.

---

## ✨ Funcionalidades

- 🔍 **Pesquisa Inteligente de Concelhos:** 278 concelhos de Portugal Continental indexados com tolerância total a maiúsculas, minúsculas e acentuação (ex: `agueda`, `águeda` ou `Águeda`).
- 📅 **Previsão Alargada (9 Dias) Estilo Apple Weather:** Cartão compacto e retrátil com carrossel horizontal de 116px e modo expandido com animação suave, apresentando temperaturas e direção/intensidade do vento.
- 🗺️ **Mapa Vetorial Interativo a 60/120 FPS:** Renderização vetorial dos 278 concelhos em Canvas 1000x1600 com memoização estática de fronteiras (~8 draw calls por frame), duplo toque inteligente (*double-tap to zoom*) e inércia física natural (*iOS momentum glide*).
- ⭐ **Gestão de Favoritos:** Acesso imediato a concelhos habituais com badge de contagem na barra inferior.
- 📴 **Deteção Realista de Conectividade:** Indicador em tempo real de estado Online/Offline com sincronização sob demanda (`forcar: true`) e cache Hive NoSQL.
- 📍 **Geolocalização Resiliente & Privada:** Deteção automática do concelho via GPS/Location com resolução poligonal vetorial 100% offline (nenhuma coordenada é enviada para a internet).
- 🎨 **Acessibilidade & Temas:** Tema Claro, Escuro (True Dark Apple style), modo de Alto Contraste para máxima legibilidade sob sol forte, e escala dinâmica de texto.
- ⚖️ **Aviso Legal & Privacidade Unificado:** Em total conformidade com a Lei de Dados Abertos (Lei n.º 68/2021) e privacidade estrita pelo Regulamento Geral sobre a Proteção de Dados (RGPD).

---

## 📡 Fonte de Dados

Os dados são recolhidos diretamente das fontes abertas e oficiais do IPMA:
- **API Pública RCM Hoje:** `https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d0.json`
- **API Pública RCM Amanhã:** `https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d1.json`
- **Previsão Alargada 9 Dias (FWI):** Portal oficial de Perigo de Incêndio Rural do IPMA (`/ambiente/risco.incendio/`)

### Escala de Risco (RCM - Risco Conjuntural e Meteorológico):

| Nível | Classificação | Cor na App | Ação / Significado |
| :---: | :--- | :---: | :--- |
| **1** | **Reduzido** | 🟢 Verde | Condições normais de segurança |
| **2** | **Moderado** | 🟡 Amarelo | Atenção a trabalhos com maquinaria ou queimas |
| **3** | **Elevado** | 🟠 Laranja | Cuidados redobrados, restrições habituais em meio rural |
| **4** | **Muito Elevado** | 🔴 Vermelho | Risco severo, fortes restrições a atividades florestais |
| **5** | **Máximo** | 🟣 Roxo | Proibições estritas legais em espaços florestais |

---

## 🚀 Como Usar

### No iPhone / iPad / Android (Web PWA):
1. Acede a **[https://vie1r4.github.io/PIR-app/](https://vie1r4.github.io/PIR-app/)** no Safari (iOS) ou Chrome (Android).
2. No iOS (Safari), toca no botão de **Partilhar** (`Compartilhar`) e seleciona **"Ecrã Principal"** (*Add to Home Screen*).
3. A aplicação abre instantaneamente em modo nativo de ecrã inteiro (Standalone), com suporte offline, ícone de alta resolução e transições táteis fluidas.

### No Computador (Windows Desktop):
1. **Pelo Atalho do Ambiente de Trabalho:**
   - Clica duas vezes no ícone **`PIR - Incêndio Rural`** no teu Ambiente de Trabalho.
2. **Localização do Executável:**
   - Caso queiras aceder diretamente à pasta de distribuição:
     `pir_app\build\windows\x64\runner\Release\pir_app.exe`

### Primeiros Passos na Aplicação:
1. Podes navegar pelas abas principais:
   - **Início**: Concelho principal, risco de Hoje e Amanhã, regras legais e carrossel retrátil com os 9 dias.
   - **Mapa**: Visualização vetorial completa de Portugal a 60/120 FPS com duplo toque para zoom e pesquisa rápida.
   - **Favoritos**: Acesso imediato aos teus locais marcados com badge de contagem.
   - **Definições**: Acessibilidade (alto contraste, tamanho de letra), GPS automático, modo escuro e aviso legal/privacidade.
2. Para atualizar os dados manualmente, basta fazer pull-to-refresh na página inicial ou premir o botão de sincronização nas Definições.

---

## 📱 Widget iOS (Scriptable)

Para além da PWA, o projeto inclui um **Widget nativo para o ecrã inicial do iPhone/iPad**, desenvolvido em JavaScript para a app gratuita **Scriptable**:
- **Design Apple Weather:** Apresenta o concelho, nível de risco de hoje, temperaturas mínima/máxima, direção e velocidade do vento.
- **Cor Dinâmica Contextual:** O fundo do widget adapta-se automaticamente à cor oficial do nível de risco emitido pelo IPMA (Verde a Roxo).
- **Sem Servidores Externos:** O widget comunica diretamente com a API pública do IPMA e atualiza-se em segundo plano no iOS.

---

## 🏛️ Decisões de Arquitetura (ADRs)

O projeto adota o formato *Architecture Decision Records* (ADR) para documentar formalmente o racional, as alternativas consideradas e o impacto de escolhas chave de engenharia de software:

| ADR | Título | Estado | Foco Principal |
| :---: | :--- | :---: | :--- |
| [**0001**](pir_app/docs/adr/0001-modelo-hibrido-ipma-api-e-scraper.md) | Modelo Híbrido IPMA (API Aberta + Scraper de 9 Dias) | Aceite | Resiliência de dados e previsão estendida sem backend intermediário |
| [**0002**](pir_app/docs/adr/0002-persistencia-local-com-hive.md) | Persistência Local e Cache Offline com Hive NoSQL | Aceite | Desempenho sub-milissegundo, tolerância a falhas de rede e zero setup nativo SQLite |
| [**0003**](pir_app/docs/adr/0003-projecao-cartografica-vetorial-canvas.md) | Projeção Cartográfica Vetorial Offline em CustomPainter | Aceite | Renderização de 278 concelhos a 60/120 FPS sem WebViews nem dependências de tiles pesadas |
| [**0004**](pir_app/docs/adr/0004-geolocalizacao-hibrida-e-mapeamento-poligonal.md) | Geolocalização Híbrida e Mapeamento Poligonal Offline | Aceite | Deteção resiliente GPS+IP e identificação geométrica local de concelhos com privacidade |
| [**0005**](pir_app/docs/adr/0005-motor-preditivo-multidias-e-otimizacao-vetorial.md) | Motor Preditivo Multi-Dias e Memoização Vetorial Cartográfica | Aceite | Continuidade de 9 dias via D0/D1/D2 e 60/120 FPS no mapa com duplo toque inteligente |

Os registos detalhados encontram-se disponíveis no diretório [`pir_app/docs/adr/`](pir_app/docs/adr/).

---

## 📁 Estrutura do Projeto

```text
Pir-app/
├── README.md                          # Este documento
└── pir_app/                           # Código-fonte da aplicação Flutter
    ├── assets/
    │   ├── concelhos.json             # Mapeamento DICO -> Concelho/Distrito
    │   ├── concelhos_geo.json         # Geometrias vetoriais oficiais dos concelhos
    │   └── logopirapp.png             # Logotipo oficial da aplicação
    ├── docs/
    │   └── adr/                       # Registos de Decisão de Arquitetura (ADRs)
    ├── installer/
    │   ├── pir_app_setup.iss          # Script Inno Setup 6 para instalador Windows
    │   └── build_installer.ps1        # Script PowerShell de compilação e empacotamento
    ├── dist/                          # Pacotes de distribuição gerados (.zip e .exe)
    ├── lib/
    │   ├── main.dart                  # Ponto de entrada (Hive + Provider)
    │   ├── app.dart                   # MaterialApp e definição de temas (Light/Dark)
    │   ├── models/
    │   │   ├── concelho.dart          # Modelo de concelho e busca
    │   │   ├── concelho_geometry.dart # Geometria e polígonos para o mapa
    │   │   └── risco_incendio.dart    # Modelo de risco FWI / RCM e previsão estendida
    │   ├── services/
    │   │   ├── ipma_api_service.dart  # Cliente HTTP para a API aberta do IPMA
    │   │   ├── ipma_scraper_service.dart # Extrator da previsão de 9 dias
    │   │   ├── map_geometry_service.dart # Carregador e projetor cartográfico
    │   │   └── cache_service.dart     # Persistência local (Hive)
    │   ├── providers/
    │   │   ├── risco_provider.dart    # Gestão de estado reativa de risco e previsão
    │   │   ├── acessibilidade_provider.dart # Opções de acessibilidade e escala de texto
    │   │   └── tema_provider.dart     # Gestão de tema claro/escuro/sistema
    │   ├── screens/
    │   │   ├── main_layout_screen.dart # Layout adaptativo com barra lateral e atalhos
    │   │   ├── home_screen.dart       # Dashboard com previsões e seletor global
    │   │   ├── map_screen.dart        # Mapa interativo com pesquisa integrada e zoom
    │   │   ├── favoritos_screen.dart  # Ecrã de concelhos favoritos
    │   │   └── definicoes_screen.dart # Ecrã de definições e acessibilidade
    │   ├── widgets/
    │   │   ├── portugal_map_painter.dart # Pintor vetorial do mapa de Portugal (Canvas 1000x1600)
    │   │   ├── modal_seletor_concelhos.dart # Seletor modal dos 278 concelhos com pesquisa
    │   │   ├── modal_niveis_risco.dart # Modal explicativo dos 5 níveis de risco
    │   │   ├── alerta_governo_card.dart # Aviso oficial da Proteção Civil
    │   │   ├── status_conexao_badge.dart # Indicador de estado online/offline
    │   │   ├── concelho_tile.dart     # Tile de concelho
    │   │   ├── risco_badge.dart       # Badge de nível de risco
    │   │   └── risco_card.dart        # Cartão de risco Hoje/Amanhã
    │   └── utils/
    │       ├── constants.dart         # URLs e constantes da aplicação
    │       └── risco_helpers.dart     # Cores cartográficas oficiais e datas
    ├── test/                          # Bateria de testes automatizados (48 testes)
    │   ├── acessibilidade_provider_test.dart
    │   ├── concelho_test.dart
    │   ├── favoritos_screen_test.dart
    │   ├── ipma_scraper_test.dart
    │   ├── localizacao_test.dart
    │   ├── map_geometry_service_test.dart
    │   ├── modal_seletor_concelhos_test.dart
    │   ├── previsao_alargada_card_test.dart
    │   ├── risco_helpers_test.dart
    │   ├── risco_provider_offline_test.dart
    │   └── widget_test.dart
    ├── pubspec.yaml                   # Dependências e versão do projeto
    └── windows/                       # Configurações nativas do Windows (janela, titlebar)
```

---

## ⌨️ Atalhos de Teclado (Desktop)

| Atalho | Ação |
| :--- | :--- |
| `Ctrl + F` | Focar instantaneamente a barra de pesquisa de concelhos |
| `Esc` | Fechar dropdowns, desselecionar concelho ou fechar diálogos |
| `+` ou `=` | Aumentar zoom no mapa de Portugal |
| `-` | Diminuir zoom no mapa de Portugal |
| `0` | Centrar Portugal e repor zoom inicial |
| `Ctrl + 1..4` | Alternar entre abas (Início, Mapa, Favoritos, Definições) |
| `F5` / `Ctrl + R` | Forçar sincronização imediata com os servidores do IPMA |

---

## 💻 Para Programadores

O Flutter encontra-se instalado em `C:\Users\Utilizador\flutter\bin`.

### Executar em Modo de Desenvolvimento:
```powershell
flutter run -d chrome     # Web / PWA
flutter run -d windows    # Windows Desktop
```

### Executar Testes Automatizados:
```powershell
flutter test
```

### Análise de Código (Lint):
```powershell
flutter analyze
```

### Gerar Build de Produção:
```powershell
# Web (GitHub Pages / PWA)
flutter build web --release --base-href /PIR-app/

# Windows Desktop
flutter build windows --release
```
