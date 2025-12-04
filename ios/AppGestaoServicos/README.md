# App Gestao de Serviços (SwiftUI)

Pequeno protótipo em SwiftUI cobrindo login, agenda por funcionário, cadastro de clientes e visão financeira com suporte offline simplificado (JSON local). Abra a pasta `ios/AppGestaoServicos` no Xcode 15+ e rode em um simulador iOS 16+.

## Funcionalidades
- Login simples com persistência local de sessão.
- Agenda diária por funcionário com status, horário, criação de novos serviços e detalhe editável (notificações rápidas).
- Cadastro de clientes via formulário modal com telefone, e-mail, preferências de horário e notas de acesso.
- Visão financeira separando itens a pagar e receber, com status pendente/pago, método (Pix, cartão, dinheiro) e criação de novos lançamentos.
- Botão de sincronização que registra o horário do último sync (ponto de integração com backend).

Wireframes textuais e campos detalhados estão em [`Wireframes.md`](./Wireframes.md).
O backlog etiquetado por status está em [`BACKLOG.md`](./BACKLOG.md).

## Como testar
1. Abra `AppGestaoServicosApp.swift` no Xcode e rode no simulador.
2. Faça login com qualquer usuário/senha para abrir as abas.
3. Inclua novos clientes e veja-os listados.
4. Na Agenda, crie um novo serviço, escolhendo cliente/funcionário/horário/status, e valide que ele aparece na lista.
5. Toque em um serviço existente para editar status, horários e notificações rápidas.
6. Na aba Financeiro, cadastre um novo lançamento (a pagar ou a receber) e use o menu para marcar pago (Pix/Cartão/Dinheiro) ou voltar para pendente.
