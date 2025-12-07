# PRD - App iOS de Gestão de Serviços Residenciais

## Visão Geral
Aplicativo iOS em Swift para administrar serviços domésticos, centralizando gestão de clientes, imóveis, funcionários, agenda e finanças, com operação offline e sincronização posterior.

## Objetivos
- Simplificar o cadastro e consulta de clientes, imóveis e equipes.
- Garantir visibilidade individual de agendas por funcionário/equipe.
- Permitir operação offline com sincronização confiável.
- Notificar clientes e funcionários sobre eventos relevantes.
- Integrar controle financeiro básico (contas a pagar/receber).

## Público-Alvo
- Administradoras de serviços residenciais e suas equipes operacionais.

## Funcionalidades
- **Cadastro de Clientes e Imóveis**: dados pessoais, telefone (com DDI), e-mail, endereços e detalhes do imóvel administrado.
- **Cadastro de Funcionários**: perfil com foto (a partir dos Contatos do iOS quando disponível), documentos, telefone (com DDI) e informações de remuneração.
- **Perfis de Usuário (Employee/Manager)**: o usuário escolhe seu perfil no primeiro acesso; toda a experiência (dashboard, agenda, financeiro) é filtrada de acordo com o papel.
- **Agendamento e Agenda**: CRUD de serviços; cada funcionário visualiza apenas sua agenda e tarefas da equipe; visões diária, semanal e mensal, com cards de tarefas e filtro por equipe.
- **Modo Offline**: uso completo sem conexão; sincronização automática ao voltar online com resolução de conflitos prioritária para dados mais recentes do servidor quando houver conflito não resolvido localmente.
- **Notificações e Siri**: comandos de voz para agendar; push/local notifications para chegadas, cancelamentos e alterações.
- **Contas a Pagar e Receber**: lançamento e acompanhamento de recebimentos e pagamentos em **USD** e **EUR** (sem suporte a BRL na primeira versão), com vínculo automático entre serviços, clientes e funcionários quando houver preço base de serviço.
- **Dashboard** (cards + gráficos):
  - Para funcionários (Employee): visão diária/semanal/mensal da agenda, serviços concluídos no período e valor estimado a receber apenas para tasks com check-in/check-out efetivos.
  - Para gestores (Manager): visão por equipe da realização das tarefas (cards por equipe + gráfico de tarefas por status) e cards financeiros com Contas a Pagar/Receber e fluxo de caixa, incluindo gráfico comparando Recebíveis x Pagáveis.
- **Autenticação e onboarding visual**: Splash Screen da AG Home Organizer International, seguida de login seguro em SwiftUI com tema azul moderno.
- **Integração com Contatos do iOS**:
  - Exibir avatar/foto de cliente e funcionário a partir dos Contatos, quando existir correspondência por nome/telefone.
  - Permitir importar dados básicos (nome, telefone) de um contato na criação/edição de funcionário e cliente.
- **Invoices e Payroll**:
  - Tela dedicada para invoices (recebíveis) e payroll (pagáveis) com CRUD, edição até D-1 do vencimento no caso de invoices, marcação de disputa com motivo e reenvio pelo canal preferido do cliente (email/WhatsApp/iMessage).
  - Despesas out-of-pocket com preview e reenvio de recibo (receiptData) para o cliente/gestor.

## Requisitos Não Funcionais
- Plataforma: iOS (Swift, UIKit/SwiftUI conforme padrão do projeto).
- Armazenamento local: Core Data ou SQLite para suporte offline; filas de sincronização para eventos pendentes.
- Segurança: armazenamento seguro de credenciais (Keychain) e comunicação criptografada.
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
