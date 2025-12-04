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
- **Cadastro de Clientes e Imóveis**: dados pessoais, contatos, endereços e detalhes do imóvel administrado.
- **Cadastro de Funcionários**: perfil com foto, documentos e informações de remuneração.
- **Agendamento e Agenda**: CRUD de serviços; cada funcionário visualiza apenas sua agenda e tarefas da equipe; visões diária e mensal.
- **Modo Offline**: uso completo sem conexão; sincronização automática ao voltar online com resolução de conflitos prioritária para dados mais recentes do servidor quando houver conflito não resolvido localmente.
- **Notificações e Siri**: comandos de voz para agendar; push/local notifications para chegadas, cancelamentos e alterações.
- **Contas a Pagar e Receber**: lançamento e acompanhamento de recebimentos e pagamentos.
- **Autenticação**: Splash Screen minimalista e login seguro.

## Requisitos Não Funcionais
- Plataforma: iOS (Swift, UIKit/SwiftUI conforme padrão do projeto).
- Armazenamento local: Core Data ou SQLite para suporte offline; filas de sincronização para eventos pendentes.
- Segurança: armazenamento seguro de credenciais (Keychain) e comunicação criptografada.
- Performance: respostas em menos de 200 ms para navegação principal em dispositivos-alvo recentes.
- Acessibilidade: suporte a Dynamic Type, VoiceOver e contrastes adequados.

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
