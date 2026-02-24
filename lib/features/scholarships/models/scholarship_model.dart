class Scholarship {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String? providerLogo;
  final String type;
  final List<String> countries;
  final List<String> fields;
  final List<String> level;
  final double? amount;
  final String? currency;
  final DateTime deadline;
  final DateTime? startDate;
  final String? duration;
  final String link;
  final String? requirements;
  final List<String> benefits;
  final List<String> languages;
  final bool isActive;
  final bool isFeatured;
  final int views;
  final DateTime createdAt;
  bool isSaved;

  Scholarship({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    this.providerLogo,
    required this.type,
    required this.countries,
    required this.fields,
    required this.level,
    this.amount,
    this.currency,
    required this.deadline,
    this.startDate,
    this.duration,
    required this.link,
    this.requirements,
    required this.benefits,
    required this.languages,
    required this.isActive,
    required this.isFeatured,
    required this.views,
    required this.createdAt,
    this.isSaved = false,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      provider: json['provider'],
      providerLogo: json['providerLogo'],
      type: json['type'],
      countries: List<String>.from(json['countries'] ?? []),
      fields: List<String>.from(json['fields'] ?? []),
      level: List<String>.from(json['level'] ?? []),
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      deadline: DateTime.parse(json['deadline']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      duration: json['duration'],
      link: json['link'],
      requirements: json['requirements'],
      benefits: List<String>.from(json['benefits'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      views: json['views'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isSaved: json['isSaved'] ?? false,
    );
  }

  int get daysLeft {
    return deadline.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon => daysLeft <= 7;
  bool get isExpired => daysLeft < 0;

  String get typeLabel {
    switch (type) {
      case 'COMPLETE': return 'Complète';
      case 'PARTIELLE': return 'Partielle';
      case 'RECHERCHE': return 'Recherche';
      case 'FORMATION': return 'Formation';
      default: return type;
    }
  }

  String get amountFormatted {
    if (amount == null) return 'Variable';
    return '${amount!.toStringAsFixed(0)} ${currency ?? 'USD'}';
  }
}
