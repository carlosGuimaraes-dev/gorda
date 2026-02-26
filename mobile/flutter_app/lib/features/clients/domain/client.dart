enum DeliveryChannel { email, whatsapp, sms }

class Client {
  const Client({
    required this.id,
    required this.name,
    this.contact = '',
    this.address = '',
    this.propertyDetails = '',
    this.phone = '',
    this.whatsappPhone = '',
    this.email = '',
    this.accessNotes = '',
    this.preferredSchedule = '',
    this.preferredDeliveryChannels = const [DeliveryChannel.email],
  });

  final String id;
  final String name;
  final String contact;
  final String address;
  final String propertyDetails;
  final String phone;
  final String whatsappPhone;
  final String email;
  final String accessNotes;
  final String preferredSchedule;
  final List<DeliveryChannel> preferredDeliveryChannels;

  Client copyWith({
    String? id,
    String? name,
    String? contact,
    String? address,
    String? propertyDetails,
    String? phone,
    String? whatsappPhone,
    String? email,
    String? accessNotes,
    String? preferredSchedule,
    List<DeliveryChannel>? preferredDeliveryChannels,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      propertyDetails: propertyDetails ?? this.propertyDetails,
      phone: phone ?? this.phone,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      email: email ?? this.email,
      accessNotes: accessNotes ?? this.accessNotes,
      preferredSchedule: preferredSchedule ?? this.preferredSchedule,
      preferredDeliveryChannels:
          preferredDeliveryChannels ?? this.preferredDeliveryChannels,
    );
  }
}
