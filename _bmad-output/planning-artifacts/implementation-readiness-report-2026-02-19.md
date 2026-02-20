---
reportDate: 2026-02-19
project: gorda
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
filesIncluded:
  prd:
    - prd/ios-servicos-prd.md
  architecture:
    - docs/architecture-backend.md
    - docs/architecture-frontend.md
    - docs/architecture-ios_app.md
    - docs/integration-architecture.md
  epicsStories:
    - BACKLOG.md
  supporting:
    - _bmad-output/implementation-artifacts/sprint-status.yaml
    - docs/index.md
  ux:
    - ios/AppGestaoServicos/Views.swift
    - ios/AppGestaoServicos/Theme.swift
---

# Implementation Readiness Assessment Report

> Status note (2026-02-20): This report is historical and was generated before the final UX artifacts were written.  
> Current UX references now exist in `_bmad-output/planning-artifacts/ux-design-specification.md` and `_bmad-output/planning-artifacts/wireframes-final-v1.md`.

**Date:** 2026-02-19
**Project:** gorda

## Document Discovery

### PRD Files Found

**Whole Documents:**
- prd/ios-servicos-prd.md (8206 bytes, 2025-12-29 17:00:22)

**Sharded Documents:**
- None

### Architecture Files Found

**Whole Documents:**
- docs/architecture-backend.md (1507 bytes, 2026-02-19 19:23:32)
- docs/architecture-frontend.md (1862 bytes, 2025-12-29 00:19:24)
- docs/architecture-ios_app.md (1524 bytes, 2026-02-19 19:23:32)
- docs/integration-architecture.md (996 bytes, 2026-02-19 19:23:32)

**Sharded Documents:**
- None

### Epics & Stories Files Found

**Whole Documents:**
- BACKLOG.md (15449 bytes, 2026-02-19 20:38:22)

**Supporting Status/Index Files:**
- _bmad-output/implementation-artifacts/sprint-status.yaml (4914 bytes, 2026-02-19 20:39:03)
- docs/index.md (2599 bytes, 2026-02-19 19:23:49)

### UX Design Files Found

**Whole UX Documentation Files (.md):**
- None found

**UX/UI Source Files Provided as Supporting Input:**
- ios/AppGestaoServicos/Views.swift (205154 bytes, 2025-12-29 17:48:50)
- ios/AppGestaoServicos/Theme.swift (425 bytes, 2025-12-04 20:04:16)

### Issues Found

- WARNING: No dedicated UX markdown document (`*ux*.md`, `*ui*.md`, `*design*.md`) was found.
- No duplicate whole-vs-sharded document formats were detected.

## PRD Analysis
### Functional Requirements
## Functional Requirements Extracted
FR1: dados pessoais, telefone (com DDI), WhatsApp opcional (pode ser diferente do telefone), e-mail, endereços e detalhes do imóvel administrado.
FR2: perfil com foto (a partir dos Contatos do iOS quando disponível), documentos, telefone (com DDI) e informações de remuneração.
FR3: menu lateral em sheet (hambúrguer) com atalhos para Dashboard/Agenda/Clients/Finance/Settings e catálogos de Services/Employees/Teams; criação de times, movimentação de funcionários entre times e gerenciamento de tipos de serviço (CRUD).
FR4: o usuário escolhe seu perfil no primeiro acesso; toda a experiência (dashboard, agenda, financeiro) é filtrada de acordo com o papel (Employee vê apenas payroll no Finance).
FR5: idioma (en-US/es-ES), moeda padrão (USD/EUR) e canais de envio de invoice (WhatsApp/SMS/Email) são escolhidos na aba Settings e aplicados aos cadastros/fluxos.
FR6: CRUD de serviços; cada funcionário visualiza apenas sua agenda e tarefas da equipe; visões diária, semanal e mensal, com cards de tarefas e filtro por equipe. Cancelamentos mantêm histórico e não entram nos cálculos financeiros.
FR7: uso completo sem conexão; sincronização automática ao voltar online com resolução de conflitos priorizando dados locais e registrando conflitos quando houver divergências.
FR8: local-first com fila local; quando houver backend, aplicar merge com prioridade local e registrar conflitos em log.
FR9: comandos de voz para agendar; push/local notifications para chegadas, cancelamentos e alterações.
FR10: lançamento e acompanhamento de recebimentos e pagamentos em **USD** e **EUR** (sem suporte a BRL na primeira versão), com vínculo automático entre serviços, clientes e funcionários quando houver preço base de serviço.
FR11: resumo mensal/semanal e intervalo custom por cliente e funcionário, com export simples (CSV/PDF) para compartilhamento interno.
FR12: Para funcionários (Employee): visão diária/semanal/mensal da agenda, serviços concluídos no período e valor estimado a receber apenas para tasks com check-in/check-out efetivos.
FR13: Para gestores (Manager): visão por equipe da realização das tarefas (cards por equipe + gráfico de tarefas por status) e cards financeiros com Contas a Pagar/Receber e fluxo de caixa, incluindo gráfico comparando Recebíveis x Pagáveis.
FR14: Splash Screen da AG Home Organizer International, seguida de login seguro em SwiftUI com tema azul moderno.
FR15: Integração com Contatos do iOS (requisito guarda-chuva para avatar/foto e importação de dados básicos).
FR16: Exibir avatar/foto de cliente e funcionário a partir dos Contatos, quando existir correspondência por nome/telefone.
FR17: Permitir importar dados básicos (nome, telefone) de um contato na criação/edição de funcionário e cliente.
FR18: Invoices e Payroll (requisito guarda-chuva para as capacidades de recebíveis/pagáveis, disputa, geração e detalhamento).
FR19: Tela dedicada para invoices (recebíveis) e payroll (pagáveis) com CRUD, edição permitida respeitando janela pós‑vencimento configurável (D+N), marcação de disputa com motivo e reenvio pelo canal definido pelo Manager (WhatsApp/SMS/Email), em ordem de prioridade.
FR20: Geração de invoices agregados por cliente dentro de um período, separados por moeda (um invoice por cliente por moeda), com PDF (QuickLook + share sheet) contendo line items das tasks do intervalo e instruções de pagamento; permitir re-geração parcial por período.
FR21: Payroll pode ser gerado manualmente sem check-in/out, com confirmação do Manager.
FR22: Payroll detalhado por funcionário: período, horas/dias trabalhados, taxa/hora, base pay, bônus, descontos, impostos, reembolsos, net pay e notas (CRUD completo pelo Manager).
FR23: Disputa de invoice iniciada pelo cliente via e-mail/texto ou botao no PDF; permitida a qualquer momento (mantendo historico) e com ajustes permitidos pelo Manager; janela pos-vencimento e configuravel (D+N dias).
FR24: Despesas out-of-pocket com preview e reenvio de recibo (receiptData) para o cliente/gestor.
FR25: Auditoria básica: log de alterações em tarefas e finanças (quem/quando), visível no Settings.
FR26: Login → sincronização inicial → acesso à home com resumo de agenda e notificações.
FR27: Cadastro de cliente/imóvel → associação a serviços → agendamento para funcionário/equipe.
FR28: Funcionário abre sua agenda (dia/mês) → visualiza tarefas atribuídas → registra status (em andamento, concluído, cancelado).
FR29: Operação offline → registros ficam em fila local → sincronização ao recuperar conexão.

Total FRs: 29
### Non-Functional Requirements
## Non-Functional Requirements Extracted
NFR1: Plataforma: iOS (Swift, UIKit/SwiftUI conforme padrão do projeto).
NFR2: Armazenamento local: Core Data ou SQLite para suporte offline; filas de sincronização para eventos pendentes.
NFR3: Segurança: armazenamento seguro de credenciais (Keychain) e comunicação criptografada.
NFR4: Segurança local: criptografia de dados sensíveis em repouso (ex.: contatos e documentos).
NFR5: Performance: respostas em menos de 200 ms para navegação principal em dispositivos-alvo recentes.
NFR6: Acessibilidade: suporte a Dynamic Type, VoiceOver e contrastes adequados.
NFR7: Internacionalização: interface e conteúdo em **Inglês Americano (en-US)** e **Espanhol da Espanha (es-ES)**; sem suporte a Português do Brasil na primeira versão (tradução PT-BR avaliada como melhoria futura).
NFR8: Tempo médio de criação de um serviço/agendamento < 1 min.
NFR9: >95% das ações críticas disponíveis offline.
NFR10: Taxa de falhas na sincronização < 2% por semana.
NFR11: Engajamento de notificações: >60% abertas em até 10 minutos.
NFR12: Consistência: eventual.

Total NFRs: 12
### Additional Requirements
- MVP inclui Employees, Service Types e Teams.
- Offline local-first com fila local e pontos de extensão para sync futuro.
- Conflitos: merge com prioridade local + log de conflito.
- Invoices: geração manual com re-geração parcial por período.
- Payroll: permitido manualmente sem check-in/out, com confirmação do Manager.
- Task cancelada mantém histórico e não entra nos cálculos.
- Disputa de invoice permitida a qualquer momento e iniciada pelo cliente.
- Disputa: Manager pode ajustar invoice mesmo após disputa, respeitando janela pos-vencimento configuravel (D+N dias).
- Notificações: locais + base pronta para push.
- Segurança: Keychain + criptografia local de dados sensíveis.
- Localização: en-US e es-ES implementados.
- Moeda global: Manager define e aplica sem conversão.
- Dashboard: contagens + cashflow + estimativa de payroll.
- Backend/Auth: Clerk.
- Storage de anexos: Cloudflare R2.
- Backend runtime: Node.js + TypeScript (Vercel).
- Banco: Postgres.
- Multi-tenant: habilitado na v1.
- Sync: last-write-wins com log de conflito.
- Notificações reais habilitadas na v1: WhatsApp (Meta Cloud API) + Email (Resend). SMS/iMessage é device-only.
- Consistência: eventual.
- Risco/Mitigação: Conflitos de dados na sincronização: usar controle de versão/etags e regras de mesclagem previsíveis.
- Risco/Mitigação: Latência de notificações: fallback para notificações locais quando push indisponível.
- Risco/Mitigação: Privacidade de dados sensíveis: limitar escopos de dados em cache local e criptografar campos confidenciais quando aplicável.

### PRD Completeness Assessment
- O PRD cobre módulos centrais e fluxos principais com granularidade suficiente para rastreabilidade.
- Requisitos funcionais e não funcionais estão descritos de forma explícita, porém sem numeração nativa FR/NFR no documento fonte.
- Critérios de aceitação detalhados por requisito ainda dependem do backlog e refinamento de stories.

## Epic Coverage Validation

## Epic FR Coverage Extracted

FR1: Covered in Epic 4 (Story 4.1)
FR2: Covered in Epic 5 (Story 5.1)
FR3: Partially covered in Epic 5 (Story 5.2) and Epic 6 (Story 6.1)
FR4: Covered in Epic 1 (Story 1.5), Epic 7 (Story 7.1), Epic 8 (Story 8.2), Epic 11 (Story 11.2)
FR5: Partially covered in Epic 1 (Story 1.1)
FR6: Covered in Epic 7 (Stories 7.1, 7.2, 7.3)
FR7: Covered in Epic 2 (Story 2.1)
FR8: Covered in Epic 2 (Stories 2.1, 2.2)
FR9: Covered in Epic 7 (Story 7.6)
FR10: Covered in Epic 8 (Story 8.1)
FR11: Covered in Epic 8 (Story 8.3)
FR12: Covered in Epic 11 (Story 11.2) and Epic 7 (Story 7.4)
FR13: Covered in Epic 11 (Story 11.1)
FR14: Partially covered in Epic 1 (Story 1.3)
FR15: Partially covered in Epic 4 (Story 4.2)
FR16: Partially covered in Epic 4 (Story 4.2)
FR17: Covered in Epic 4 (Story 4.2)
FR18: Partially covered in Epic 9 and Epic 10
FR19: Covered in Epic 9 (Stories 9.2, 9.3, 9.4) and Epic 10
FR20: Covered in Epic 9 (Stories 9.1, 9.5) with dependency on Epic 6 (Story 6.2)
FR21: Covered in Epic 10 (Story 10.2)
FR22: Partially covered in Epic 10 (Stories 10.1, 10.2)
FR23: Covered in Epic 9 (Stories 9.2, 9.3)
FR24: Covered in Epic 8 (Story 8.4)
FR25: Covered in Epic 2 (Story 2.3)
FR26: Partially covered in Epic 1 (Story 1.3) and Epic 11
FR27: Covered in Epic 4 (Story 4.1), Epic 6 (Story 6.1), Epic 7 (Story 7.2)
FR28: Covered in Epic 7 (Stories 7.1, 7.2)
FR29: Covered in Epic 2 (Story 2.1)

Total FRs in epics (fully covered): 21

### Coverage Matrix

| FR Number | PRD Requirement | Epic Coverage | Status |
| --------- | --------------- | ------------- | ------ |
| FR1 | Cadastro de clientes/imóveis com dados e contatos | Epic 4 Story 4.1 | ✓ Covered |
| FR2 | Cadastro de funcionários com foto/documentos/remuneração | Epic 5 Story 5.1 | ✓ Covered |
| FR3 | Gestão de equipes e catálogos com menu | Epic 5.2 + Epic 6.1 | ⚠ Partial |
| FR4 | Escolha de perfil + experiência por papel | Epic 1.5 + 7.1 + 8.2 + 11.2 | ✓ Covered |
| FR5 | Preferências idioma/moeda/canais de envio | Epic 1.1 | ⚠ Partial |
| FR6 | Agenda com CRUD, visões e cancelamento | Epic 7.1 + 7.2 + 7.3 | ✓ Covered |
| FR7 | Operação offline com sincronização | Epic 2.1 | ✓ Covered |
| FR8 | Sync local-first com conflitos | Epic 2.1 + 2.2 | ✓ Covered |
| FR9 | Notificações e Siri | Epic 7.6 | ✓ Covered |
| FR10 | Financeiro payables/receivables em USD/EUR | Epic 8.1 | ✓ Covered |
| FR11 | Relatórios financeiros com export | Epic 8.3 | ✓ Covered |
| FR12 | Dashboard Employee com estimativa por check-in/out | Epic 11.2 + 7.4 | ✓ Covered |
| FR13 | Dashboard Manager com KPI e gráficos | Epic 11.1 | ✓ Covered |
| FR14 | Splash + login seguro | Epic 1.3 | ⚠ Partial |
| FR15 | Integração com contatos (guarda-chuva) | Epic 4.2 | ⚠ Partial |
| FR16 | Avatar/foto via contatos | Epic 4.2 | ⚠ Partial |
| FR17 | Importação básica de contatos | Epic 4.2 | ✓ Covered |
| FR18 | Invoices e Payroll (guarda-chuva) | Epic 9 + 10 | ⚠ Partial |
| FR19 | Tela invoices/payroll com disputa/reenvio | Epic 9 + 10 | ✓ Covered |
| FR20 | Invoices agregadas + PDF + line items | Epic 9.1 + 9.5 (+6.2) | ✓ Covered |
| FR21 | Payroll manual com confirmação | Epic 10.2 | ✓ Covered |
| FR22 | Payroll detalhado completo | Epic 10.1 + 10.2 | ⚠ Partial |
| FR23 | Disputa de invoice com D+N | Epic 9.2 + 9.3 | ✓ Covered |
| FR24 | Out-of-pocket com preview/reenvio | Epic 8.4 | ✓ Covered |
| FR25 | Auditoria básica em Settings | Epic 2.3 | ✓ Covered |
| FR26 | Fluxo login → sync → home | Epic 1.3 + 11 | ⚠ Partial |
| FR27 | Fluxo cliente → serviço → agendamento | Epic 4.1 + 6.1 + 7.2 | ✓ Covered |
| FR28 | Fluxo employee agenda → status | Epic 7.1 + 7.2 | ✓ Covered |
| FR29 | Fluxo offline fila local → sync | Epic 2.1 | ✓ Covered |

### Missing Requirements

- Nenhum FR sem cobertura explícita foi identificado nesta rodada.

### Coverage Statistics

- Total PRD FRs: 29
- FRs covered in epics (strict): 21
- FRs partially covered: 8
- FRs missing: 0
- Coverage percentage (strict): 72.41%

## UX Alignment Assessment

### UX Document Status

Not Found (no UX markdown document under `_bmad-output/planning-artifacts` matching `*ux*.md` or `*ux*/index.md`).

### Alignment Issues

- PRD descreve comportamentos UX/UI explícitos para um app iOS user-facing (role-based views, dashboard cards/charts, onboarding/login/splash, agenda, settings e contatos).
- Arquitetura existe, mas não há artefato UX formal com jornadas, estados de erro/empty/loading, regras de navegação e critérios de interação.
- A rastreabilidade UX→Arquitetura→Stories continua indireta, aumentando risco de divergência de implementação.

### Warnings

- WARNING: UX é claramente necessário e continua sem documento formal no conjunto de planning artifacts.
- WARNING: risco de interpretação inconsistente entre times/agentes para fluxos críticos de UI.
- Recommendation: criar UX spec (whole ou sharded) com fluxos por papel, estados de tela e critérios de interação testáveis.

## Epic Quality Review

### Epic Structure Validation

#### User Value Focus Check

- Os epics permanecem majoritariamente orientados a valor de usuário/negócio.
- Não foram identificados epics puramente técnicos sem valor funcional explícito.

#### Epic Independence Validation

- Dependências cross-epic seguem direção incremental (sem dependência circular observada).
- Melhoria aplicada: seção explícita de dependências adicionada ao backlog.

### Story Quality Assessment

#### Story Sizing Validation

- Stories permanecem com escopo implementável em incrementos curtos.
- Gaps críticos de cobertura FR foram convertidos em histórias explícitas (1.5, 2.3, 7.6, 8.3, 8.4).

#### Acceptance Criteria Review

- ACs existem para as histórias, porém ainda não padronizados em Given/When/Then.
- Persistem lacunas de testabilidade em cenários de erro e critérios mensuráveis em parte dos itens.

### Dependency Analysis

#### Within-Epic and Cross-Epic Dependencies

- Dependências críticas agora explícitas no backlog:
  - 1.5 antecede 7.1, 8.2, 11.2
  - 6.2 antecede 9.5
  - 7.4 antecede 10.1
  - 7.6 depende de 7.2 e 1.5
- Não foram encontradas referências explícitas a histórias futuras dentro do mesmo epic.

### Best Practices Compliance Checklist

- [x] Epic delivers user value
- [x] Epic can function independently
- [x] Stories appropriately sized
- [x] No forward dependencies explícitas
- [ ] Acceptance criteria em BDD (Given/When/Then)
- [ ] Critérios de erro e observabilidade consistentes em histórias críticas

### Quality Assessment Documentation

#### 🔴 Critical Violations

1. Ausência de artefato UX formal para produto user-facing.
- Remediation: criar UX spec e alinhar com PRD/arquitetura.

#### 🟠 Major Issues

1. Acceptance Criteria fora de padrão BDD em grande parte das histórias.
- Remediation: refinar ACs com Given/When/Then e critérios objetivos.

2. Cobertura parcial de FRs estruturais (menu/canais, contatos, guarda-chuva invoices/payroll, detalhamento payroll, fluxo login→sync→home).
- Remediation: desdobrar subtarefas/histórias de fechamento para os FRs parciais.

#### 🟡 Minor Concerns

1. Granularidade desigual em algumas histórias multi-capacidade.
2. Padronização semântica (task/serviço/invoice/payroll) ainda pode ser refinada.

### Actionable Recommendations

1. Criar UX document formal (jornadas, estados de tela, regras de interação).
2. Padronizar ACs em BDD nas histórias prioritárias da próxima sprint.
3. Converter FRs parciais em cobertura completa com stories/substories explícitas.

## Summary and Recommendations

### Overall Readiness Status

NEEDS WORK

### Critical Issues Requiring Immediate Action

- Falta de documento UX formal para um produto fortemente orientado a interface e fluxo de usuário.
- Critérios de aceitação ainda sem padronização BDD em grande parte das histórias.
- Há FRs com cobertura parcial que precisam de fechamento explícito antes de reduzir risco de execução.

### Recommended Next Steps

1. Criar o artefato UX (fluxos por papel, estados de tela, regras de navegação e interação).
2. Refinar ACs das histórias críticas para Given/When/Then com cenários de erro.
3. Converter FRs parcialmente cobertos em stories/substories objetivas no backlog.
4. Reexecutar o check de readiness após esses ajustes para confirmar status READY.

### Final Note

Nesta reavaliação, os gaps críticos de cobertura FR foram fechados com novas histórias explícitas, mas ainda existem pontos estruturais de qualidade e UX que impedem classificar o plano como pronto para implementação sem risco adicional.

**Assessment Date:** 2026-02-19
**Assessor:** Codex (BMad Workflow Execution)

---

## Reassessment (Rerun)

**Run Timestamp:** 2026-02-19 20:48:16 PST

### Document Discovery (Rerun)

- PRD: `prd/ios-servicos-prd.md`
- Epics/Stories: `BACKLOG.md`
- Architecture: `docs/architecture-backend.md`, `docs/architecture-frontend.md`, `docs/architecture-ios_app.md`, `docs/integration-architecture.md`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- UX document: `_bmad-output/planning-artifacts/ux-spec.md` (agora presente)

### FR Coverage (Rerun)

- Total FRs (baseline de validação): 31
- FRs cobertos (strict): 23
- FRs parcialmente cobertos: 8
- FRs sem cobertura: 0
- Coverage percentage (strict): 74.19%

### Quality Signals (Rerun)

- Stories no backlog: 35
- Stories com AC definido: 35
- ACs em padrão BDD completo (Given/When/Then): 13
- Percentual de AC BDD completo: 37.14%

### Delta vs Run Anterior

- ✅ Gaps críticos de cobertura FR resolvidos (FR5, FR13, FR15, FR26, FR27)
- ✅ Documento UX formal adicionado (`ux-spec.md`)
- ✅ Dependências críticas explicitadas no backlog
- ✅ Histórias críticas com AC BDD adicionadas/refinadas
- ⚠️ Ainda há cobertura parcial relevante e maioria dos ACs fora de BDD completo

### Updated Overall Readiness Status

NEEDS WORK

### Updated Critical/Major Findings

#### Critical

- Nenhum FR crítico permanece sem cobertura explícita.

#### Major

1. Apenas parte das histórias está em BDD completo (13/35).
2. FRs parcialmente cobertos ainda exigem fechamento explícito (principalmente frentes de UX/fluxo e detalhes funcionais finos).

### Updated Recommended Next Steps

1. Converter AC das 22 histórias restantes para Given/When/Then com cenário de erro.
2. Criar stories/substories para fechar os 8 FRs parciais com rastreabilidade explícita.
3. Reexecutar este check após fechamento de BDD + FRs parciais para buscar status READY.

### Root Verification Update (Post-Rerun)

- Verificação no código raiz confirmou:
  - ✅ seleção de perfil no login e experiência por papel
  - ✅ auditoria local (quem/quando) e log de conflitos no Settings
  - ✅ relatórios financeiros com export CSV/PDF
  - ✅ preview/reenvio de recibos out-of-pocket
  - 🟡 Siri implementada via Suggestions/shortcut donation; comando de voz dedicado ainda não totalmente fechado

Impacto no readiness:
- FR relacionado a Siri deve ser tratado como cobertura parcial nesta revisão de root.
- Status geral permanece: NEEDS WORK.
