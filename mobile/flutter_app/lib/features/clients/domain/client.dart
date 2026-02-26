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
}
