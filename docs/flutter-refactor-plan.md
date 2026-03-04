# Plano de Refatoração Flutter por Paridade SwiftUI

Data: 2026-03-04  
Objetivo: restaurar paridade funcional e visual com a baseline SwiftUI sem remover nem inventar features.

## 1) Premissas obrigatórias

1. TDD em tudo: todo ajuste nasce de teste que falha.
2. Refatorar toda divergência relevante de UX/UI em relação ao SwiftUI.
3. Não excluir nem inventar funcionalidades fora do escopo definido.
4. Fechar gap entre "feito x faltante" com backlog rastreável.
5. Prioridade máxima para regressão lógica (regras financeiras, role-based e offline-first).

## 2) Fontes de verdade usadas

- PRD inicial: `prd/ios-servicos-prd.md`
- Backlog principal: `ios/AppGestaoServicos/BACKLOG.md`
- Wireframes base: `docs/Wireframes.md`
- Contrato backend: `docs/backend-api-contract.md`, `docs/backend-openapi.yaml`
- Baseline SwiftUI: `ios/AppGestaoServicos/Views.swift`, `ios/AppGestaoServicos/OfflineStore.swift`
- Estado Flutter: `mobile/flutter_app/lib/**`, `mobile/flutter_app/README.md`

## 3) Diagnóstico consolidado (alto nível)

### 3.1 O que está aderente

- Estrutura macro de módulos (Dashboard, Schedule, Clients, Finance, Settings).
- Offline-first com fila local (`pendingChanges`) e log de conflitos/auditoria local.
- Slice financeiro avançado (closing wizard, receipts hub, invoices/payroll, reports).
- Role-based navigation (manager vs employee).

### 3.2 Gaps críticos para corrigir

1. Testes insuficientes:
- Flutter hoje tem essencialmente 1 teste de widget.
- Não há rede de proteção para regras críticas (invoice/payroll/dispute/check-in/out/cancelamento).

2. Divergências de UX em fluxos de entrada:
- SwiftUI: role selection no login (segmentado na mesma tela).
- Flutter: role selection separado em segunda tela.
- Cópia visual/textual e hierarquia visual do login divergem da baseline.

3. Divergências de Settings com risco funcional:
- Strings hardcoded em inglês em trechos do Settings.
- Toggles locais não persistidos no `OfflineStore` em pontos de notificações.
- Dropdown de moeda com `onChanged: (_) {}` (sem efeito funcional).

4. Sync real com backend ainda pendente:
- Flutter e SwiftUI estão com sync stub; backend já prevê `/sync/push` e `/sync/pull`.
- Risco de inconsistência entre contrato e comportamento local.

5. Risco de regressão em regras financeiras:
- Regras de disputa D+N, supersede de invoice, payroll automático/manual e filtros por perfil exigem cobertura de teste dedicada.

## 4) Escopo congelado (sem invenção de feature)

Este plano preserva exatamente as capacidades já previstas no PRD/backlog.

Permitido:
- Ajustar UX para equivalência SwiftUI.
- Corrigir bugs de lógica.
- Completar itens explicitamente pendentes (ex.: sync real, Siri comando completo se confirmado no backlog).

Não permitido:
- Criar novos módulos fora do escopo.
- Remover fluxo previsto no PRD/backlog.

## 5) Estratégia de execução (TDD-first)

## Fase A — Baseline de regressão (obrigatória antes de refatorar UI)

Objetivo: proteger lógica antes de mexer forte em apresentação.

1. Criar suíte de testes de domínio/store:
- `offline_store_test.dart` cobrindo:
  - role-based visibilidade (employee vs manager)
  - cancelamento de task fora de cálculos
  - disputa invoice com janela D+N
  - supersede/reemissão de invoice
  - payroll automático por check-in/out
  - payroll manual com confirmação
  - pending queue e deduplicação no sync stub

2. Criar testes de widget smoke por fluxo:
- login + seleção de perfil
- dashboard manager/employee
- settings (sync/conflicts/audit/preferences)
- finance: invoice/payroll/receipts

3. Criar matriz de paridade SwiftUI↔Flutter (golden checklist):
- por tela, por componente crítico e por regra de negócio.

## Fase B — Paridade visual e de interação (sem mudar regra de negócio)

Objetivo: aproximar UX Flutter da SwiftUI baseline.

1. Login:
- unificar fluxo para role selection no contexto do login (como SwiftUI), salvo restrição técnica explícita.
- alinhar tipografia, espaçamento, prioridades visuais e textos.

2. Home shell/menu:
- validar equivalência de navegação principal + sheet de catálogos.

3. Settings:
- remover hardcodes, usar i18n.
- ligar todos controles ao estado persistido no store.
- corrigir ações sem efeito (ex.: moeda global).

4. Finance visual:
- alinhar hierarquia de cards, densidade de informação e fluxo de fechamento.

## Fase C — Paridade de integração backend/sync

Objetivo: sair de stub com segurança.

1. Implementar cliente de sync:
- `POST /v1/sync/push`
- `GET /v1/sync/pull`
- reconciliação LWW + conflito local/log.

2. Testes de contrato:
- validar payloads e parsing contra OpenAPI/contract docs.

3. Rollout controlado:
- feature flag para alternar stub vs real sync até estabilização.

## Fase D — Hardening de regressão

1. Testes E2E críticos (ou integração avançada) dos cenários de fechamento mensal.
2. Checklist de regressão manual guiado por perfil (manager/employee).
3. Gate de CI: bloqueio de merge sem testes críticos verdes.

## 6) Backlog priorizado (mais novo plano de execução)

Legenda: P0 crítico | P1 alto | P2 médio

### P0 — Proteção de regressão lógica

1. Criar testes unitários do `OfflineStore` para regras financeiras críticas.
2. Criar testes unitários para regras de agenda (check-in/out, cancelamento, filtros por perfil).
3. Criar testes de widget mínimos para Login, Settings e Finance.
4. Corrigir Settings para persistir toggles/preferências no store.
5. Corrigir seleção de moeda para realmente atualizar preferência global.

### P1 — Paridade SwiftUI de UX/UI

1. Reestruturar fluxo de login para espelhar SwiftUI (incluindo papel no fluxo de autenticação).
2. Ajustar textos/labels/layout dos cards principais para equivalência visual.
3. Revisar dashboard manager/employee contra baseline Swift.
4. Revisar shell/menu para equivalência de navegação e atalhos.

### P1 — Integração de sync

1. Implementar cliente API de sync.
2. Persistir cursor/since e tratamento de conflito por campo.
3. Criar testes de integração do sync com dublês de API.

### P2 — Acabamento e confiabilidade

1. Golden tests das telas críticas.
2. Checklist de acessibilidade e i18n (en-US/es-ES) nas telas migradas.
3. Revisão de performance de listas e renderizações pesadas.

## 7) Critérios de aceite globais da refatoração

1. Nenhuma feature do PRD/backlog removida.
2. Nenhuma feature nova fora de escopo adicionada.
3. Todos os fluxos críticos cobertos por testes automatizados.
4. Paridade de UX validada por checklist SwiftUI↔Flutter.
5. Regras financeiras e role-based sem regressão.

## 8) Riscos e mitigação

1. Risco: regressão de lógica ao mexer na UI.
- Mitigação: fase A obrigatória antes da fase B.

2. Risco: divergência oculta entre docs e comportamento real Swift.
- Mitigação: usar `Views.swift`/`OfflineStore.swift` como baseline executável, não só docs.

3. Risco: integração sync introduzir conflitos inesperados.
- Mitigação: rollout com feature flag e telemetria mínima de erros de sync.

## 9) Próxima ação sugerida (imediata)

Executar sprint de estabilização P0:
- escrever testes de `OfflineStore` para regras críticas;
- corrigir Settings (persistência + moeda + i18n hardcoded);
- só então iniciar ajustes visuais de login/dashboard.
