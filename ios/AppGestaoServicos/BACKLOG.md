# Backlog etiquetado (SwiftUI)

- ✅ Login e sessão local com splash minimalista
- ✅ Agenda diária com detalhe editável (status, horários, notas, notificações rápidas)
- ✅ Cadastro de clientes com telefone, e-mail, imóvel, notas de acesso e horário preferido
- ✅ Financeiro com status pago/pendente e método (Pix/Cartão/Dinheiro)
- ✅ Inclusão de novos serviços a partir da Agenda (formulário com cliente/funcionário, horários, status, notificações)
- ✅ Cadastro de novos lançamentos financeiros (título, valor, tipo, vencimento, método)
- ✅ Visão mensal da agenda e filtros por equipe
- ✅ Tela de detalhe do cliente com histórico de serviços e botão "Criar serviço"
- ✅ Fila de sincronização offline/online com resolução de conflitos
- ✅ Integração de notificações locais/push e preferências de notificação
- ✅ Revisão de textos/labels para remover dependências de PT-BR e preparar tradução futura opcional para Português do Brasil
- ✅ Dashboard inicial após login, diferenciado por perfil (Employee/Manager), com resumo de agenda e indicadores principais
- ✅ Migração do armazenamento local (JSON) para Core Data ou SQLite com suporte offline robusto
- ✅ Modelagem de remuneração por funcionário (valor/hora em USD/EUR e outros recebíveis)
- ✅ Cadastro de funcionários com foto, documentos e informações de remuneração
- ✅ Modelagem de tipos de serviço com preço em USD/EUR e vínculo automático a lançamentos financeiros por cliente/funcionário
- ✅ Menu hamburger com atalhos para Dashboard, Schedule, Clients, Services, Employees, Finance e Settings
- ✅ Catálogo de serviços com lista/detalhe e CRUD básico (criar, editar, apagar quando não está em uso)
- ✅ Diretório de funcionários com detalhe e edição dedicada (fora do fluxo de Finance)
- ✅ Gestão de equipes (visualizar times, atribuir/remover funcionários, criação de novos times)
- ✅ Menu em sheet (Quick Actions) acionado pelo botão hambúrguer em todas as telas principais para evitar sobreposições
- ✅ Check-in/Check-out em tarefas para calcular horas trabalhadas e ganhos do funcionário
- ✅ Suporte a múltiplas moedas (USD e EUR) no módulo financeiro, sem exibição em BRL
- ✅ Internacionalização da interface para Inglês Americano (en-US) e Espanhol da Espanha (es-ES)
- ✅ Armazenamento seguro de credenciais no Keychain e comunicação criptografada
- ✅ Ajustes de acessibilidade (Dynamic Type, VoiceOver e contraste) nas principais telas
- 🟡 Integração com Siri para criação de serviços (Siri Suggestions ativas; comando de voz completo ainda pendente)
- ✅ Splash Screen da AG Home Organizer International antes do login
- ✅ Redesign completo do login, dashboard, agenda, clientes, financeiro e configurações com cards e tema azul
- ✅ Cards de clientes e funcionários com avatar, telefone e indicador visual de pendências financeiras
- ✅ Integração com Contatos do iOS para exibir foto de cliente/funcionário quando disponível
- ✅ Importação de dados básicos de funcionários a partir dos Contatos (nome e telefone)
- ✅ Campos de telefone de cliente e funcionário com seletor de DDI por bandeira (CountryCodePicker)
- ✅ Dashboard de manager com gráficos (Charts) para tarefas por status e visão comparativa de Recebíveis x Pagáveis
- ✅ Catálogo de tipos de serviço padrão (limpeza, groceries, troca de lâmpada, compra de tapete, lavanderia) com preços base em ServiceType
- ✅ Geração de invoices e folha de pagamento a partir das tasks (end of month) com criação automática de contas a receber/pagar
- ✅ Geração de invoices agregados por cliente no período selecionado (1 invoice por cliente), com PDF (QuickLook + share) contendo line items das tasks do período e instruções de pagamento
- ✅ Cadastro de despesas extras com opção de despesa "out-of-pocket" para o manager, incluindo captura de foto do recibo e envio imediato via share sheet
- ✅ Agenda com calendário destacando dias que possuem serviços agendados
- ✅ FinanceEntry e ServiceTask persistidos com IDs estáveis de cliente/funcionário + backfill automático
- ✅ Financeiro com payroll-only para Employee e invoices geradas separadas por moeda
- ✅ Preferências do app no Settings (manager escolhe idioma e moeda padrão global)
- ✅ Payroll detalhado (horas, dias, bônus, descontos, impostos, reembolsos e net pay) com CRUD por funcionário no Manager

## Pendentes / Próximas entregas

- ✅ Perfil da empresa (logo + dados fiscais por país) usado no cabeçalho das invoices
- ✅ Tipos de serviço com modelo de preço por tarefa ou por hora (pricing model)
- ✅ Check-in/out com foto obrigatória via câmera; botão de check-out só após check-in
- ✅ Invoices com line items por task (tipo, descrição, qtd, valor unitário, total) e qty em horas quando aplicável
- ✅ Tela dedicada de "Invoices" (lista de FinanceEntry.kind == invoiceClient) com CRUD completo: editar título/valor/vencimento/método, marcar como contestado e reemitir/enviar novamente
- ✅ CRUD semelhante para folhas de pagamento (FinanceEntry.kind == payrollEmployee), com edição antes da confirmação do pagamento
- ✅ Fluxo de contestacao de faturas pelo cliente: iniciar disputa via e-mail/texto ou botao no PDF, registrar motivo e respeitar janela D+N configuravel
- ✅ Visualização dos recibos anexados às despesas (preview da imagem a partir de FinanceEntry.receiptData) e possibilidade de reenviar o comprovante
- ✅ Canais de envio definidos pelo Manager (WhatsApp/Text/Email) + telefone WhatsApp opcional por cliente, usados na emissão/reenvio de invoices

## Decision Log (2025-12-29)

- MVP inclui Employees, Service Types e Teams (além de Login/Dashboard/Schedule/Clients/Finance/Settings).
- Offline local-first com fila local e pontos de extensão para sync futuro.
- Conflitos de sync: merge com prioridade local + log de conflito.
- Invoices: geração manual, com re-geração parcial por período.
- Payroll: permitido manualmente sem check-in/out, com confirmação do Manager.
- Task cancelada mantém histórico e não entra nos cálculos.
- Disputa de invoice pode ocorrer a qualquer momento e eh iniciada pelo cliente; Manager pode editar apos disputa e define janela pos-vencimento (D+N dias).
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

## Roadmap (Now)

- ✅ Localization en-US/es-ES: substituir textos hardcoded por Localizable.strings.
- ✅ Segurança local: criptografar campos sensíveis (cliente/funcionário/finanças) com chave no Keychain.
- ✅ Sync stub: adicionar log de conflito local (estrutura + UI simples em Settings).
- ✅ Regras financeiras: disputa de invoice a qualquer momento, com janela pós-vencimento configurável (D+N) e payroll manual sem check-in/out (com confirmação do Manager).
- ✅ Revisar cancelamento: garantir exclusão de cálculos e manter histórico.

## Roadmap (Next)

- ✅ Relatórios financeiros: resumo mensal/semanal e intervalo custom por cliente/funcionário com export simples.
- Sync real com backend (API) e regras de reconciliação.
- ✅ Auditoria básica de alterações (quem/quando) para tarefas e finanças.

## Roadmap (Later)

- PT-BR.
- Integração com pagamentos/boletos.
- Modo multi-empresa (multi-tenant) com troca rápida de contexto.

## Backlog Executável (Épicos + Histórias + ACs)

Legenda: ✅ implementado · 🟡 parcial · ❌ pendente

### EPIC 1 — Sessão, Perfis e Settings
- ✅ **Story 1.1**: Como Manager, quero definir idioma (en-US/es-ES) e moeda global para o app.  
  **AC**: Given o usuário é Manager e abre Settings; When altera idioma e moeda global; Then o locale do app é atualizado, a moeda padrão passa a valer para novos registros e a configuração fica persistida e visível no Settings.
- ✅ **Story 1.2**: Como Manager, quero definir janela de disputa pós‑vencimento (D+N dias).  
  **AC**: campo numérico em Settings; disputas após o vencimento só até D+N; valor 0 significa apenas até o vencimento.
- ✅ **Story 1.3**: Como usuário, quero manter sessão local segura.  
  **AC**: Given login válido; When sessão é criada; Then token/sessão são armazenados no Keychain; Given logout; When usuário encerra sessão; Then credenciais locais são removidas e o app retorna ao estado não autenticado.
- ✅ **Story 1.4**: Como Manager, quero cadastrar o perfil da empresa (logo + dados fiscais por país) para usar nas invoices.  
  **AC**: um perfil por conta; campos comuns (nome/endereço/contato) + ID fiscal variável (NIF/VAT vs EIN/SSN); logo opcional.
- ✅ **Story 1.5**: Como usuário, quero escolher meu perfil (Employee/Manager) no primeiro acesso.  
  **AC**: Given primeiro login sem perfil definido; When o usuário escolhe Employee ou Manager; Then o perfil é salvo e as telas passam a respeitar o papel escolhido no app inteiro.

### EPIC 2 — Offline, Sync e Conflitos
- ✅ **Story 2.1**: Como usuário, quero operar offline e sincronizar depois.  
  **AC**: fila local registra mudanças; botão “Force sync” mantém comportamento atual.
- ✅ **Story 2.2**: Como Manager, quero ver conflitos em um log simples.  
  **AC**: log acessível em Settings; badge ao abrir app se houver conflitos; cada item mostra entidade, data e ação.
- ✅ **Story 2.3**: Como Manager, quero ver auditoria básica (quem/quando) em tarefas e finanças no Settings.  
  **AC**: Given uma alteração em task ou finance; When o usuário abre a auditoria; Then cada item mostra entidade, ação, autor e timestamp, com ordenação por data mais recente.

### EPIC 3 — Segurança Local
- ✅ **Story 3.1**: Como Manager, quero criptografia local de dados sensíveis.  
  **AC**: criptografar contatos, endereços, notas, documentos/recibos; chave guardada no Keychain.

### EPIC 4 — Clients
- ✅ **Story 4.1**: Como Manager, quero CRUD completo de clientes com telefone e canais preferidos.  
  **AC**: criar, editar, apagar; validação de campos mínimos.
- ✅ **Story 4.2**: Como Manager, quero importar dados básicos de Contatos.  
  **AC**: Given o Manager inicia criação/edição de cliente; When escolhe importar de Contatos; Then nome e telefone são preenchidos automaticamente; Given o usuário não concede permissão ou cancela; When retorna ao formulário; Then o cadastro manual continua disponível sem bloqueio.

### EPIC 5 — Employees & Teams
- ✅ **Story 5.1**: Como Manager, quero CRUD de funcionários com remuneração e documentos.  
  **AC**: taxa/hora, moeda global aplicada, campos opcionais.
- ✅ **Story 5.2**: Como Manager, quero gerenciar times e mover funcionários.  
  **AC**: criar times, mover membros, remover time sem apagar funcionários.

### EPIC 6 — Service Types
- ✅ **Story 6.1**: Como Manager, quero CRUD de tipos de serviço com preço base.  
  **AC**: moeda global aplicada; não permitir excluir se houver tasks vinculadas.
- ✅ **Story 6.2**: Como Manager, quero definir se o preço é por tarefa ou por hora.  
  **AC**: Given criação/edição de ServiceType; When o Manager seleciona pricing model (por tarefa ou por hora); Then o preço base é interpretado conforme o modelo e exibido no catálogo com o rótulo correto.

### EPIC 7 — Schedule / Tasks
- ✅ **Story 7.1**: Como Employee, quero ver apenas minhas tasks.  
  **AC**: filtro por empregado logado; status visíveis.
- ✅ **Story 7.2**: Como Manager, quero criar/editar tasks com cliente e serviço.  
  **AC**: validação de cliente/funcionário; horário e status persistidos.
- ✅ **Story 7.3**: Como Manager, quero cancelar tasks sem perder histórico.  
  **AC**: status “canceled”; não entra em cálculos financeiros.
- ✅ **Story 7.4**: Como Employee, quero registrar check‑in/out.  
  **AC**: Given task atribuída ao Employee; When registra check-in e check-out; Then os timestamps são salvos na task e ficam disponíveis para cálculo de horas no payroll automático.
- ✅ **Story 7.5**: Como Employee, quero check‑in/out com foto obrigatória via câmera.  
  **AC**: sem upload da galeria; foto é capturada no momento; botão de check‑out só aparece após check‑in.
- 🟡 **Story 7.6**: Como usuário, quero receber notificações de agenda e poder criar serviço por Siri.  
  **AC**: Given uma task criada/alterada/cancelada; When o evento ocorre; Then o app agenda notificação local e, quando disponível, dispara push; Given Siri Suggestions habilitado; When uma task é criada; Then o app doa atalho de criação de serviço para sugestões da Siri; Given comando de voz completo via intent dedicado; When o usuário solicitar criação de serviço por voz; Then o fluxo deve criar serviço com dados mínimos e confirmar agendamento (pendente).

### EPIC 8 — Finance Base
- ✅ **Story 8.1**: Como Manager, quero lançamentos financeiros manuais (payable/receivable).  
  **AC**: CRUD completo; moeda global aplicada; método opcional.
- ✅ **Story 8.2**: Como Employee, quero ver apenas payroll no Finance.  
  **AC**: listas ocultam receivables; mostra só payroll do próprio usuário.
- ✅ **Story 8.3**: Como Manager, quero relatórios financeiros por período com export (CSV/PDF).  
  **AC**: Given filtros por período/cliente/funcionário; When o Manager gera relatório; Then o resumo semanal/mensal/custom é exibido e pode ser exportado em CSV/PDF.
- ✅ **Story 8.4**: Como Manager, quero visualizar e reenviar recibos de despesas out-of-pocket.  
  **AC**: Given uma despesa com receiptData; When o usuário abre o detalhe; Then o recibo é exibido em preview e pode ser reenviado por share sheet/canal configurado.

### EPIC 9 — Invoices
- ✅ **Story 9.1**: Como Manager, quero gerar invoices por cliente e período.  
  **AC**: separa por moeda; permite re‑gerar parcial por período.
- ✅ **Story 9.2**: Como Manager, quero editar invoice mesmo após disputa.  
  **AC**: edição permitida; disputa registrada com motivo.
- ✅ **Story 9.3**: Como Cliente, quero disputar invoice apos vencimento conforme D+N.  
  **AC**: disputa iniciada via e-mail/texto ou botao no PDF; permitida ate D+N; bloqueio apos prazo com mensagem clara.
- ✅ **Story 9.4**: Como Manager, quero re‑gerar invoice e marcar anterior como “superseded”.  
  **AC**: invoice anterior permanece para histórico; nova invoice criada.
- ✅ **Story 9.5**: Como Manager, quero invoices com line items detalhados por task.  
  **AC**: Given geração de invoice com tasks no período; When o documento é criado; Then cada line item exibe tipo, descrição, quantidade, valor unitário e total; Given o ServiceType é por hora; When há check-in/out válidos; Then qty usa horas trabalhadas; Given o ServiceType é por tarefa; When item é calculado; Then qty = 1.

### EPIC 10 — Payroll
- ✅ **Story 10.1**: Como Manager, quero gerar payroll automático com check‑in/out.  
  **AC**: Given período e funcionário selecionados com tasks fechadas; When o Manager gera payroll automático; Then horas são calculadas a partir de check-in/out, valor é calculado pela taxa aplicável e a moeda global é respeitada.
- ✅ **Story 10.2**: Como Manager, quero registrar payroll manual com horas informadas.  
  **AC**: Given criação de payroll manual; When o Manager informa horas/valores e confirma explicitamente; Then o lançamento é salvo com histórico de criação/edição e permanece auditável.

### EPIC 11 — Dashboard & KPIs
- ✅ **Story 11.1**: Como Manager, quero KPIs de cashflow e payroll estimado.  
  **AC**: cards com Receivables/Payables/Net; gráfico simples.
- ✅ **Story 11.2**: Como Employee, quero visão de tasks e ganhos estimados.  
  **AC**: baseado em check‑in/out; somente do usuário logado.

### EPIC 12 — Localização
- ✅ **Story 12.1**: Como Manager, quero app totalmente traduzido em en-US/es-ES.  
  **AC**: todas telas principais com strings localizadas; fallback para en-US.

### Dependências explícitas (ordem de execução)

- Story 1.5 antecede fluxos role-based de 7.1, 8.2 e 11.2.
- Story 6.2 antecede Story 9.5 (line items por hora vs por tarefa).
- Story 7.4 antecede Story 10.1 (payroll automático por check-in/out).
- Story 7.6 depende de 7.2 (eventos de agenda) e 1.5 (contexto de perfil).
