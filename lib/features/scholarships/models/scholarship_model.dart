import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Pour kReleaseMode
import '../../../core/constants/countries.dart';
import '../../../core/utils/display_formatters.dart';

// ⚡ Commenter temporairement la génération Hive si pas encore généré
// part 'scholarship_model.g.dart';

// ⚡ Commenter @HiveType temporairement si pas encore généré
// @HiveType(typeId: 0)
class Scholarship extends Equatable {
  // @HiveField(0)
  final String id;

  // @HiveField(1)
  final String title;

  // @HiveField(2)
  final String description;

  // @HiveField(3)
  final String provider;

  // @HiveField(4)
  final String? providerLogo;

  // @HiveField(5)
  final String type;

  // @HiveField(6)
  final List<String> countries;

  // @HiveField(7)
  final List<String> fields;

  // @HiveField(8)
  final List<String> level;

  // @HiveField(9)
  final double? amount;

  // @HiveField(10)
  final String? currency;

  // @HiveField(11)
  final DateTime deadline;

  // @HiveField(12)
  final DateTime? startDate;

  // @HiveField(13)
  final String? duration;

  // @HiveField(14)
  final String link;

  // @HiveField(15)
  final String? requirements;

  // @HiveField(16)
  final List<String> benefits;

  // @HiveField(17)
  final List<String> languages;

  // @HiveField(18)
  final bool isActive;

  // @HiveField(19)
  final bool isFeatured;

  // @HiveField(20)
  final int views;

  // @HiveField(21)
  final DateTime createdAt;

  // @HiveField(22)
  final bool isSaved;

  const Scholarship({
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

  // ⚡ Fonction de log conditionnelle
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('📝 ScholarshipModel: $message');
    }
  }

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    try {
      return Scholarship(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        provider: json['provider'] ?? '',
        providerLogo: json['providerLogo'],
        type: json['type'] ?? '',
        countries: List<String>.from(json['countries'] ?? []),
        fields: List<String>.from(json['fields'] ?? []),
        level: List<String>.from(json['level'] ?? []),
        amount: json['amount']?.toDouble(),
        currency: json['currency'],
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'])
            : DateTime.now(),
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        duration: json['duration'],
        link: json['link'] ?? '',
        requirements: json['requirements'],
        benefits: List<String>.from(json['benefits'] ?? []),
        languages: List<String>.from(json['languages'] ?? []),
        isActive: json['isActive'] ?? true,
        isFeatured: json['isFeatured'] ?? false,
        views: json['views'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        isSaved: json['isSaved'] ?? false,
      );
    } catch (e) {
      _log('Erreur parsing Scholarship: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider': provider,
      'providerLogo': providerLogo,
      'type': type,
      'countries': countries,
      'fields': fields,
      'level': level,
      'amount': amount,
      'currency': currency,
      'deadline': deadline.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'duration': duration,
      'link': link,
      'requirements': requirements,
      'benefits': benefits,
      'languages': languages,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
      'isSaved': isSaved,
    };
  }

  // Getter pour les pays avec drapeaux et noms
  List<Map<String, String>> get countriesWithDetails {
    return countries.map((code) {
      final country = countryByCode[code];
      return {
        'code': code,
        'name': country?.name ?? code,
        'flag': country?.flag ?? '🌍',
      };
    }).toList();
  }

  // Noms des pays formatés avec drapeaux
  String get formattedCountries {
    if (countries.isEmpty) return 'Tous les pays';

    final countryNames = countries.map((code) {
      final country = countryByCode[code];
      return country?.displayName ?? code;
    }).toList();

    if (countries.length > 3) {
      final firstThree = countryNames.take(3).join(', ');
      return '$firstThree et ${countries.length - 3} autres';
    }

    return countryNames.join(', ');
  }

  // Liste des drapeaux pour affichage compact
  String get countryFlags {
    if (countries.isEmpty) return '🌍';
    return countries.map((code) => getCountryFlag(code)).join(' ');
  }

  // Vérifier si un pays est éligible
  bool isEligibleForCountry(String countryCode) {
    return countries.contains(countryCode);
  }

  // Obtenir les détails d'un pays spécifique
  Map<String, String>? getCountryDetails(String countryCode) {
    if (!countries.contains(countryCode)) return null;
    final country = countryByCode[countryCode];
    if (country == null) return null;

    return {
      'code': country.code,
      'name': country.name,
      'flag': country.flag,
    };
  }

  int get daysLeft {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  bool get isExpiringSoon => daysLeft <= 7 && daysLeft >= 0;
  bool get isExpired => daysLeft < 0;

  String get typeLabel {
    switch (type) {
      case 'COMPLETE':
        return 'Complète';
      case 'PARTIELLE':
        return 'Partielle';
      case 'RECHERCHE':
        return 'Recherche';
      case 'FORMATION':
        return 'Formation';
      default:
        return type;
    }
  }

  String get amountFormatted {
    if (amount == null) return 'Variable';

    final formatter = NumberFormat('#,###', 'fr_FR');
    final formattedAmount = formatter.format(amount);

    if (currency == null) return formattedAmount;

    switch (currency) {
      case 'USD':
        return '\$$formattedAmount';
      case 'EUR':
        return '$formattedAmount €';
      case 'GBP':
        return '£$formattedAmount';
      case 'XOF':
      case 'XAF':
        return '$formattedAmount FCFA';
      default:
        return '$formattedAmount $currency';
    }
  }

  String get fieldNames {
    if (fields.isEmpty) return 'Tous domaines';
    if (fields.length > 3) {
      return '${fields.take(3).map(formatFieldLabel).join(', ')}...';
    }
    return fields.map(formatFieldLabel).join(', ');
  }

  // Méthode copyWith
  Scholarship copyWith({
    String? id,
    String? title,
    String? description,
    String? provider,
    String? providerLogo,
    String? type,
    List<String>? countries,
    List<String>? fields,
    List<String>? level,
    double? amount,
    String? currency,
    DateTime? deadline,
    DateTime? startDate,
    String? duration,
    String? link,
    String? requirements,
    List<String>? benefits,
    List<String>? languages,
    bool? isActive,
    bool? isFeatured,
    int? views,
    DateTime? createdAt,
    bool? isSaved,
  }) {
    return Scholarship(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      providerLogo: providerLogo ?? this.providerLogo,
      type: type ?? this.type,
      countries: countries ?? this.countries,
      fields: fields ?? this.fields,
      level: level ?? this.level,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      deadline: deadline ?? this.deadline,
      startDate: startDate ?? this.startDate,
      duration: duration ?? this.duration,
      link: link ?? this.link,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      languages: languages ?? this.languages,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        provider,
        providerLogo,
        type,
        countries,
        fields,
        level,
        amount,
        currency,
        deadline,
        startDate,
        duration,
        link,
        requirements,
        benefits,
        languages,
        isActive,
        isFeatured,
        views,
        createdAt,
        isSaved,
      ];
}

// Extension pour faciliter le filtrage par pays
extension ScholarshipListExtension on List<Scholarship> {
  List<Scholarship> filterByType(String type) {
    if (type.isEmpty) return this;
    return where((s) => s.type == type).toList();
  }

  List<Scholarship> filterByLevel(String level) {
    if (level.isEmpty) return this;
    return where((s) => s.level.contains(level)).toList();
  }

  List<Scholarship> filterByCountry(String countryCode) {
    if (countryCode.isEmpty) return this;
    return where((s) => s.countries.contains(countryCode)).toList();
  }

  List<Scholarship> filterByCountries(List<String> countryCodes) {
    if (countryCodes.isEmpty) return this;
    return where((s) => s.countries.any((code) => countryCodes.contains(code)))
        .toList();
  }

  List<Scholarship> search(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((s) =>
        s.title.toLowerCase().contains(lowerQuery) ||
        s.description.toLowerCase().contains(lowerQuery) ||
        s.provider.toLowerCase().contains(lowerQuery) ||
        s.fields.any((f) => f.toLowerCase().contains(lowerQuery))).toList();
  }

  List<Scholarship> get saved => where((s) => s.isSaved).toList();
  List<Scholarship> get featured => where((s) => s.isFeatured).toList();
  List<Scholarship> get active =>
      where((s) => s.isActive && !s.isExpired).toList();
  List<Scholarship> get expiringSoon => where((s) => s.isExpiringSoon).toList();

  // Filtrer par continent (Afrique uniquement ici)
  List<Scholarship> get africanOnly => where((s) =>
      s.countries.any((code) => africanCountriesCodes.contains(code))).toList();
}

// Liste des codes pays africains pour référence rapide
const List<String> africanCountriesCodes = [
  'DZ',
  'AO',
  'BJ',
  'BW',
  'BF',
  'BI',
  'CV',
  'CM',
  'CF',
  'TD',
  'KM',
  'CG',
  'CD',
  'CI',
  'DJ',
  'EG',
  'GQ',
  'ER',
  'SZ',
  'ET',
  'GA',
  'GM',
  'GH',
  'GN',
  'GW',
  'KE',
  'LS',
  'LR',
  'LY',
  'MG',
  'MW',
  'ML',
  'MR',
  'MU',
  'MA',
  'MZ',
  'NA',
  'NE',
  'NG',
  'RW',
  'ST',
  'SN',
  'SC',
  'SL',
  'SO',
  'ZA',
  'SS',
  'SD',
  'TZ',
  'TG',
  'TN',
  'UG',
  'ZM',
  'ZW',
];
