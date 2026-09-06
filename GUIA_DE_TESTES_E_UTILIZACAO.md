# Manual do Utilizador & Roteiro de Testes — PIR App (v1.1.0)

Este documento guia passo a passo na utilização e validação da aplicação **PIR (Perigo de Incêndio Rural - IPMA)** no ambiente de trabalho (Windows Desktop).

---

## 1. Como Iniciar a Aplicação

Podes abrir a aplicação de várias formas:

1. **Atalho no Ambiente de Trabalho ou Menu Iniciar:**
   - Clica no atalho **`PIR - Incêndio Rural`**.
2. **Executável Portátil / Build:**
   - Caminho: `pir_app\build\windows\x64\runner\Release\pir_app.exe`
3. **Instalador Oficial:**
   - Executar `dist\PIR_App_v1.1.0_Setup.exe` (instalação automática limpa no Windows).

---

## 2. Visão Geral dos Ecrãs e Funcionalidades

### 🏠 2.1. Ecrã Principal (Início / Dashboard)
- **Cabeçalho Global:** Título, seletor rápido de concelho com modal de pesquisa entre os 278 concelhos de Portugal Continental, botão de favoritos e indicador de sincronização online/offline.
- **Cartões de Destaque:** 
  - **Hoje** e **Amanhã**: Nível de risco oficial (1 a 5), ícone climático, temperaturas esperadas e data correspondente.
- **Carrossel de Previsão Estendida (até 9 Dias):** Cartões individuais com a evolução meteorológica e índice FWI calculados pelo IPMA.
- **Aviso Oficial da Proteção Civil:** Faixa de recomendação preventiva ajustada dinamicamente ao grau de perigo.

### 🗺️ 2.2. Mapa Vetorial Interativo de Portugal Continental
- **Renderização Cartográfica Offline:** Todos os 278 concelhos desenhados com vetores e coloridos segundo o nível de perigo do dia selecionado.
- **Pesquisa Integrada:** Caixa de pesquisa flutuante com autocompletar e centralização automática no concelho pretendido.
- **Interatividade Total:**
  - Deslocar (Pan) clicando e arrastando com o rato.
  - Zoom fluído (botões `+` e `-` na interface ou roda do rato).
  - Reposicionamento com botão `0` (centrar Portugal).
  - Seleção de dias: Barra vertical para alternar instantaneamente a visualização entre Hoje, Amanhã e os restantes dias disponíveis.

### ⭐ 2.3. Gestão de Favoritos
- Acesso rápido a concelhos previamente guardados.
- Exibição de cartões detalhados com risco e temperatura.
- Gestão direta (adicionar/remover) com sincronização em tempo real com o Dashboard.

### ⚙️ 2.4. Definições & Acessibilidade
- **Tamanho do Texto:** 4 patamares calibrados (`pequeno`, `normal`, `grande`, `gigante`).
- **Tema Visual:** Claro (Light), Escuro (Dark) ou Automático (conforme o sistema operativo).
- **Reposição Rápida:** Botão para repor predefinições acessíveis.

---

## 3. ⌨️ Atalhos de Teclado no Windows

| Atalho | Ação |
| :--- | :--- |
| `Ctrl + F` | Focar instantaneamente a barra de pesquisa de concelhos |
| `Esc` | Fechar dropdowns de pesquisa, modais ou desselecionar o concelho |
| `+` ou `=` | Aumentar zoom no mapa cartográfico |
| `-` | Diminuir zoom no mapa cartográfico |
| `0` | Centrar Portugal Continental e repor escala inicial |
| `Ctrl + 1` | Navegar para o ecrã de **Início** |
| `Ctrl + 2` | Navegar para o **Mapa & Pesquisa** |
| `Ctrl + 3` | Navegar para os **Favoritos** |
| `Ctrl + 4` | Navegar para as **Definições** |
| `F5` / `Ctrl + R` | Forçar sincronização imediata com os servidores do IPMA |

---

## 4. Roteiro de Testes Passo a Passo

Segue esta lista de verificações práticas para comprovar o funcionamento da versão 1.1.0:

### ✅ Teste 1: Arranque e Identidade Visual
- [ ] Executa a aplicação.
- [ ] **Resultado Esperado:** A janela desktop abre em formato moderno (1180x780 px) com barra de navegação lateral (`NavigationRail`). O ícone na barra de tarefas e no topo da janela apresenta o logótipo oficial do PIR (não o ícone padrão do Flutter).

### ✅ Teste 2: Seletor Global de Concelhos
- [ ] No topo da página inicial, clica no nome do concelho atual.
- [ ] **Resultado Esperado:** Abre o diálogo modal com os 278 concelhos. Ao pesquisar por `agueda`, `braga` ou `coimbra`, a filtragem é instantânea e tolerante a acentos. Selecionar um concelho atualiza imediatamente todos os dados da página inicial.

### ✅ Teste 3: Navegação e Interação no Mapa
- [ ] Clica na aba **Mapa** (ou pressiona `Ctrl + 2`).
- [ ] Clica e arrasta no mapa para verificar o movimento suave de câmara.
- [ ] Pressiona `+` e `-` para testar o zoom via teclado, e `0` para recentrar.
- [ ] Clica em concelhos diferentes no mapa para confirmar o cartão flutuante com dados de risco.

### ✅ Teste 4: Acessibilidade e Tamanhos de Letra
- [ ] Vai ao ecrã de **Definições** (ou pressiona `Ctrl + 4`).
- [ ] Alterna entre os tamanhos de letra (`pequeno`, `normal`, `grande`, `gigante`).
- [ ] **Resultado Esperado:** Toda a interface adapta as fontes e espaçamentos sem sobreposição nem quebra de layout.

### ✅ Teste 5: Modo Offline & Tolerância de Rede
- [ ] Desliga o Wi-Fi ou a ligação à internet do computador.
- [ ] Fecha e reabre a aplicação.
- [ ] **Resultado Esperado:** A aplicação carrega os dados armazenados em cache local (Hive NoSQL) com badge indicativo de estado offline e sem mensagens de falha impeditivas.

---

## 5. Escala Oficial de Risco do IPMA

| Valor | Classificação | Cor Visual | Ação Recomendada |
| :---: | :--- | :---: | :--- |
| **1** | **Reduzido** | 🟢 Verde (`#4CAF50`) | Condições normais de segurança |
| **2** | **Moderado** | 🟡 Amarelo (`#FFC107`) | Atenção a trabalhos rurais com maquinaria |
| **3** | **Elevado** | 🟠 Laranja (`#FF9800`) | Cuidados redobrados, restrições habituais |
| **4** | **Muito Elevado** | 🔴 Vermelho (`#F44336`) | Risco severo, fortes restrições |
| **5** | **Máximo** | 🟣 Roxo escuro (`#9C27B0`) | Proibições legais estritas em meio florestal |
