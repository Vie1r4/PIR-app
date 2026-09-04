# PIR - Perigo de Incêndio Rural (IPMA)

Aplicação multiplataforma (Desktop Windows, Android e iOS) concebida para consultar de forma rápida, simples e direta o **Perigo de Incêndio Rural (PIR)** oficial disponibilizado pelo **IPMA (Instituto Português do Mar e da Atmosfera)**.

---

## 📌 Índice
1. [Sobre o Projeto](#-sobre-o-projeto)
2. [Funcionalidades](#-funcionalidades)
3. [Fonte de Dados](#-fonte-de-dados)
4. [Como Usar](#-como-usar)
5. [Roteiro de Testes Recomendado](#-roteiro-de-testes-recomendado)
6. [Estrutura do Projeto](#-estrutura-do-projeto)
7. [Para Programadores (Desenvolvimento & Build)](#-para-programadores)
8. [Próximos Passos (Roadmap)](#-próximos-passos-roadmap)

---

## 🌲 Sobre o Projeto

O objetivo não é reinventar um modelo de risco nem adicionar sobrecarga de autenticação ou servidores próprios. A aplicação consome diretamente a API pública do IPMA, transformando ficheiros técnicos em interfaces visuais legíveis, com:
- **Execução leve e rápida** no ambiente de trabalho e dispositivos móveis.
- **Armazenamento em cache local**, permitindo a consulta dos últimos dados conhecidos mesmo sem acesso à internet.
- **Foco no concelho do utilizador**, destacando a situação para **Hoje** e **Amanhã**.

---

## ✨ Funcionalidades

- 🔍 **Pesquisa Inteligente de Concelhos:** 278 concelhos de Portugal Continental indexados. A pesquisa é tolerante a maiúsculas, minúsculas e acentos (ex: pesquisar `agueda`, `águeda` ou `Águeda` devolve os mesmos resultados).
- 📅 **Previsão para Hoje e Amanhã:** Apresentação clara dos níveis de risco para o próprio dia e para o dia seguinte.
- ⭐ **Gestão de Favoritos:** Marcação de concelhos com acesso rápido e gestão simplificada.
- 🕒 **Data e Hora de Atualização:** Indicação clara de quando o ficheiro do IPMA foi emitido e quando a app sincronizou os dados.
- 📴 **Modo Offline & Cache Local:** Guarda as previsões na máquina local (usando Hive). Se a ligação à internet falhar, a app informa e exibe a última informação válida disponível.
- 🎨 **Tema Automático:** Adaptação instantânea ao tema Claro (Light) ou Escuro (Dark) do sistema operativo.
- 🖥️ **Janela Compacta para Desktop:** Dimensões otimizadas (420x700 px) para consulta rápida sem ocupar o ecrã todo.

---

## 📡 Fonte de Dados

Os dados são recolhidos diretamente dos endpoints abertos do IPMA:
- **Hoje:** `https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d0.json`
- **Amanhã:** `https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d1.json`

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
1. Ao abrir pela primeira vez, clica no botão **"Procurar Concelho"** (ou na lupa no topo direito).
2. Escreve o nome do teu concelho ou distrito na barra de pesquisa.
3. Clica no concelho pretendido. Este passará a ser o teu **concelho principal**.
4. Clica no ícone do coração (canto superior direito) se quiseres adicioná-lo aos teus **favoritos**.
5. Para atualizar os dados manualmente a qualquer instante, basta puxar a lista para baixo (pull-to-refresh) ou reabrir a aplicação.

---

## 🧪 Roteiro de Testes Recomendado

Para verificar que tudo está a funcionar a 100%, podes seguir este plano de testes:

| # | Teste | Procedimento | Resultado Esperado |
|---|---|---|---|
| **1** | **Arrancar a aplicação** | Clicar no atalho no Ambiente de Trabalho | Abre a janela (420x700) com tema coerente com o Windows. |
| **2** | **Pesquisar concelho** | Clicar na lupa e escrever `Braga`, `Lisboa` ou `Faro` | A lista filtra instantaneamente mostrando concelho, distrito e badge de risco. |
| **3** | **Pesquisa com/sem acentos** | Escrever `santarem` vs `Santarém`, ou `evora` vs `Évora` | Ambos encontram o mesmo concelho corretamente. |
| **4** | **Selecionar Concelho** | Tocar num concelho da lista de pesquisa | Regressa ao ecrã inicial com os cartões de **Hoje** e **Amanhã** preenchidos com as cores respetivas. |
| **5** | **Adicionar aos Favoritos** | No ecrã inicial, clicar no ícone de coração | O coração fica preenchido a vermelho. No ecrã de Favoritos (ícone na barra superior) o concelho passa a figurar. |
| **6** | **Remover de Favoritos** | No ecrã de Favoritos, deslizar o item ou carregar no coração | O concelho é removido da lista de favoritos. |
| **7** | **Teste de Modo Offline** | Desligar o Wi-Fi ou a internet e abrir a app | A aplicação abre normalmente, carrega a previsão do cache e exibe a mensagem de aviso informando que está a mostrar os últimos dados conhecidos. |

---

## 📁 Estrutura do Projeto

```text
Pir-app/
├── README.md                          # Este documento
├── GUIA_DE_TESTES_E_UTILIZACAO.md     # Manual detalhado de utilização e testes
└── pir_app/                           # Código-fonte da aplicação Flutter
    ├── assets/
    │   └── concelhos.json             # Mapeamento estático DICO -> Concelho/Distrito
    ├── lib/
    │   ├── main.dart                  # Ponto de entrada (Hive + Provider)
    │   ├── app.dart                   # MaterialApp e definição de temas (Light/Dark)
    │   ├── models/
    │   │   ├── concelho.dart          # Modelo de concelho e filtro de pesquisa
    │   │   └── risco_incendio.dart    # Modelo dos dados de perigo IPMA
    │   ├── services/
    │   │   ├── ipma_api_service.dart  # Cliente HTTP para a API do IPMA
    │   │   └── cache_service.dart     # Persistência local (Hive)
    │   ├── providers/
    │   │   └── risco_provider.dart    # Gestão de estado reativa
    │   ├── screens/
    │   │   ├── home_screen.dart       # Ecrã inicial (previsões de Hoje/Amanhã)
    │   │   ├── search_screen.dart     # Ecrã de pesquisa
    │   │   └── favoritos_screen.dart  # Ecrã de favoritos
    │   ├── widgets/
    │   │   ├── concelho_tile.dart     # Item de lista reutilizável
    │   │   ├── risco_badge.dart       # Badge circular colorido
    │   │   └── risco_card.dart        # Cartão destacado com gradiente de risco
    │   └── utils/
    │       ├── constants.dart         # URLs, textos e constantes
    │       └── risco_helpers.dart     # Cores, ícones e formatação de datas
    ├── pubspec.yaml                   # Dependências do projeto
    └── windows/                       # Configurações nativas do Windows
```

---

## 💻 Para Programadores

O Flutter encontra-se instalado em `C:\Users\Utilizador\flutter\bin` e já faz parte do teu `PATH`.

### Executar em Modo de Desenvolvimento (com Hot Reload):
```powershell
cd "c:\Users\Utilizador\Desktop\Trabalhos\Pir-app\pir_app"
flutter run -d windows
```

### Executar os Testes Unitários e de Widgets:
```powershell
flutter test
```

### Análise Estática de Código:
```powershell
flutter analyze
```

### Gerar Novo Executável de Release:
```powershell
flutter build windows --release
```

---

## 🗺️ Próximos Passos (Roadmap)

- [ ] **Fase 2 (iOS):** Criação do Widget nativo para o ecrã principal do iPhone (WidgetKit em SwiftUI via `home_widget`).
- [ ] **Fase 3 (Android):** Widget nativo para Android (Glance / AppWidgetProvider).
- [ ] **Desktop Tray Icon:** Minimizar para a área de notificação do Windows (junto ao relógio) com indicação da cor do risco em tempo real.
