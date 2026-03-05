import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/clients/domain/client.dart';
import 'package:ag_home_organizer_flutter/features/clients/presentation/client_detail_page.dart';
import 'package:ag_home_organizer_flutter/features/clients/presentation/clients_page.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';

class _TestOfflineStore extends OfflineStore {
  _TestOfflineStore(this._state);

  final OfflineState _state;

  @override
  OfflineState build() => _state;
}

void main() {
  testWidgets('manager can create client with extended fields', (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Manager',
        role: UserRole.manager,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ClientsPage(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('clients_add_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('client_form_name')),
      'John Carter',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_phone')),
      '+1 555 111',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_whatsapp')),
      '+1 555 222',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_email')),
      'john@demo.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_address')),
      '101 Main Street',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_property')),
      'Apartment 12',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_preferred_schedule')),
      'Weekdays 8am',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_access_notes')),
      'Front desk key',
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('client_form_channel_whatsapp')),
    );
    await tester.tap(find.byKey(const ValueKey('client_form_channel_whatsapp')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('client_form_channel_sms')),
    );
    await tester.tap(find.byKey(const ValueKey('client_form_channel_sms')));
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(
              find.byKey(const ValueKey('client_form_channel_whatsapp')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
              find.byKey(const ValueKey('client_form_channel_sms')))
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('client_form_save_button')));
    await tester.pumpAndSettle();

    final added = container
        .read(offlineStoreProvider)
        .clients
        .firstWhere((client) => client.name == 'John Carter');

    expect(added.phone, '+1 555 111');
    expect(added.whatsappPhone, '+1 555 222');
    expect(added.email, 'john@demo.com');
    expect(added.address, '101 Main Street');
    expect(added.propertyDetails, 'Apartment 12');
    expect(added.preferredSchedule, 'Weekdays 8am');
    expect(added.accessNotes, 'Front desk key');
    expect(added.preferredDeliveryChannels, contains(DeliveryChannel.email));
    expect(added.preferredDeliveryChannels, contains(DeliveryChannel.whatsapp));
    expect(added.preferredDeliveryChannels, contains(DeliveryChannel.sms));
  });

  testWidgets('client card shows email when phone and whatsapp are empty',
      (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Manager',
        role: UserRole.manager,
      ),
      clients: const [
        Client(
          id: 'client-1',
          name: 'Email Only',
          email: 'email-only@demo.com',
          address: 'A street',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
        ],
        child: const MaterialApp(
          home: ClientsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('email-only@demo.com'), findsOneWidget);
  });

  testWidgets('manager can edit client extended fields', (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Manager',
        role: UserRole.manager,
      ),
      clients: const [
        Client(
          id: 'client-edit',
          name: 'Original Name',
          phone: '+1 111',
          email: 'old@demo.com',
          preferredDeliveryChannels: [DeliveryChannel.email],
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ClientDetailPage(clientId: 'client-edit'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('client_form_name')),
      'Updated Name',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_property')),
      'Tower B',
    );
    await tester.enterText(
      find.byKey(const ValueKey('client_form_access_notes')),
      'Call reception',
    );

    await tester.tap(find.byKey(const ValueKey('client_form_save_button')));
    await tester.pumpAndSettle();

    final updated = container
        .read(offlineStoreProvider)
        .clients
        .firstWhere((client) => client.id == 'client-edit');

    expect(updated.name, 'Updated Name');
    expect(updated.propertyDetails, 'Tower B');
    expect(updated.accessNotes, 'Call reception');
  });

  testWidgets('employee cannot access client creation from clients page',
      (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Employee',
        role: UserRole.employee,
      ),
      clients: const [
        Client(
          id: 'client-1',
          name: 'Read Only Client',
          address: '123 Main',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
        ],
        child: const MaterialApp(
          home: ClientsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clients_add_button')), findsNothing);
  });

  testWidgets('employee cannot access edit delete or create in client detail',
      (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Employee',
        role: UserRole.employee,
      ),
      clients: const [
        Client(
          id: 'client-2',
          name: 'Detail Client',
          address: '456 Main',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
        ],
        child: const MaterialApp(
          home: ClientDetailPage(clientId: 'client-2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('client_detail_edit_button')), findsNothing);
    expect(find.byKey(const ValueKey('client_detail_delete_button')), findsNothing);
    expect(
        find.byKey(const ValueKey('client_detail_create_service_button')),
        findsNothing);
  });
}
