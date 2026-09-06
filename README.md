# PIR - Perigo de Incêndio Rural (IPMA)

Aplicação multiplataforma (Desktop Windows, Android e iOS) concebida para consultar de forma rápida, simples e direta o **Perigo de Incêndio Rural (PIR)** oficial disponibilizado pelo **IPMA (Instituto Português do Mar e da Atmosfera)**.

---

## 📌 Índice
1. [Sobre o Projeto](#-sobre-o-projeto)
2. [Funcionalidades](#-funcionalidades)
3. [Fonte de Dados](#-fonte-de-dados)
4. [Como Usar](#-como-usar)
5. [Distribuição e Instalador (Windows)](#-distribuição-e-instalador-windows)
6. [Decisões de Arquitetura (ADRs)](#-decisões-de-arquitetura-adrs)
7. [Roteiro de Testes Recomendado](#-roteiro-de-testes-recomendado)
8. [Estrutura do Projeto](#-estrutura-do-projeto)
9. [Para Programadores (Desenvolvimento & Build)](#-para-programadores)
10. [Próximos Passos (Roadmap)](#-próximos-passos-roadmap)

---

## 🌲 Sobre o Projeto

O objetivo não é reinventar um modelo de risco nem adicionar sobrecarga de autenticação ou servidores próprios. A aplicação consome diretamente a API pública do IPMA, transformando ficheiros técnicos em interfaces visuais legíveis, com:
- **Execução leve e rápida** no ambiente de trabalho e dispositivos móveis.
- **Armazenamento em cache local**, permitindo a consulta dos últimos dados conhecidos mesmo sem acesso à internet.
- **Foco no concelho do utilizador**, destacando a situação para **Hoje** e **Amanhã**.

---

## ✨ Funcionalidades

- 🔍 **Pesquisa Inteligente de Concelhos:** 278 concelhos de Portugal Continental indexados. A pesquisa é tolerante a maiúsculas, minúsculas e acentos (ex: pesquisar `agueda`, `águeda` ou `Águeda` devolve os mesmos resultados).
- 📅 **Previsão Estendida (até 9 Dias):** Apresentação detalhada para Hoje, Amanhã e os restantes 7 dias com níveis de risco, temperaturas (mín/máx) e vento.
- 🗺️ **Mapa Vetorial Interativo Oficial:** Mapa geográfico offline de todos os concelhos de Portugal Continental com zoom, pan, seleção interativa e cores cartográficas oficiais do IPMA.
- ⭐ **Gestão de Favoritos:** Marcação de concelhos com acesso rápido e gestão simplificada com badge de contagem.
- 🕒 **Data e Hora de Atualização:** Indicação clara de quando o ficheiro do IPMA foi emitido e quando a app sincronizou os dados.
- 📴 **Modo Offline & Cache Local:** Guarda as previsões na máquina local (usando Hive). Se a ligação à internet falhar, a app informa e exibe a última informação válida disponível.
- 🎨 **Tema Automático:** Adaptação instantânea ao tema Claro (Light) ou Escuro (Dark) do sistema operativo.
- 🖥️ **Interface Adaptativa para Desktop:** Janela moderna (1180x780 px) com barra lateral de navegação (NavigationRail) e visualização de cartões lado a lado.

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

### No Computador (Windows Desktop):
1. **Pelo Atalho do Ambiente de Trabalho:**
   - Clica duas vezes no ícone **`PIR - Incêndio Rural`** no teu Ambiente de Trabalho.
2. **Localização do Executável:**
   - Caso queiras aceder diretamente à pasta de distribuição:
     `pir_app\build\windows\x64\runner\Release\pir_app.exe`

### Primeiros Passos na Aplicação:
1. Ao abrir, podes navegar pela **Barra Lateral**:
   - **Início**: Cartões de Hoje e Amanhã + carrossel com os 9 dias.
   - **Mapa de Risco**: Visualização completa de Portugal pintado por risco com seletor de dias.
   - **Pesquisa**: Busca direta por concelho ou distrito.
   - **Favoritos**: Acesso imediato aos teus locais marcados.
2. Para atualizar os dados manualmente, basta fazer pull-to-refresh na página inicial ou reabrir a aplicação.

---

## 📦 Distribuição e Instalador (Windows)

A aplicação suporta duas modalidades de entrega prontas para produção:

1. **Pacote Portátil (ZIP):**
   - Pasta autónoma com o executável `pir_app.exe`, bibliotecas dinâmicas e assets em `data/flutter_assets`.
   - Pode ser descompactado e executado em qualquer computador com Windows 10/11 x64 sem necessidade de instalação ou privilégios de administrador.
2. **Instalador Nativo (Inno Setup):**
   - Cria o executável `PIR_App_v1.1.0_Setup.exe` que instala a aplicação em `%LOCALAPPDATA%\Programs\PIR App` (instalação por utilizador sem necessidade de UAC/admin).
   - Cria atalhos no Menu Iniciar e no Ambiente de Trabalho.
   - Integração completa com o Desinstalador nativo do Windows.

Para gerar os artefactos automaticamente, executa o script PowerShell:
```powershell
.\installer\build_installer.ps1
```
Os ficheiros gerados serão guardados na pasta `dist/`:
- `dist/PIR_App_v1.1.0_Windows_x64.zip` (Portátil)
- `dist/PIR_App_v1.1.0_Setup.exe` (Instalador, se o Inno Setup estiver instalado)

---

## 🏛️ Decisões de Arquitetura (ADRs)

O projeto adota o formato *Architecture Decision Records* (ADR) para documentar formalmente o racional, as alternativas consideradas e o impacto de escolhas chave de engenharia de software:

| ADR | Título | Estado | Foco Principal |
| :---: | :--- | :---: | :--- |
| [**0001**](docs/adr/0001-modelo-hibrido-ipma-api-e-scraper.md) | Modelo Híbrido IPMA (API Aberta + Scraper de 9 Dias) | Aceite | Resiliência de dados e previsão estendida sem backend intermediário |
| [**0002**](docs/adr/0002-persistencia-local-com-hive.md) | Persistência Local e Cache Offline com Hive NoSQL | Aceite | Desempenho sub-milissegundo, tolerância a falhas de rede e zero setup nativo SQLite |
| [**0003**](docs/adr/0003-projecao-cartografica-vetorial-canvas.md) | Projeção Cartográfica Vetorial Offline em CustomPainter | Aceite | Renderização de 278 concelhos a 60/120 FPS sem WebViews nem dependências de tiles pesadas |

Os registos detalhados encontram-se disponíveis no diretório [`docs/adr/`](docs/adr/).

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
    ├── test/                          # Bateria de testes automatizados (21 testes)
    │   ├── concelho_test.dart
    │   ├── ipma_scraper_test.dart
    │   ├── risco_helpers_test.dart
    │   ├── acessibilidade_provider_test.dart
    │   ├── modal_seletor_concelhos_test.dart
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
flutter run -d windows
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
flutter build windows --release
```
