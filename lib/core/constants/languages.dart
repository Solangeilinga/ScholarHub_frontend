// lib/core/constants/languages.dart

class Language {
  final String code;
  final String name;
  
  const Language({required this.code, required this.name});
}

// Liste complète des langues (identique au backend)
const List<Language> languages = [
  Language(code: 'EN', name: 'Anglais'),
  Language(code: 'FR', name: 'Français'),
  Language(code: 'ES', name: 'Espagnol'),
  Language(code: 'AR', name: 'Arabe'),
  Language(code: 'PT', name: 'Portugais'),
  Language(code: 'DE', name: 'Allemand'),
  Language(code: 'ZH', name: 'Chinois (Mandarin)'),
  Language(code: 'RU', name: 'Russe'),
  Language(code: 'IT', name: 'Italien'),
  Language(code: 'TR', name: 'Turc'),
  Language(code: 'NL', name: 'Néerlandais'),
  Language(code: 'JA', name: 'Japonais'),
  Language(code: 'KO', name: 'Coréen'),
  Language(code: 'HI', name: 'Hindi'),
  Language(code: 'SV', name: 'Suédois'),
];

// Maps utilitaires pour un accès rapide
final Map<String, Language> languageByCode = {
  for (var lang in languages) lang.code: lang
};

final Map<String, String> languageNames = {
  for (var lang in languages) lang.code: lang.name
};

// Liste des codes seulement
final List<String> languageCodes = languages.map((l) => l.code).toList();

// Fonction utilitaire pour obtenir le nom à partir du code
String getLanguageName(String code) {
  return languageByCode[code]?.name ?? code;
}