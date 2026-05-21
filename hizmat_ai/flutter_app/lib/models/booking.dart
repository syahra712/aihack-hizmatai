enum BookingStatus { confirmed, pending, completed, cancelled, paid }

class Booking {
  final String id;
  final String providerName;
  final String serviceType;
  final String city;
  final DateTime dateTime;
  final int estimatedCost;
  final BookingStatus status;
  final String? providerPhone;
  final String? paidLast4;

  const Booking({
    required this.id,
    required this.providerName,
    required this.serviceType,
    required this.city,
    required this.dateTime,
    required this.estimatedCost,
    required this.status,
    this.providerPhone,
    this.paidLast4,
  });

  bool get isPaid => status == BookingStatus.paid;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isPayable => status == BookingStatus.confirmed || status == BookingStatus.pending;

  String get serviceLabel => {
    'electrician': 'Electrician',
    'plumber': 'Plumber',
    'cleaner': 'Cleaner',
    'cleaning': 'Cleaning',
    'ac_repair': 'AC Technician',
    'home_tutor': 'Home Tutor',
    'beautician': 'Beautician',
    'painter': 'Painter',
    'carpenter': 'Carpenter',
  }[serviceType] ?? serviceType;

  String get statusLabel => {
    BookingStatus.confirmed: 'Unpaid',
    BookingStatus.pending: 'Pending',
    BookingStatus.completed: 'Completed',
    BookingStatus.cancelled: 'Cancelled',
    BookingStatus.paid: 'Paid',
  }[status]!;

  Booking copyWith({BookingStatus? status, String? paidLast4}) => Booking(
    id: id,
    providerName: providerName,
    serviceType: serviceType,
    city: city,
    dateTime: dateTime,
    estimatedCost: estimatedCost,
    status: status ?? this.status,
    providerPhone: providerPhone,
    paidLast4: paidLast4 ?? this.paidLast4,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerName': providerName,
    'serviceType': serviceType,
    'city': city,
    'dateTime': dateTime.toIso8601String(),
    'estimatedCost': estimatedCost,
    'status': status.index,
    'providerPhone': providerPhone,
    'paidLast4': paidLast4,
  };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    providerName: j['providerName'] as String,
    serviceType: j['serviceType'] as String,
    city: j['city'] as String,
    dateTime: DateTime.parse(j['dateTime'] as String),
    estimatedCost: j['estimatedCost'] as int,
    status: BookingStatus.values[(j['status'] as int).clamp(0, BookingStatus.values.length - 1)],
    providerPhone: j['providerPhone'] as String?,
    paidLast4: j['paidLast4'] as String?,
  );
}
