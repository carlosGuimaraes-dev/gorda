# AG Home Organizer International (gorda)

Aplicativo iOS de gestão de serviços residenciais, agenda e finanças, criado para uso interno da Gorda e sua equipe. O app permite coordenar serviços, clientes, funcionários e fluxo financeiro em múltiplas moedas, com operação offline e sincronização futura.

## Visão Geral

- Plataforma: iOS (Swift / SwiftUI / Core Data).
- Perfis: **Employee** (funcionário) e **Manager** (gestor), com dashboards e permissões diferentes.
- Domínio: serviços residenciais (limpeza, compras, manutenção, lavanderia etc.).
- Idiomas: **Inglês (en-US)** e **Espanhol (es-ES)**; PT‑BR poderá ser oferecido em uma versão futura.
- Moedas: **USD** e **EUR** (sem BRL na versão inicial).

## Funcionalidades principais

- **Autenticação & Splash**
  - Splash screen da AG Home Organizer International.
  - Login em SwiftUI com tema azul moderno e sessão persistida em Keychain.

- **Agenda & Serviços**
  - Agenda diária/mensal com calendário destacando dias com serviços.
  - Cadastro e edição de serviços com horário, status, notas e tipo de serviço.
  - Tipos de serviço padrão (standard cleaning, groceries shopping, lightbulb replacement, rug purchase, laundry) com preços base em USD/EUR.
  - Check-in / check-out por tarefa para cálculo de horas efetivamente trabalhadas.

- **Clientes & Funcionários**
  - Cadastro de clientes com telefone (DDI), e-mail, endereço, detalhes do imóvel e notas de acesso.
  - Cadastro de funcionários com perfil, time, telefone (DDI), valor/hora e observações de remuneração/documentos.
  - Integração com **Contatos** do iOS:
    - Importar dados (nome/telefone) de um contato para cliente/funcionário.
    - Exibir foto/avatar a partir dos Contatos quando houver correspondência.
  - Listas em formato de card com avatar, telefone e indicador visual de pendências financeiras.

- **Dashboard**
  - **Employee**:
    - Workload do período (tarefas agendadas, em andamento, concluídas).
    - Horas trabalhadas (via check-in/out) e ganhos estimados no período.
  - **Manager**:
    - Visão por equipe (tarefas totais/concluídas).
    - Gráficos com **Charts** mostrando tarefas por status e comparativo Recebíveis x Pagáveis.

- **Financeiro**
  - Contas a receber / pagar com status (pendente/pago), método (Pix, cartão, dinheiro) e moeda global (USD/EUR).
  - **End of month**:
    - Geração de **invoices por cliente** (somando serviços do período) com criação automática de `FinanceEntry` do tipo receivable.
    - Geração de **payroll** por funcionário (horas x valor/hora) com criação automática de `FinanceEntry` do tipo payable.
  - **Despesas extras out-of-pocket**:
    - Lançamento de despesas pagas do próprio bolso pela manager, vinculadas a um cliente.
    - Captura de foto do recibo diretamente da tela de nova despesa.
    - Armazenamento do recibo no `FinanceEntry` e abertura automática do share sheet (Mail, Mensagens, WhatsApp, etc.) para envio imediato ao cliente.

- **Offline & Sincronização**
  - Armazenamento local em **Core Data/SQLite** via `OfflineStore`.
  - Fila de mudanças pendentes; conflitos registrados em log com prioridade local.
  - Preparado para futura integração com backend para sincronização real.

- **Notificações & Siri**
  - Preferências de notificação por cliente/equipe.
  - Notificações locais para algumas ações rápidas.
  - Doação de `NSUserActivity` para criar atalhos Siri de criação de serviço.

## Arquitetura e Organização

- Código iOS principal em `ios/AppGestaoServicos`:
  - `AppGestaoServicosApp.swift` – ponto de entrada (`@main`) com injeção de `OfflineStore`.
  - `Models.swift` – modelos de domínio (`Client`, `Employee`, `ServiceType`, `ServiceTask`, `FinanceEntry`, `UserSession`).
  - `Persistence.swift` – modelo Core Data construído via código (`NSManagedObjectModel`).
  - `OfflineStore.swift` – camada de dados/offline + fila de sincronização.
  - `Views.swift` – telas principais (Login, Home/TabView, Dashboard, Agenda, Clientes, Financeiro, Settings, Service Detail, formulários).
  - `EmployeesView.swift` – lista e formulário de funcionários.
  - `KeychainHelper.swift` – utilitário simples para persistência de `UserSession`.
  - `Theme.swift` – paleta, radius e estilos de cor (AppTheme).
  - `AgendaCalendar.swift` – wrapper de `UICalendarView` para os destaques de agenda.
  - `ContactAvatar.swift` – carregamento de avatar a partir de Contatos.
  - `ActivityView.swift` – share sheet e image picker para recibos.

- Documentação:
  - `BACKLOG.md` – backlog etiquetado (✅ / ⏳) com features concluídas e pendentes.
  - `DATA_MODEL.md` – visão do modelo de dados.
  - `prd/ios-servicos-prd.md` – PRD funcional do app iOS.
  - `docs/architecture-frontend.md` – arquitetura do app iOS.
  - `docs/architecture-backend.md` – arquitetura do backend (planejada).
  - `AGENTS.md` – instruções para agentes/IA sobre padrões do projeto.

## Ambiente de desenvolvimento

- **Xcode**: 16 ou superior (desenvolvimento atual em Xcode 26.1.1).
- **iOS alvo**: 16+.
- **Dependências externas**: apenas frameworks Apple (SwiftUI, Charts, Contacts, CoreData, UIKit bridges).

### Como rodar

1. Clone o repositório:
   ```bash
   git clone https://github.com/carlosGuimaraes-dev/gorda.git
   cd gorda
   ```
2. No Xcode, crie um novo projeto iOS App (SwiftUI + Core Data) e, na estrutura do projeto, **adicione os arquivos existentes** de `ios/AppGestaoServicos` sem copiar para outro local (ou reproduza a configuração do projeto AG usada pelo autor).  
3. Configure o esquema para usar um simulador iOS 16+ ou um iPhone físico (com perfil de desenvolvedor).  
4. Compile e rode: a Splash AG aparece, seguida pelo login e pelas abas (Dashboard, Schedule, Clients, Finance, Settings).

> Observação: para testar integrações com **Contatos**, **Câmera** e **Siri**, é recomendável usar um dispositivo físico com permissões concedidas.

## Roadmap (resumo)

- Tela dedicada de Invoices e Payroll com CRUD completo e histórico.
- Disputa iniciada pelo cliente (email/texto ou botão no PDF) com janela D+N configurável.
- Configuração de canais preferenciais (e-mail/WhatsApp/iMessage) por cliente.
- Backend para sincronização real e multi-dispositivo.

## Licença

Projeto privado para uso interno da Gorda / AG Home Organizer International. Direitos reservados ao autor.
