# PRD - App iOS de Gestão de Serviços Residenciais

## Visão Geral
Aplicativo iOS em Swift para administrar serviços domésticos, centralizando gestão de clientes, imóveis, funcionários, agenda e finanças, com operação offline e sincronização posterior.

## Objetivos
- Simplificar o cadastro e consulta de clientes, imóveis e equipes.
- Garantir visibilidade individual de agendas por funcionário/equipe.
- Permitir operação offline com sincronização confiável.
- Notificar clientes e funcionários sobre eventos relevantes.
- Integrar controle financeiro básico (contas a pagar/receber).

## Decisões (2025-12-29)
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
- Notificações reais (WhatsApp/SMS/Email) habilitadas na v1.
- Consistência: eventual.

## Público-Alvo
- Administradoras de serviços residenciais e suas equipes operacionais.

## Funcionalidades
- **Cadastro de Clientes e Imóveis**: dados pessoais, telefone (com DDI), WhatsApp opcional (pode ser diferente do telefone), e-mail, endereços e detalhes do imóvel administrado.
- **Cadastro de Funcionários**: perfil com foto (a partir dos Contatos do iOS quando disponível), documentos, telefone (com DDI) e informações de remuneração.
- **Gestão de Equipes e Catálogos**: menu lateral em sheet (hambúrguer) com atalhos para Dashboard/Agenda/Clients/Finance/Settings e catálogos de Services/Employees/Teams; criação de times, movimentação de funcionários entre times e gerenciamento de tipos de serviço (CRUD).
- **Perfis de Usuário (Employee/Manager)**: o usuário escolhe seu perfil no primeiro acesso; toda a experiência (dashboard, agenda, financeiro) é filtrada de acordo com o papel (Employee vê apenas payroll no Finance).
- **Preferências do App (Manager)**: idioma (en-US/es-ES), moeda padrão (USD/EUR) e canais de envio de invoice (WhatsApp/SMS/Email) são escolhidos na aba Settings e aplicados aos cadastros/fluxos.
- **Agendamento e Agenda**: CRUD de serviços; cada funcionário visualiza apenas sua agenda e tarefas da equipe; visões diária, semanal e mensal, com cards de tarefas e filtro por equipe. Cancelamentos mantêm histórico e não entram nos cálculos financeiros.
- **Modo Offline**: uso completo sem conexão; sincronização automática ao voltar online com resolução de conflitos priorizando dados locais e registrando conflitos quando houver divergências.
- **Sync/Conflitos**: local-first com fila local; quando houver backend, aplicar merge com prioridade local e registrar conflitos em log.
- **Notificações e Siri**: comandos de voz para agendar; push/local notifications para chegadas, cancelamentos e alterações.
- **Contas a Pagar e Receber**: lançamento e acompanhamento de recebimentos e pagamentos em **USD** e **EUR** (sem suporte a BRL na primeira versão), com vínculo automático entre serviços, clientes e funcionários quando houver preço base de serviço.
- **Relatórios financeiros**: resumo mensal/semanal e intervalo custom por cliente e funcionário, com export simples (CSV/PDF) para compartilhamento interno.
- **Dashboard** (cards + gráficos):
  - Para funcionários (Employee): visão diária/semanal/mensal da agenda, serviços concluídos no período e valor estimado a receber apenas para tasks com check-in/check-out efetivos.
  - Para gestores (Manager): visão por equipe da realização das tarefas (cards por equipe + gráfico de tarefas por status) e cards financeiros com Contas a Pagar/Receber e fluxo de caixa, incluindo gráfico comparando Recebíveis x Pagáveis.
- **Autenticação e onboarding visual**: Splash Screen da AG Home Organizer International, seguida de login seguro em SwiftUI com tema azul moderno.
- **Integração com Contatos do iOS**:
  - Exibir avatar/foto de cliente e funcionário a partir dos Contatos, quando existir correspondência por nome/telefone.
  - Permitir importar dados básicos (nome, telefone) de um contato na criação/edição de funcionário e cliente.
- **Invoices e Payroll**:
  - Tela dedicada para invoices (recebíveis) e payroll (pagáveis) com CRUD, edição permitida respeitando janela pós‑vencimento configurável (D+N), marcação de disputa com motivo e reenvio pelo canal definido pelo Manager (WhatsApp/SMS/Email), em ordem de prioridade.
  - Geração de invoices agregados por cliente dentro de um período, separados por moeda (um invoice por cliente por moeda), com PDF (QuickLook + share sheet) contendo line items das tasks do intervalo e instruções de pagamento; permitir re-geração parcial por período.
  - Payroll pode ser gerado manualmente sem check-in/out, com confirmação do Manager.
  - Disputa de invoice iniciada pelo cliente via e-mail/texto ou botao no PDF; permitida a qualquer momento (mantendo historico) e com ajustes permitidos pelo Manager; janela pos-vencimento e configuravel (D+N dias).
  - Despesas out-of-pocket com preview e reenvio de recibo (receiptData) para o cliente/gestor.
  - Auditoria básica: log de alterações em tarefas e finanças (quem/quando), visível no Settings.

## Requisitos Não Funcionais
- Plataforma: iOS (Swift, UIKit/SwiftUI conforme padrão do projeto).
- Armazenamento local: Core Data ou SQLite para suporte offline; filas de sincronização para eventos pendentes.
- Segurança: armazenamento seguro de credenciais (Keychain) e comunicação criptografada.
- Segurança local: criptografia de dados sensíveis em repouso (ex.: contatos e documentos).
- Performance: respostas em menos de 200 ms para navegação principal em dispositivos-alvo recentes.
- Acessibilidade: suporte a Dynamic Type, VoiceOver e contrastes adequados.
- Internacionalização: interface e conteúdo em **Inglês Americano (en-US)** e **Espanhol da Espanha (es-ES)**; sem suporte a Português do Brasil na primeira versão (tradução PT-BR avaliada como melhoria futura).

## Fluxos Principais
1. Login → sincronização inicial → acesso à home com resumo de agenda e notificações.
2. Cadastro de cliente/imóvel → associação a serviços → agendamento para funcionário/equipe.
3. Funcionário abre sua agenda (dia/mês) → visualiza tarefas atribuídas → registra status (em andamento, concluído, cancelado).
4. Operação offline → registros ficam em fila local → sincronização ao recuperar conexão.

## Métricas de Sucesso
- Tempo médio de criação de um serviço/agendamento < 1 min.
- >95% das ações críticas disponíveis offline.
- Taxa de falhas na sincronização < 2% por semana.
- Engajamento de notificações: >60% abertas em até 10 minutos.

## Riscos e Mitigações
- Conflitos de dados na sincronização: usar controle de versão/etags e regras de mesclagem previsíveis.
- Latência de notificações: fallback para notificações locais quando push indisponível.
- Privacidade de dados sensíveis: limitar escopos de dados em cache local e criptografar campos confidenciais quando aplicável.
