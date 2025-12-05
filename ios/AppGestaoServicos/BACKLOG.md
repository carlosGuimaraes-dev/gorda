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
- ✅ Check-in/Check-out em tarefas para calcular horas trabalhadas e ganhos do funcionário
- ✅ Suporte a múltiplas moedas (USD e EUR) no módulo financeiro, sem exibição em BRL
- ✅ Internacionalização da interface para Inglês Americano (en-US) e Espanhol da Espanha (es-ES)
- ✅ Armazenamento seguro de credenciais no Keychain e comunicação criptografada
- ✅ Ajustes de acessibilidade (Dynamic Type, VoiceOver e contraste) nas principais telas
- ✅ Integração com Siri para criação de serviços por comando de voz
- ✅ Splash Screen da AG Home Organizer International antes do login
- ✅ Redesign completo do login, dashboard, agenda, clientes, financeiro e configurações com cards e tema azul
- ✅ Cards de clientes e funcionários com avatar, telefone e indicador visual de pendências financeiras
- ✅ Integração com Contatos do iOS para exibir foto de cliente/funcionário quando disponível
- ✅ Importação de dados básicos de funcionários a partir dos Contatos (nome e telefone)
- ✅ Campos de telefone de cliente e funcionário com seletor de DDI por bandeira (CountryCodePicker)
- ✅ Dashboard de manager com gráficos (Charts) para tarefas por status e visão comparativa de Recebíveis x Pagáveis
- ✅ Catálogo de tipos de serviço padrão (limpeza, groceries, troca de lâmpada, compra de tapete, lavanderia) com preços base em ServiceType
- ✅ Geração de invoices e folha de pagamento a partir das tasks (end of month) com criação automática de contas a receber/pagar
- ✅ Cadastro de despesas extras com opção de despesa "out-of-pocket" para o manager, incluindo captura de foto do recibo e envio imediato via share sheet
- ✅ Agenda com calendário destacando dias que possuem serviços agendados

## Pendentes / Próximas entregas

- ⬜ Tela dedicada de "Invoices" (lista de FinanceEntry.kind == invoiceClient) com CRUD completo: editar título/valor/vencimento/método, marcar como contestado e reemitir/enviar novamente
- ⬜ CRUD semelhante para folhas de pagamento (FinanceEntry.kind == payrollEmployee), com edição antes da confirmação do pagamento
- ⬜ Fluxo de contestação de faturas pelo cliente: marcar invoice como `disputed`, registrar motivo e permitir ajustes até 1 dia antes do vencimento
- ⬜ Visualização dos recibos anexados às despesas (preview da imagem a partir de FinanceEntry.receiptData) e possibilidade de reenviar o comprovante
- ⬜ Configuração por cliente dos canais preferidos para envio (e-mail, WhatsApp, iMessage) e integração mais direta nesses canais na emissão da fatura
