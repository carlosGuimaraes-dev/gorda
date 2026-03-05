# Matriz de Paridade SwiftUI ↔ Flutter

Data baseline: 2026-03-04
Fonte de verdade UX/UI: `ios/AppGestaoServicos/Views.swift` + `ios/AppGestaoServicos/Theme.swift`
Escopo: sem remover feature prevista e sem inventar feature nova.

Legenda:
- `Paridade OK`
- `Divergência visual`
- `Divergência funcional`
- `Risco de regressão`

## Leitura das alterações recentes (mais novas → mais antigas)

1. `a3bd39a` correção de import de teste (`widget_test.dart`) para estabilizar CI.
2. `7c86488` estabilização de testes Flutter no CI.
3. `47a70e9` restauração de gate estrito (testes voltam a bloquear merge).
4. `f2ef048` correções de testes de regressão.
5. `a7b4a77` pacote maior de refactor (settings persistência, sync gateway, testes).
6. `ca2558d`/`98defd5`/`b9026c6`/`32d027b` mudanças visuais amplas (“Liquid Glass”) com alto risco de afastamento do baseline SwiftUI.

Impacto: priorizar validação de regressão lógica e paridade visual nos fluxos que receberam mudança ampla de UI.

## Matriz de paridade por módulo

| Módulo | Item | SwiftUI baseline | Flutter atual | Status | Prioridade | Evidência principal |
|---|---|---|---|---|---|---|
| Login | Estrutura de login + role no mesmo fluxo | Card central com user/senha + picker de perfil + CTA | `TextField` + `SegmentedButton<UserRole>` + CTA | Paridade OK | P1 | `mobile/flutter_app/lib/features/auth/presentation/login_page.dart` |
| Login | Autenticação real | Fluxo integrado ao store/sessão | Repositório mock (`Future.delayed`, token fixo) | Divergência funcional | P0 | `mobile/flutter_app/lib/features/auth/application/auth_controller.dart` |
| Home/Menu | Tabs por perfil | Manager 5 abas, Employee sem Clients | Igual | Paridade OK | P1 | `mobile/flutter_app/lib/features/shell/home_shell.dart` |
| Home/Menu | Catálogos via sheet | Services/Employees/Teams | Igual | Paridade OK | P1 | `mobile/flutter_app/lib/features/shell/home_shell.dart` |
| Dashboard | Segmentação Day/Week/Month | Presente | Presente | Paridade OK | P1 | `mobile/flutter_app/lib/features/dashboard/presentation/dashboard_page.dart` |
| Dashboard | Role-based manager vs employee | Presente | Presente | Paridade OK | P1 | `mobile/flutter_app/lib/features/dashboard/presentation/dashboard_page.dart` |
| Schedule | Filtro role-based employee | Visibilidade por vínculo real de usuário/time | Filtro usa `assignedEmployeeId == session.name` (potencial inconsistência ID/nome) | Divergência funcional | P0 | `mobile/flutter_app/lib/features/schedule/presentation/schedule_page.dart` |
| Schedule | Check-in/check-out e cancelamento | Regras críticas de cálculo | Implementado, mas precisa cobertura forte | Risco de regressão | P0 | `mobile/flutter_app/lib/features/offline/application/offline_store.dart` |
| Clients | CRUD + filtros + detalhe | Presente | Presente (client-side) | Paridade OK | P1 | `mobile/flutter_app/lib/features/clients/presentation/clients_page.dart` |
| Finance | Hub manager + payroll employee | Presente | Presente | Paridade OK | P1 | `mobile/flutter_app/lib/features/finance/presentation/finance_page.dart` |
| Finance | Disputa D+N, supersede/reissue, payroll auto/manual | Regras centrais | Implementado no store | Risco de regressão | P0 | `mobile/flutter_app/lib/features/offline/application/offline_store.dart` |
| Finance | Organização de código da tela | Estrutura Swift segmentada por views | Flutter monolítico em arquivo grande | Risco de regressão | P1 | `mobile/flutter_app/lib/features/finance/presentation/finance_page.dart` |
| Settings | Persistência real de idioma/moeda/notificações/canais | Persistido e refletido na UI | Parcialmente conectado, precisa fechar gaps e validar i18n | Divergência funcional | P0 | `mobile/flutter_app/lib/features/settings/presentation/settings_page.dart` |
| Sync | Push/pull/conflicts/audit em contrato backend | Previsto em docs backend | `StubSyncGateway`, sem integração real | Divergência funcional | P0 | `mobile/flutter_app/lib/features/offline/application/sync_gateway.dart` |

## Backlog inicial de refatoração (derivado da matriz)

### P0 (bloqueante)

1. Fechar lacuna de autenticação mock (sem inventar endpoint: usar contrato existente e fallback offline).
2. Corrigir regra de visibilidade do Schedule para vínculo por ID canônico, não nome.
3. Expandir TDD no `OfflineStore` para regras financeiras e agenda com cenários compostos de regressão.
4. Finalizar persistência end-to-end em Settings (idioma/moeda/toggles/canais + i18n en-US/es-ES).
5. Implementar sync real (`/v1/sync/push`, `/v1/sync/pull`, `/v1/conflicts`, `/v1/audit`) sem quebrar fallback local.

### P1

1. Revisar e ajustar paridade visual pós “Liquid Glass” contra `Theme.swift` (tokens, hierarquia, densidade).
2. Quebrar `finance_page.dart` em subcomponentes para reduzir risco de regressão em manutenção.
3. Consolidar golden tests/snapshots de Login, Dashboard, Settings e Finance.

## Checklist executável por PR

- [ ] PR atualiza esta matriz quando altera Login/Home/Dashboard/Schedule/Clients/Finance/Settings.
- [ ] Nenhum item novo de `Divergência funcional` foi introduzido sem justificativa documentada.
- [ ] Todo item marcado `Risco de regressão` no escopo do PR possui teste automatizado no mesmo PR.
- [ ] Se tocar Settings, validar persistência real de preferência + i18n sem hardcode na tela alterada.
- [ ] Se tocar Sync/Offline, validar fila pendente, deduplicação e reconciliação.
- [ ] Se tocar Finance, validar disputa D+N, supersede/reissue e payroll (auto/manual).
- [ ] Se tocar UI crítica, anexar evidência de paridade com baseline SwiftUI (captura/comparação objetiva).

## Notas de governança

- Em divergência entre documentação e UX, prevalece Swift atual (`Views.swift` + `Theme.swift`).
- Em integração, prevalece contrato backend (`docs/backend-api-contract.md` e `docs/backend-openapi.yaml`).
- Merge bloqueado para PR sem cobertura de regressão crítica.
