# Wireframes textuais - App Gestão de Serviços (iOS)

## Tela de login
```
+----------------------------------+
|  Gestão de Serviços              |
|                                  |
|  [ Usuária..................... ]|
|  [ Senha....................... ]|
|  ( ) Lembrar sessão              |
|                                  |
|  [ Entrar ]                      |
|  Última sync: 12/03 09:45        |
+----------------------------------+
```
Campos: usuária, senha, checkbox lembrar sessão (opcional), link para recuperar senha (versão futura), label de última sincronização.

## Home com abas
```
[Agenda] [Clientes] [Financeiro] [Config]
```
Aba Agenda abre visão diária; Clientes lista cartões; Financeiro mostra saldos; Config concentra sessão, sync e preferências.

## Agenda - visão diária
```
Data: [ 15 Mar 2024  v]
--------------------------------------
09:00  Limpeza pós-evento   (Ana)
      Status: Agendado
      Cliente: Carla Lima
      Endereço: Rua das Flores, 123
      Notas: Levar materiais de piso vinílico
--------------------------------------
14:00  Inspeção pré-mudança (Bruno)
      Status: Em andamento
      Cliente: Joana Prado
      Endereço: Av. Central, 45 apt 81
      Notas: Checklist de paredes
```
Campos por tarefa: título do serviço, status, funcionário atribuído, cliente, endereço, janela de horário (início/fim), notas, botão de editar status.

### Ficha da tarefa (detalhe)
```
[Título do serviço]
[Cliente] [Imóvel/endereço]
[Funcionário/equipe]
[Data] [Hora início] [Hora fim]
[Status dropdown]
[Notas multiline]
[Botão: Marcar concluído] [Cancelar]
[Botão: Notificar cliente] [Notificar equipe]
```

## Agenda - criar/editar serviço
```
[Título]
[Cliente]
[Funcionário/equipe]
[Data] [Hora início] [Hora fim]
[Status (default: Agendado)]
[Notas multiline]
[Checkbox] Enviar notificação para cliente
[Checkbox] Notificar funcionário
[Salvar]
```

## Clientes
```
+ Cliente 1 -------------------------
  Nome, telefone, e-mail
  Endereço resumido
  Imóvel: apartamento, bloco, vaga
  Preferência de horário | Notas de acesso
  Botões: Ver detalhes | Criar serviço

+ Cliente 2 ...
```

### Ficha de cliente
Campos: nome, telefone, e-mail, endereço, detalhes do imóvel (tipo, bloco/apt, metragem), preferências de horário, notas de acesso (portaria, vaga), histórico rápido de serviços.

## Financeiro
```
A receber
- Limpeza pós-evento .......... R$ 350,00  (15/03) [Registrar recebimento]
- Manutenção jardim ........... R$ 220,00  (17/03)

A pagar
- Pagamento equipe A .......... R$ 1.200,00 (20/03) [Marcar pago/Pendente]
- Materiais de limpeza ........ R$ 180,00  (18/03)
```
Campos por lançamento: título, valor, tipo (a receber/a pagar), data de vencimento, status (pendente/pago), método (pix/cartão/dinheiro), observações.

## Configurações
Seções: dados da sessão (usuária, botão sair), sincronização manual (forçar sync, mostrar última sync), preferências de notificações (cliente/funcionário), idioma e acessibilidade (Dynamic Type).
