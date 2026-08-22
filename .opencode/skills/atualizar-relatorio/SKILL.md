---
name: atualizar-relatorio
description: Atualiza docs/RELATORIO_ARTIGO.md antes de todo commit no projeto ph_indicador, para que o relatório científico sempre reflita o estado real do repositório. Use quando o usuário pedir para commitar/commit, fizer um commit, ou mencionar o relatório, o estado do repositório ou docs/RELATORIO_ARTIGO.md.
---

# Atualizar o relatório do projeto a cada commit

O `docs/RELATORIO_ARTIGO.md` é o relatório científico do projeto (base para um artigo). Ele contém uma descrição técnica com referências a arquivos/linhas (§2), uma tabela do estado do repositório (§2.6) e a lista de lacunas para publicação (§5.2). **Toda vez que o usuário for commitar, o relatório deve ser atualizado primeiro e incluído no mesmo commit.**

## Passos

### 1. Antes de qualquer commit

1. Rode `git status --short` e `git diff --stat` para ver o que mudou.
2. Identifique os arquivos alterados e agrupe a intenção da mudança (ex.: "novos testes", "correção de bug", "nova funcionalidade").

### 2. Atualize as seções afetadas do relatório

- **§2.1–2.5 (descrição técnica)**: se a mudança alterou arquivos descritos no relatório (ex.: `camera_capture_widget.dart`, `find_best_match_range_usecase.dart`, `database_helper.dart`), verifique se a descrição e as referências `arquivo:linha` continuam corretas e ajuste o que mudou (ex.: nova configuração, novo parâmetro, nova tela).
- **§2.6 (estado atual do repositório)** — SEMPRE:
  - Adicione uma linha na tabela de commits com o hash (curto) e uma descrição em português no mesmo estilo das existentes (minúsculas, imperativo: "adicionar...", "corrigir...", "implementar...").
  - Atualize a contagem de commits.
  - Se a árvore ficou limpa, mantenha a nota "árvore de trabalho limpa"; se houver pendências, registre-as.
- **§5.2 (lacunas para a publicação)**: se a mudança resolve uma lacuna listada, marque-a com **RESOLVIDO** e explique em uma frase o que foi feito (ex.: item 4 — suíte de testes). Se a mudança revelou um bug de produção, registre a descoberta e a correção na seção apropriada (ex.: item 4 já documenta o caso do `PRAGMA foreign_keys`).
- **§7 (estudo de caso)**: apenas se a mudança envolver dados experimentais novos.
- **§8 (referências)**: apenas se a mudança envolver nova literatura.

### 3. Verifique a consistência

- Confirme que os números de commits da §2.6 batem com `git log --oneline | wc -l`.
- Confirme que as referências a arquivos/linhas citadas ainda existem (`ls`/grep rápidos quando houver dúvida).

### 4. Commit único

- Faça `git add` dos arquivos de código **e** do `docs/RELATORIO_ARTIGO.md` no **mesmo commit** da mudança — o relatório nunca deve ficar desatualizado em relação ao HEAD.
- Mensagem de commit em português, minúscula, imperativo, no estilo do repositório (ex.: "adicionar suíte de testes e corrigir cascade do banco").

## Regras

- Não edite o relatório quando o commit for puramente documental do próprio relatório (evita loop).
- Se a mudança for trivial (ex.: remoção de prints), basta atualizar a tabela da §2.6 — não reescreva as seções técnicas.
- Nunca invente dados experimentais ou referências: use apenas o que está no código e no histórico do git.