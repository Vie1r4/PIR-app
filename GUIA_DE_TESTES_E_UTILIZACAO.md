# Manual do Utilizador & Roteiro de Testes — PIR App

Este documento foi preparado para te guiar passo a passo na utilização e validação da aplicação **PIR (Perigo de Incêndio Rural)** no teu computador.

---

## 1. Como Iniciar a Aplicação

Podes abrir a aplicação de duas formas:

1. **Atalho no Ambiente de Trabalho (Mais rápido):**
   - Vai ao teu Ambiente de Trabalho.
   - Dá duplo clique no ícone **`PIR - Incêndio Rural`**.
   
2. **Diretamente pelo ficheiro executável:**
   - Pasta: `c:\Users\Utilizador\Desktop\Trabalhos\Pir-app\pir_app\build\windows\x64\runner\Release\`
   - Ficheiro: `pir_app.exe`

---

## 2. Visão Geral dos Ecrãs e Funcionalidades

### 🏠 2.1. Ecrã Principal (Home)
- **Título superior:** "PIR - Incêndio Rural".
- **Botões no topo direito:**
  - 🔍 **Lupa:** Abre a pesquisa de concelhos.
  - ❤️ **Coração:** Abre a lista de favoritos.
- **Caso não haja concelho selecionado:** É apresentado um botão azul/laranja com o texto *"Procurar Concelho"*.
- **Quando selecionas um concelho:**
  - Nome do concelho em tamanho grande e o respetivo distrito logo por baixo.
  - Ícone de coração ao lado para marcar/desmarcar dos favoritos.
  - **Cartão de Hoje:** Mostra o nível de perigo atual (ex: *Elevado*, *Muito Elevado*), o valor numérico (1 a 5), ícone ilustrativo e a data de hoje.
  - **Cartão de Amanhã:** Mostra a previsão de risco para o dia seguinte.
  - **Rodapé:** Indicação de quando os dados foram obtidos e o carimbo de data/hora oficial do IPMA.

---

### 🔍 2.2. Ecrã de Pesquisa (Search)
- Escreve no campo de texto para filtrar instantaneamente entre os **278 concelhos** de Portugal Continental.
- A pesquisa procura tanto pelo **nome do concelho** como pelo **distrito**.
- **Não precisas de te preocupar com acentos nem maiúsculas:**
  - `braganca` encontra `Bragança`.
  - `evora` encontra `Évora`.
  - `faro` lista os concelhos do distrito de Faro.
- Em cada linha vês o nome, distrito, o círculo colorido com o nível de risco de hoje e o botão de coração para favoritar diretamente.
- Clicar num concelho seleciona-o e volta automaticamente ao ecrã inicial.

---

### ❤️ 2.3. Ecrã de Favoritos
- Apresenta a lista de concelhos que guardaste como favoritos.
- Se a lista estiver vazia, apresenta uma mensagem informativa.
- Clicar num concelho favorito leva-te ao ecrã inicial focado nesse concelho.
- Podes remover dos favoritos carregando no coração vermelho ou arrastando o item para o lado (swipe / dismiss).

---

## 3. Roteiro de Testes Passo a Passo

Segue esta lista de verificações práticas para comprovar o bom funcionamento de cada parte da aplicação:

### ✅ Teste 1: Abertura e Dimensão da Janela
- [ ] Clica no atalho do Ambiente de Trabalho.
- [ ] **O que deves observar:** A aplicação abre numa janela compacta com proporção de telemóvel (420 x 700 px) e título "PIR - Perigo de Incêndio Rural".

---

### ✅ Teste 2: Primeira Seleção de Concelho
- [ ] No ecrã inicial, clica no botão **"Procurar Concelho"** (ou na lupa no topo).
- [ ] Escreve as primeiras letras do teu concelho (por exemplo, `Águeda` ou `Coimbra`).
- [ ] Clica no concelho correspondente.
- [ ] **O que deves observar:** O ecrã volta ao início e surgem os dois cartões: **Hoje** e **Amanhã**, pintados com a cor correspondente ao perigo de incêndio desse local.

---

### ✅ Teste 3: Teste de Acentos na Pesquisa
- [ ] Abre novamente a pesquisa pela lupa.
- [ ] Experimenta escrever sem acentos: `santarem`.
- [ ] **O que deves observar:** Deves ver aparecer `Santarém` sem qualquer dificuldade.
- [ ] Experimenta pesquisar por um distrito (ex: `Leiria` ou `Viseu`).
- [ ] **O que deves observar:** São listados todos os concelhos pertencentes a esse distrito.

---

### ✅ Teste 4: Adicionar e Consultar Favoritos
- [ ] No ecrã principal com um concelho aberto, clica no ícone de coração no canto superior direito do cabeçalho.
- [ ] O ícone deve ficar preenchido a vermelho.
- [ ] Clica no ícone de favoritos na barra de topo (canto superior direito).
- [ ] **O que deves observar:** O concelho que marcaste aparece na lista de favoritos com o respetivo nível de risco.

---

### ✅ Teste 5: Persistência entre Reinícios (Memória da App)
- [ ] Fecha a janela da aplicação.
- [ ] Volta a abrir a aplicação pelo atalho do Ambiente de Trabalho.
- [ ] **O que deves observar:** A aplicação não pede para selecionar concelho novamente; ela lembra-se do último concelho principal que tinhas aberto e dos teus favoritos guardados.

---

### ✅ Teste 6: Teste do Modo Offline (Sem Internet)
- [ ] Desliga a tua ligação à internet (podes desligar o Wi-Fi ou ativar o Modo de Voo temporariamente).
- [ ] Fecha e volta a abrir a aplicação.
- [ ] **O que deves observar:**
  - A aplicação abre sem bloquear nem dar ecrã branco.
  - Apresenta os últimos dados de risco que tinha descarregado (vindos da cache Hive).
  - Surge uma barra de aviso suave no topo a indicar que não foi possível atualizar os dados e que está a mostrar a última informação disponível.
- [ ] Volta a ligar a internet e puxa a lista para baixo para atualizar.

---

## 4. Escala Oficial de Risco do IPMA

A aplicação utiliza as seguintes cores e classificações definidas para o RCM (Risco Conjuntural e Meteorológico):

| Valor | Classificação | Cor Visual |
| :---: | :--- | :--- |
| **1** | **Reduzido** | 🟢 Verde (`#4CAF50`) |
| **2** | **Moderado** | 🟡 Amarelo (`#FFC107`) |
| **3** | **Elevado** | 🟠 Laranja (`#FF9800`) |
| **4** | **Muito Elevado** | 🔴 Vermelho (`#F44336`) |
| **5** | **Máximo** | 🟣 Roxo escuro (`#9C27B0`) |

---

## 5. Perguntas Frequentes & Resolução de Dúvidas

**Q: Porque é que os Açores e a Madeira não estão na lista de concelhos?**  
*R:* O índice RCM (Perigo de Incêndio Rural) emitido pelo IPMA nestes ficheiros específicos (`rcm-d0.json` e `rcm-d1.json`) abrange apenas Portugal Continental. Os arquipélagos possuem sistemas de vigilância e relatórios meteorológicos diferenciados.

**Q: A que horas o IPMA costuma atualizar a previsão para o dia seguinte?**  
*R:* O IPMA normalmente atualiza os ficheiros durante a manhã e ao início da tarde. A app indica sempre no rodapé o carimbo exato da data e hora emitido pelo IPMA (`fileDate`).

**Q: Posso copiar a pasta da app para outro computador?**  
*R:* Sim! A pasta `pir_app\build\windows\x64\runner\Release\` contém tudo o que é necessário para correr a aplicação em qualquer computador com Windows 10/11 sem necessitar de instalar nada adicional.
