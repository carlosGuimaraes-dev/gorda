# Data Model - App Gestão de Serviços

Visão de alto nível das entidades principais, pensando em uma implementação com Core Data (SQLite por baixo).

## Nota de Migração Cross-Platform (Flutter)

- Foi criada uma base Flutter em `mobile/flutter_app` com espelhamento inicial das entidades de domínio:
  - `UserSession`, `Client`, `Employee`, `ServiceTask`, `FinanceEntry`, `PendingChange`.
- O `OfflineStore` no Flutter está em versão inicial (estado em memória + fila pendente + sync stub), alinhado ao comportamento atual de sync local-first do iOS.
- Próxima etapa: substituir estado em memória por persistência local (SQLite/Drift) mantendo contratos de entidade e reconciliação de fila.

## User / Session

- **User**
  - `id: UUID`
  - `name: String`
  - `email: String?`
  - `role: String` (`"employee"` ou `"manager"`)
  - Relacionamentos:
    - `employeeProfile: Employee?`

- **UserSession** (pode ser apenas em memória, mas pode ser persistida se necessário)
  - `token: String`
  - `user: User`
  - `createdAt: Date`

## Employee / Team

- **Team (hoje representado por uma string no Employee)**
  - `name: String`
  - Observação: a UI agrupa funcionários por `team` (String). Não há entidade Team separada neste momento; o formulário de times apenas atribui/edita esse campo nos funcionários.

- **Employee**
  - `id: UUID`
  - `name: String`
  - `roleTitle: String?` (ex.: Supervisor, Técnico)
  - `hourlyRate: Decimal` (valor da hora)
  - `currency: String` (`"USD"` ou `"EUR"`)
  - `extraEarningsDescription: String?` (outros recebíveis)
  - `team: String` (nome do time; pode ser vazio)
  - Relacionamentos:
    - `user: User?`
    - `tasks: [ServiceTask]`

## Client / Property

- **Client**
  - `id: UUID`
  - `name: String`
  - `contactName: String`
  - `phone: String`
  - `whatsappPhone: String` (opcional, pode ser diferente do telefone)
  - `email: String`
  - `accessNotes: String`
  - `preferredSchedule: String`
  - `preferredDeliveryChannels: [String]` (`"email"`, `"whatsapp"`, `"sms"`)
  - Relacionamentos:
    - `properties: [Property]`
    - `serviceTasks: [ServiceTask]`
    - `financeEntries: [FinanceEntry]`

- **Property**
  - `id: UUID`
  - `label: String` (ex.: "Apartamento 302")
  - `addressLine: String`
  - `details: String` (tipo, metragem, bloco)
  - Relacionamentos:
    - `client: Client`
    - `serviceTasks: [ServiceTask]`

## ServiceType / ServiceTask / Check-in

- **ServiceType**
  - `id: UUID`
  - `name: String`
  - `description: String?`
  - `basePrice: Decimal`
  - `currency: String` (`"USD"` ou `"EUR"`)
  - `pricingModel: String` (`"perTask"` ou `"perHour"`)
  - Relacionamentos:
    - `tasks: [ServiceTask]`

- **ServiceTask**
  - `id: UUID`
  - `title: String`
  - `date: Date`
  - `startTime: Date?`
  - `endTime: Date?`
  - `status: String` (`"scheduled"`, `"inProgress"`, `"completed"`, `"canceled"`)
  - `notes: String`
  - `checkInTime: Date?`
  - `checkOutTime: Date?`
  - `checkInPhotoData: Data?` (foto capturada via câmera no check-in)
  - `checkOutPhotoData: Data?` (foto capturada via câmera no check-out)
  - `clientId: UUID?` (persistido para vínculos offline consistentes)
  - Observação: na persistência local, tarefas guardam `employeeId`/`clientId` e nomes denormalizados para resiliência offline.
  - Relacionamentos:
    - `employee: Employee`
    - `client: Client`
    - `property: Property?`
    - `serviceType: ServiceType?`
    - `financeEntryClient: FinanceEntry?` (recebível do cliente)
    - `financeEntryEmployee: FinanceEntry?` (pagamento ao funcionário, se houver)

## Finance / Cash Flow

- **FinanceEntry**
  - `id: UUID`
  - `title: String`
  - `amount: Decimal`
  - `currency: String` (`"USD"` ou `"EUR"`)
  - `type: String` (`"payable"` ou `"receivable"`)
  - `dueDate: Date`
  - `status: String` (`"pending"` ou `"paid"`)
  - `method: String?` (`"pix"`, `"card"`, `"cash"` — ou equivalente internacional)
  - `clientId: UUID?`
  - `clientName: String?`
  - `employeeId: UUID?`
  - `employeeName: String?`
  - `kind: String` (`"general"`, `"invoiceClient"`, `"payrollEmployee"`, `"expenseOutOfPocket"`)
  - `isDisputed: Bool`
  - `disputeReason: String?`
  - `receiptData: Data?` (imagem de comprovante para despesas)
  - `supersededById: UUID?`
  - `supersedesId: UUID?`
  - `supersededAt: Date?`
  - `payrollPeriodStart: Date?`
  - `payrollPeriodEnd: Date?`
  - `payrollHoursWorked: Double`
  - `payrollDaysWorked: Int`
  - `payrollHourlyRate: Double`
  - `payrollBasePay: Double`
  - `payrollBonus: Double`
  - `payrollDeductions: Double`
  - `payrollTaxes: Double`
  - `payrollReimbursements: Double`
  - `payrollNetPay: Double`
  - `payrollNotes: String?`
  - `notes: String?`
  - Relacionamentos:
    - `client: Client?`
    - `employee: Employee?`
    - `serviceTask: ServiceTask?`
  - Observação: invoices são gerados agregando tasks por cliente dentro de um período e separados por moeda; line items exibem tipo/descrição/quantidade/unitário/total; para serviços `perHour`, quantidade usa horas de `checkInTime`/`checkOutTime`; para `perTask`, quantidade = 1.

## Offline / Sync / Notifications

- **CompanyProfile** (persistido dentro de `AppPreferences`)
  - `legalName: String`
  - `addressLine1: String`
  - `addressLine2: String`
  - `city: String`
  - `region: String`
  - `postalCode: String`
  - `countryName: String`
  - `contactEmail: String`
  - `contactPhone: String`
  - `website: String`
  - `taxCountry: String` (`"unitedStates"`, `"spain"`, `"portugal"`, `"other"`)
  - `taxIdentifier: String` (ex.: NIF/VAT ou EIN/SSN)
  - `logoData: Data?` (logo opcional para cabeçalho do PDF de invoice)

- **PendingChange**
  - `id: UUID`
  - `operation: String`
  - `entityId: UUID`
  - `timestamp: Date`

- **NotificationPreferences**
  - `enableClientNotifications: Bool`
  - `enableTeamNotifications: Bool`
  - `enablePush: Bool`
  - `enableSiri: Bool`

- **AppPreferences**
  - `language: String` (`"en-US"` ou `"es-ES"`)
  - `preferredCurrency: String` (`"USD"` ou `"EUR"`)
  - `disputeWindowDays: Int` (D+N após vencimento; `0` = até vencimento)
  - `enableWhatsApp: Bool`
  - `enableTextMessages: Bool`
  - `enableEmail: Bool`
  - `companyProfile: CompanyProfile?` (somente manager altera no Settings)
  - Observação: `preferredCurrency` é global e bloqueia a moeda usada em cadastros e lançamentos financeiros.

- **ConflictLogEntry**
  - `id: UUID`
  - `entity: String`
  - `field: String`
  - `summary: String`
  - `timestamp: Date`
  - Observação: log local de conflitos de sync, exibido no Settings.

- **AuditLogEntry**
  - `id: UUID`
  - `entity: String`
  - `action: String`
  - `summary: String`
  - `actor: String`
  - `timestamp: Date`
  - Observação: log local de alterações (tarefas/finanças), exibido no Settings.

> Implementação Core Data: cada entidade acima pode virar uma `NSEntityDescription` em um modelo programático ou em um `.xcdatamodeld`. O app atual continuará usando o `OfflineStore` como fachada, mas por baixo os dados passam a ser persistidos em Core Data/SQLite ao invés de um JSON único.
