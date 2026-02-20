# UX Specification (Initial)

**Project:** gorda (AG Home Organizer International)
**Date:** 2026-02-19
**Scope:** Base UX for implementation readiness (v1)

## 1. Product Context

- Plataforma principal: iOS (SwiftUI)
- Perfis: Employee e Manager
- Módulos núcleo: Login/Splash, Dashboard, Schedule, Clients, Finance, Settings, Employees
- Diretriz visual: UI limpa, foco operacional, cards, ações rápidas, poucos toques

## 2. Information Architecture

### Primary Navigation

- Dashboard
- Schedule
- Clients
- Employees
- Finance
- Settings

### Secondary / Quick Actions

- Quick actions em sheet (menu hambúrguer)
- Criar serviço
- Criar lançamento financeiro
- Reenviar invoice/recibo

## 3. Role-Based Experience

### Manager

- Visão completa de equipes, finanças, KPIs e cadastros
- Pode gerar/regerar invoices e payroll
- Pode editar preferências globais (idioma, moeda, canais)

### Employee

- Vê apenas suas tasks no Schedule
- Em Finance, vê apenas payroll próprio
- Executa check-in/out e acompanha ganhos estimados

## 4. Key User Journeys

### Journey A: Primeiro acesso e contexto de perfil

- Splash → Login
- Seleção de perfil (Employee/Manager) no primeiro acesso
- Redirecionamento para dashboard correspondente ao perfil

### Journey B: Criação e execução de serviço

- Manager cria task com cliente, funcionário e tipo de serviço
- Employee visualiza task atribuída
- Employee realiza check-in/out (com foto obrigatória quando aplicável)
- Task concluída atualiza indicadores e base financeira

### Journey C: Financeiro (Manager)

- Manager acessa invoices/payroll
- Gera invoice por período e moeda
- Trata disputa (D+N), reenvia e reemite quando necessário
- Gera payroll automático ou manual

### Journey D: Offline-first

- Usuário opera sem conexão
- Alterações entram em fila local
- Ao reconectar, sync processa pendências e conflitos são logados

## 5. Screen-Level Requirements

### Login/Splash

- Splash com branding AG Home Organizer International
- Login claro, foco em baixa fricção
- Erros de autenticação com mensagem acionável

### Dashboard

- Cards de KPI com hierarquia visual simples
- Employee: agenda + ganhos estimados
- Manager: status de tarefas + receivables/payables/net

### Schedule

- Lista em cards por dia/semana/mês
- Estados visíveis: pending/in-progress/done/canceled
- Ações contextuais rápidas (editar, cancelar, check-in/out)

### Clients/Employees

- Lista em cards com avatar, telefone e status financeiro
- Integração opcional com contatos iOS
- Formulários com botão principal fixo no rodapé

### Finance

- Separação clara entre invoice/payroll
- Estados de invoice (open/disputed/superseded/paid)
- Preview e reenvio de recibos/despesas out-of-pocket

### Settings

- Idioma (en-US/es-ES), moeda (USD/EUR), canais de envio
- Janela de disputa D+N
- Log de conflitos e auditoria (quem/quando)

## 6. UI States (Required)

Para cada tela crítica, definir e implementar:

- Loading
- Empty
- Error (recoverable)
- Success feedback
- Offline indicator

## 7. Accessibility and i18n

- Dynamic Type em componentes principais
- Suporte VoiceOver em ações críticas
- Contraste mínimo adequado em textos/ícones
- Localização inicial: en-US e es-ES (fallback en-US)

## 8. Performance UX Constraints

- Navegação primária com resposta percebida < 200 ms em dispositivos-alvo
- Operações assíncronas com feedback imediato (spinner/skeleton/toast)
- Evitar bloqueio de fluxo por permissões opcionais (ex.: contatos)

## 9. Interaction Rules

- Toda ação destrutiva exige confirmação
- Fluxos longos devem permitir retomada (offline queue + draft state)
- Regras role-based aplicadas no front e validadas na camada de dados

## 10. Open UX Decisions (Need Closure)

1. Padrão visual final para auditoria/conflitos no Settings (lista simples vs timeline).
2. Padrão de confirmação pós-ação (toast vs banner persistente) por módulo.
3. Estratégia de onboarding inicial para explicar diferença entre perfis.

## 11. Traceability Hooks (UX -> Backlog)

- Story 1.5: seleção de perfil no primeiro acesso
- Story 2.3: auditoria básica no Settings
- Story 7.6: notificações + Siri
- Story 8.3: relatórios com export
- Story 8.4: preview/reenvio de recibos
- Story 6.2 -> Story 9.5: pricing model impactando line items
- Story 7.4 -> Story 10.1: check-in/out impactando payroll automático
