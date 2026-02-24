// lib/core/constants/countries.dart

class Country {
  final String code;
  final String name;
  
  const Country({required this.code, required this.name});
  
  String get flag {
    // Convertit le code pays en drapeau emoji (ex: 'SN' -> '🇸🇳')
    if (code.length != 2) return '🌍';
    final int first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
  
  String get displayName => '$flag $name';
}

// Liste complète des pays africains (identique à votre backend)
const List<Country> africanCountries = [
  Country(code: 'DZ', name: 'Algérie'),
  Country(code: 'AO', name: 'Angola'),
  Country(code: 'BJ', name: 'Bénin'),
  Country(code: 'BW', name: 'Botswana'),
  Country(code: 'BF', name: 'Burkina Faso'),
  Country(code: 'BI', name: 'Burundi'),
  Country(code: 'CV', name: 'Cap-Vert'),
  Country(code: 'CM', name: 'Cameroun'),
  Country(code: 'CF', name: 'République centrafricaine'),
  Country(code: 'TD', name: 'Tchad'),
  Country(code: 'KM', name: 'Comores'),
  Country(code: 'CG', name: 'Congo'),
  Country(code: 'CD', name: 'République démocratique du Congo'),
  Country(code: 'CI', name: "Côte d'Ivoire"),
  Country(code: 'DJ', name: 'Djibouti'),
  Country(code: 'EG', name: 'Égypte'),
  Country(code: 'GQ', name: 'Guinée équatoriale'),
  Country(code: 'ER', name: 'Érythrée'),
  Country(code: 'SZ', name: 'Eswatini'),
  Country(code: 'ET', name: 'Éthiopie'),
  Country(code: 'GA', name: 'Gabon'),
  Country(code: 'GM', name: 'Gambie'),
  Country(code: 'GH', name: 'Ghana'),
  Country(code: 'GN', name: 'Guinée'),
  Country(code: 'GW', name: 'Guinée-Bissau'),
  Country(code: 'KE', name: 'Kenya'),
  Country(code: 'LS', name: 'Lesotho'),
  Country(code: 'LR', name: 'Liberia'),
  Country(code: 'LY', name: 'Libye'),
  Country(code: 'MG', name: 'Madagascar'),
  Country(code: 'MW', name: 'Malawi'),
  Country(code: 'ML', name: 'Mali'),
  Country(code: 'MR', name: 'Mauritanie'),
  Country(code: 'MU', name: 'Maurice'),
  Country(code: 'MA', name: 'Maroc'),
  Country(code: 'MZ', name: 'Mozambique'),
  Country(code: 'NA', name: 'Namibie'),
  Country(code: 'NE', name: 'Niger'),
  Country(code: 'NG', name: 'Nigeria'),
  Country(code: 'RW', name: 'Rwanda'),
  Country(code: 'ST', name: 'Sao Tomé-et-Principe'),
  Country(code: 'SN', name: 'Sénégal'),
  Country(code: 'SC', name: 'Seychelles'),
  Country(code: 'SL', name: 'Sierra Leone'),
  Country(code: 'SO', name: 'Somalie'),
  Country(code: 'ZA', name: 'Afrique du Sud'),
  Country(code: 'SS', name: 'Soudan du Sud'),
  Country(code: 'SD', name: 'Soudan'),
  Country(code: 'TZ', name: 'Tanzanie'),
  Country(code: 'TG', name: 'Togo'),
  Country(code: 'TN', name: 'Tunisie'),
  Country(code: 'UG', name: 'Ouganda'),
  Country(code: 'ZM', name: 'Zambie'),
  Country(code: 'ZW', name: 'Zimbabwe'),
];

// Maps utilitaires pour un accès rapide
final Map<String, Country> countryByCode = {
  for (var country in africanCountries) country.code: country
};

final Map<String, String> countryNames = {
  for (var country in africanCountries) country.code: country.name
};

// Liste des codes pays seulement
final List<String> countryCodes = africanCountries.map((c) => c.code).toList();

// Fonction utilitaire pour obtenir le nom à partir du code
String getCountryName(String code) {
  return countryByCode[code]?.name ?? code;
}

// Fonction pour obtenir le drapeau
String getCountryFlag(String code) {
  return countryByCode[code]?.flag ?? '🌍';
}