# Wireframes Finais v1 - Gorda (iPhone)

Baseado em: `_bmad-output/planning-artifacts/ux-design-specification.md`

- Plataforma: iPhone only (v1)
- Padrão de CTA: `PrimaryBottomCTA` no rodapé, acima da tab bar
- Padrões escolhidos: OBJ1=D, OBJ2=A, OBJ3=A, OBJ4=A

## Navegação Base (todas as telas principais)

```text
+----------------------------------+
| [Status iOS]                     |
| [Título da tela]                 |
|                                  |
| [Conteúdo principal]             |
|                                  |
| [ PrimaryBottomCTA ]             |
| [Home] [Agenda] [Finance] [Cfg]  |
+----------------------------------+
```

## Tela 0 - Splash (logo do business)

```text
+----------------------------------+
|                                  |
|               [AG]               |
|        AG Home Organizer         |
|        Service Management        |
|                                  |
|          [ Carregando... ]       |
+----------------------------------+
```

Notas:
- Tela de abertura antes do login.
- O bloco `[AG]` representa a logo temporária.
- Ao receber o arquivo oficial da marca, substituir por logo real.

## Tela 1 - Login + Papel

```text
+----------------------------------+
|  AG Home Organizer               |
|                                  |
|  [ Email....................... ]|
|  [ Senha....................... ]|
|                                  |
|  Perfil                          |
|  (•) Manager   ( ) Employee      |
|                                  |
|  [ Entrar ]                      |
+----------------------------------+
```

Notas:
- Papel impacta Home/Agenda/Finance imediatamente.
- Erro de login inline + resumo no topo ao enviar.

## Tela 2 - Manager Home (OBJ1 = D Split 50/50)

```text
+----------------------------------+
|  Fechamento Mensal - Jan/2026    |
|                                  |
|  + Pendências -----------------+ |
|  | Comprovantes sem vínculo: 3 | |
|  | Inconsistências: 1          | |
|  +-----------------------------+ |
|                                  |
|  + Resumo Financeiro ----------+ |
|  | Recebíveis:     $18,240     | |
|  | Pagáveis:       $7,910      | |
|  +-----------------------------+ |
|                                  |
|  [ Revisar prévia ]              |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Componentes:
- `FinanceSplitSummaryCard`
- `PrimaryBottomCTA`
- `SyncStatusPill` (topo, quando aplicável)

## Tela 3 - Fechamento em Passos (wizard)

```text
+----------------------------------+
|  Passo 2/4 - Pendências          |
|  [1] [2*] [3] [4]                |
|                                  |
|  Itens obrigatórios              |
|  - Comprovantes sem vínculo (3)  |
|  - Conflitos de valor (1)        |
|                                  |
|  [ Resolver e continuar ]        |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Notas:
- Fluxo longo sempre com progresso explícito.
- Erro crítico bloqueia avanço (padrão definido).

## Tela 3.1 - Agenda Mensal do Manager (PickDate / List)

```text
+----------------------------------+
|  Agenda Mensal - Manager         |
|  [ PickDate ] [ List ]           |
|                                  |
|  (modo PickDate ativo)           |
|  [Calendário mensal]             |
|  Dia selecionado: 15 Mar         |
|  Serviços no dia: 6              |
|                                  |
|  [ Abrir dia selecionado ]       |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Notas:
- O Manager pode alternar a visualização:
  - **PickDate:** escolhe um dia no calendário e abre os serviços daquele dia.
  - **List:** mostra serviços do período em lista contínua.
- Mantém CTA principal no bottom acima da tab bar.

## Tela 4 - Employee Agenda (OBJ2 = A Lista direta)

```text
+----------------------------------+
|  Agenda de hoje                  |
|                                  |
|  09:00  Smith House    [Check-in]|
|  11:30  Martin Apt      [Abrir]  |
|  15:00  Noah Condo      [Abrir]  |
|                                  |
|  Ganho estimado hoje: $320       |
|                                  |
|  [ Abrir próxima task ]          |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Componentes:
- `TaskDirectListCard`
- `PrimaryBottomCTA`

## Tela 5 - Task Detalhe (check-in/check-out)

```text
+----------------------------------+
|  Deep Clean - Smith House        |
|                                  |
|  Status: Em andamento            |
|  Início: 09:02                   |
|  Evidências: 2 anexos            |
|                                  |
|  [ Check-out ]                   |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Exceção:
- Check-out sem check-in abre `ExceptionReasonSheet` (justificativa obrigatória).

## Tela 6 - Comprovantes (OBJ3 = A Camera-first)

```text
+----------------------------------+
|  Comprovantes                    |
|  Fila offline: 6                 |
|                                  |
|  Sugestão cliente: Smith House   |
|  Sugestão task: Deep Clean       |
|                                  |
|  Últimos salvos locais           |
|  - Recibo #193                   |
|  - Recibo #194                   |
|                                  |
|  [ Escanear novo ]               |
|  [Home][Agenda][Capture][Cfg]    |
+----------------------------------+
```

Componentes:
- `EvidenceCaptureQuickPanel`
- `SyncStatusPill`
- `PrimaryBottomCTA`

## Tela 7 - Emissão (OBJ4 = A Resumo + Emitir)

```text
+----------------------------------+
|  Pronto para emissão             |
|                                  |
|  Invoices: 18                    |
|  Payroll:  7                     |
|  Total:    $26,150               |
|                                  |
|  Canal primário: WhatsApp        |
|  Fallback: Email                 |
|                                  |
|  [ Emitir agora ]                |
|  [Home][Agenda][Finance][Cfg]    |
+----------------------------------+
```

Componentes:
- `InvoiceEmitSummaryPanel`
- `PrimaryBottomCTA`

## Tela 8 - Clientes (busca topo + filtros em sheet)

```text
+----------------------------------+
|  Clientes                        |
|  [ 🔎 Buscar cliente... ] [Filtros]|
|                                  |
|  Smith House          (Ativo)    |
|  Martin Apt           (Ativo)    |
|  Noah Condo           (Inativo)  |
|                                  |
|  [ Aplicar filtros ]             |
|  [Home][Agenda][Clientes][Cfg]   |
+----------------------------------+
```

Sheet de filtros:
- Status (ativo/inativo)
- Equipe
- Período
- Ordenação

## Tela 9 - Empty State padrão

```text
+----------------------------------+
|  Comprovantes                    |
|                                  |
|  Nenhum comprovante no período   |
|  Comece escaneando o primeiro.   |
|                                  |
|  [ Escanear primeiro comprovante ]|
|  [Home][Agenda][Capture][Cfg]    |
+----------------------------------+
```

## Mapa rápido Tela -> Objetivo

- Tela 2 + 3 + 7: OBJ1 / OBJ4 (Manager financeiro)
- Tela 4 + 5: OBJ2 (Employee operação diária)
- Tela 6 + 9: OBJ3 (captura e confiabilidade offline)
- Tela 8: suporte transversal (cadastros e operação)

## Checklist de uso na implementação

- CTA principal sempre no bottom acima da tab bar
- 1 CTA primário por tela
- validação inline + resumo no topo no submit
- erro crítico bloqueia em fluxo financeiro
- feedback explícito: salvo local / pendente sync / sincronizado / erro
