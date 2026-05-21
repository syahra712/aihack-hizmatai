class ProviderScores {
  final int overall;
  final int ratingScore;
  final int experience;
  final int responseTime;
  final int completion;
  final int certified;
  final int priceValue;

  const ProviderScores({
    required this.overall,
    required this.ratingScore,
    required this.experience,
    required this.responseTime,
    required this.completion,
    required this.certified,
    required this.priceValue,
  });
}

class ServiceProvider {
  final String id;
  final String name;
  final String serviceType;
  final String city;
  final String zone;
  final double rating;
  final int reviewCount;
  final int priceEstimate;
  final double distanceKm;
  final bool isAvailable;
  final List<String> specializations;
  final String? whyChosen;
  final ProviderScores? scores;
  final int responseMinutes;
  final int jobsCompleted;
  final bool isCertified;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.city,
    required this.zone,
    required this.rating,
    required this.reviewCount,
    required this.priceEstimate,
    required this.distanceKm,
    required this.isAvailable,
    required this.specializations,
    this.whyChosen,
    this.scores,
    this.responseMinutes = 15,
    this.jobsCompleted = 0,
    this.isCertified = false,
  });

  String get serviceLabel => {
    'electrician': 'Electrician',
    'plumber': 'Plumber',
    'cleaner': 'Cleaner',
    'ac_repair': 'AC Technician',
    'home_tutor': 'Home Tutor',
    'beautician': 'Beautician',
    'painter': 'Painter',
    'carpenter': 'Carpenter',
  }[serviceType] ?? serviceType;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.substring(0, 2).toUpperCase();
  }
}
