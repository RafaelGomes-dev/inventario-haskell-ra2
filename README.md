# Sistema de Inventário — Atividade Avaliativa RA2

Sistema de gerenciamento de inventário desenvolvido em **Haskell**, com interação via terminal, persistência de estado em disco e log de auditoria. O projeto pratica conceitos de programação funcional, manipulação de estado e operações de I/O, mantendo separação rigorosa entre funções puras (lógica de negócio) e impuras (I/O).

---

## 🔗 Ambiente de Execução

> **Execute o projeto sem modificações aqui:** https://onlinegdb.com/HC0-WqSBO
---

## 📚 Identificação

- **Instituição:** PUCPR
- **Disciplina:** Programação Logica e Funcional
- **Professor:** Frank Coelho de Alcantara

### Integrantes do grupo (ordem alfabética)

| Nome | Usuário no GitHub |
|------|-------------------|
| Erick Meister | [ @usuario ] |
| [Tiago Figueiredo ] | [ @usuario ] |
| Rafael Gomes | [@RafaelGomes-dev](https://github.com/RafaelGomes-dev) |



---

## ⚙️ Como compilar e executar

O projeto foi desenvolvido e testado no **Online GDB** (linguagem Haskell).

### Online GDB
1. Acesse [onlinegdb.com](https://www.onlinegdb.com/).
2. Selecione a linguagem **Haskell** no canto superior direito.
3. Cole o conteúdo de `Main.hs` no editor.
4. Clique em **Run**.

### Localmente (GHC)
```bash
ghc Main.hs -o inventario
./inventario
```

Na primeira execução, os arquivos `Inventario.dat` e `Auditoria.log` ainda não existem — o programa inicia com um inventário vazio e cria os arquivos conforme as operações são realizadas.

---

## 🕹️ Comandos disponíveis

| Comando | Sintaxe | Descrição |
|---------|---------|-----------|
| Adicionar | `add <id> <nome> <quantidade> <categoria>` | Adiciona um novo item ao inventário |
| Remover | `remove <id> <quantidade>` | Remove uma quantidade de um item existente |
| Atualizar | `update <id> <nova_quantidade>` | Define a quantidade de um item |
| Listar | `list` | Exibe todos os itens do inventário |
| Relatório | `report` | Gera relatórios a partir do log de auditoria |
| Sair | `sair` | Encerra o programa |

### Exemplo de uso

```
> add 001 Teclado 10 Perifericos
OK.
> add 002 Mouse 25 Perifericos
OK.
> remove 001 3
OK.
> list
001 | Teclado | qtd: 7 | Perifericos
002 | Mouse | qtd: 25 | Perifericos
> report
===== RELATORIO =====
Total de eventos: 3
Erros registrados: 0
Item mais movimentado: 001
> sair
Encerrando.
```

---

## 🗂️ Estrutura do projeto

```
inventario-haskell-ra2/
├── Main.hs          # Código-fonte completo
├── README.md        # Este arquivo
└── .gitignore       # Ignora arquivos de dados gerados em runtime
```

### Arquivos gerados em execução
- **`Inventario.dat`** — estado atual do inventário, sobrescrito a cada operação bem-sucedida.
- **`Auditoria.log`** — registro append-only de todas as operações (sucesso e falha).

---

## 🧱 Arquitetura

O sistema separa rigorosamente lógica pura de operações de I/O:

- **Tipos de dados:** `Item`, `Inventario` (`Map String Item`), `AcaoLog`, `StatusLog`, `LogEntry`. Todos derivam `Show` e `Read` para serialização.
- **Funções puras:** `addItem`, `removeItem`, `updateQty` — retornam `Either String ResultadoOperacao`, sinalizando falhas de lógica sem nenhuma operação de I/O.
- **Análise de logs (puras):** `historicoPorItem`, `logsDeErro`, `itemMaisMovimentado`.
- **Camada de I/O:** `main`, `loop`, parser de comandos, leitura/escrita de arquivos com tratamento de exceções (`catch`).

---

## 🧪 Cenários de Teste Manuais



### Cenário 1 — Persistência de Estado (Sucesso)
1. Iniciar o programa sem arquivos de dados.
2. Adicionar 3 itens.
3. Fechar o programa.
4. Verificar se `Inventario.dat` e `Auditoria.log` foram criados.
5. Reiniciar o programa e executar `list`.

**Resultado esperado:** após reiniciar, o comando `list` exibe os 3 itens carregados do disco.

**Resultado observado:** [ DESCREVA O QUE ACONTECEU / COLE PRINT ]

---

### Cenário 2 — Erro de Lógica (Estoque Insuficiente)
1. Adicionar um item com 10 unidades (ex.: `add 010 Teclado 10 Perifericos`).
2. Tentar remover 15 unidades (`remove 010 15`).
3. Verificar a mensagem de erro.
4. Verificar se `Inventario.dat` (e o estado em memória) ainda mostra 10 unidades.
5. Verificar se `Auditoria.log` contém uma `LogEntry` com `StatusLog (Falha ...)`.

**Resultado esperado:** mensagem de erro clara ("Estoque insuficiente"), estado preservado em 10 unidades e falha registrada no log.

**Resultado observado:** [ DESCREVA O QUE ACONTECEU / COLE PRINT ]

---

### Cenário 3 — Geração de Relatório de Erros
1. Após o Cenário 2, executar o comando `report`.
2. Verificar se a função `logsDeErro` exibe a entrada referente à falha do Cenário 2.

**Resultado esperado:** o relatório lista a tentativa de remoção com estoque insuficiente entre os erros.

**Resultado observado:** [ DESCREVA O QUE ACONTECEU / COLE PRINT ]

---

## 📋 Dados de teste

O sistema foi populado com no mínimo 10 itens distintos para validação dos relatórios e da lógica.

| ID | Nome | Quantidade | Categoria |
|----|------|------------|-----------|
| 001 | Teclado | 10 | Perifericos |
| 002 | Mouse | 25 | Perifericos |
| 003 | Monitor | 8 | Telas |
| 004 | Cabo HDMI | 40 | Cabos |
| 005 | Webcam | 12 | Perifericos |
| 006 | Headset | 15 | Audio |
| 007 | SSD 1TB | 20 | Armazenamento |
| 008 | Memoria RAM | 30 | Componentes |
| 009 | Fonte 600W | 9 | Componentes |
| 010 | Placa de Video | 5 | Componentes |


