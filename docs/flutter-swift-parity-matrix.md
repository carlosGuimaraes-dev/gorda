# Matriz de Paridade SwiftUI ↔ Flutter

Data baseline: 2026-03-04  
Fonte de verdade UX/UI: `ios/AppGestaoServicos/Views.swift` + `Theme.swift`

Legenda:
- `Paridade OK`
- `Divergência visual`
- `Divergência funcional`
- `Risco de regressão`

## 1) Login

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Campos user/password | Na mesma tela de login | Na mesma tela | Paridade OK | |
| Seleção de perfil | No fluxo de login | Ajustado para login com `SegmentedButton` | Paridade OK | Migrado para seguir baseline |
| Texto principal/subtítulo | "Welcome back" + descrição | Ajustado para usar `AppStrings` equivalentes | Paridade OK | |
| Sessão e papel refletidos no app | Sim | Havia desvio entre `authState` e `offlineStore.session` | Risco de regressão | Corrigido com sincronização no `AgApp` |

## 2) Home shell / menu

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Tabs principais por perfil | Manager: Dashboard/Schedule/Clients/Finance/Settings; Employee sem Clients | Igual | Paridade OK | |
| Sheet de catálogos (Services/Employees/Teams) | Sim | Sim | Paridade OK | |
| Badge de conflitos em Settings | Sim | Parcial | Divergência visual | Badge ainda pode ser refinado para paridade |

## 3) Dashboard

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Segmentação Day/Week/Month | Sim | Sim | Paridade OK | |
| Role-based cards (Manager/Employee) | Sim | Sim | Paridade OK | |
| Métricas financeiras e operacionais | Sim | Sim | Paridade OK | Validar snapshots visuais |

## 4) Schedule

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Lista/agenda por período | Sim | Sim | Paridade OK | |
| Check-in/check-out | Sim | Sim | Paridade OK | Cobertura lógica adicionada em testes de store |
| Cancelamento fora de cálculos | Sim | Sim | Risco de regressão | Coberto por testes de geração financeira |

## 5) Clients

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| CRUD básico + detalhe | Sim | Sim | Paridade OK | |
| Filtros e ordenação | Sim | Sim | Paridade OK | |
| Histórico e criação de serviço | Sim | Sim | Paridade OK | |

## 6) Finance

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Closing wizard / receipts hub / emissão | Sim | Sim | Paridade OK | |
| Invoices + payroll + reports | Sim | Sim | Paridade OK | |
| Reissue/supersede invoice | Sim | Sim | Paridade OK | Coberto em teste de store |
| Disputa D+N | Sim | Sim | Paridade OK | Coberto em teste de store |
| Geração com cancelamento excluído | Sim | Sim | Paridade OK | Coberto em teste de store |

## 7) Settings

| Item | SwiftUI baseline | Flutter atual | Status | Observação |
|---|---|---|---|---|
| Sync + pending queue + last sync | Sim | Sim | Paridade OK | |
| Conflitos/Auditoria | Sim | Sim | Paridade OK | Strings hardcoded removidas |
| Idioma/moeda globais | Sim | Parcial | Divergência funcional | Moeda foi conectada ao estado persistido |
| Toggles notificação persistidos | Sim | Parcial | Divergência funcional | Migrados para `OfflineStore` |
| Canais de entrega persistidos | Sim | Parcial | Divergência funcional | Migrados para `AppPreferences` |

## Backlog operacional por PR

1. Qualquer PR de UI deve atualizar esta matriz.
2. Itens com `Risco de regressão` exigem teste automatizado no mesmo PR.
3. PR só fecha quando não introduzir novo item `Divergência funcional` sem justificativa explícita.
