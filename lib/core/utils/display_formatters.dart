import 'package:intl/intl.dart';

import '../constants/countries.dart';
import '../constants/languages.dart';

const Map<String, String> levelLabels = {
  'BEPC': 'BEPC',
  'BACCALAUREAT': 'Baccalauréat',
  'LICENCE_1': 'Licence 1',
  'LICENCE_2': 'Licence 2',
  'LICENCE_3': 'Licence 3',
  'LICENCE': 'Licence',
  'MAITRISE': 'Maîtrise',
  'MASTER_1': 'Master 1',
  'MASTER_2': 'Master 2',
  'MASTER': 'Master',
  'DOCTORAT_1': 'Doctorat 1',
  'DOCTORAT_2': 'Doctorat 2',
  'DOCTORAT': 'Doctorat',
  'POSTDOC': 'Postdoc',
};

const Map<String, String> fieldLabels = {
  'STEM': 'STEM',
  'MEDECINE': 'Médecine',
  'DROIT': 'Droit',
  'BUSINESS': 'Business',
  'ARTS': 'Arts',
  'AGRICULTURE': 'Agriculture',
  'EDUCATION': 'Éducation',
  'INGENIERIE': 'Ingénierie',
  'INFORMATIQUE': 'Informatique',
  'SCIENCES_SOCIALES': 'Sciences sociales',
};

String formatDateFr(DateTime date, {String pattern = 'dd MMM yyyy'}) {
  return DateFormat(pattern, 'fr_FR').format(date);
}

String formatCountryLabel(String codeOrName, {bool withFlag = false}) {
  final value = codeOrName.trim();
  if (value.isEmpty) return value;
  final country = countryByCode[value.toUpperCase()];
  if (country == null) return value;
  return withFlag ? country.displayName : country.name;
}

String? normalizeCountryCode(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return null;
  final upper = input.toUpperCase();
  if (countryByCode.containsKey(upper)) return upper;

  final byName = africanCountries.firstWhere(
    (country) => country.name.toLowerCase() == input.toLowerCase(),
    orElse: () => const Country(code: '', name: ''),
  );
  return byName.code.isEmpty ? null : byName.code;
}

String formatLanguageLabel(String codeOrName) {
  final value = codeOrName.trim();
  if (value.isEmpty) return value;
  final byCode = languageByCode[value.toUpperCase()];
  if (byCode != null) return byCode.name;
  final byName = languages.firstWhere(
    (lang) => lang.name.toLowerCase() == value.toLowerCase(),
    orElse: () => const Language(code: '', name: ''),
  );
  if (byName.code.isNotEmpty) return byName.name;
  return _titleizeToken(value);
}

String formatLevelLabel(String level) {
  final value = level.trim();
  if (value.isEmpty) return value;
  return levelLabels[value] ?? _titleizeToken(value);
}

String formatFieldLabel(String field) {
  final value = field.trim();
  if (value.isEmpty) return value;
  return fieldLabels[value] ?? _titleizeToken(value);
}

String? normalizeLanguageCode(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return null;
  final upper = input.toUpperCase();
  if (languageByCode.containsKey(upper)) return upper;

  final byName = languages.firstWhere(
    (lang) => lang.name.toLowerCase() == input.toLowerCase(),
    orElse: () => const Language(code: '', name: ''),
  );
  return byName.code.isEmpty ? null : byName.code;
}

String? normalizeLevelCode(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return null;
  if (levelLabels.containsKey(input)) return input;

  final fromLabel = levelLabels.entries
      .where((e) => e.value.toLowerCase() == input.toLowerCase())
      .map((e) => e.key)
      .toList();
  if (fromLabel.isNotEmpty) return fromLabel.first;

  final generated = _codeify(input);
  return levelLabels.containsKey(generated) ? generated : generated;
}

String toBaseLevelCode(String? levelCode) {
  final value = (levelCode ?? '').trim().toUpperCase();
  if (value.isEmpty) return value;
  if (value.startsWith('LICENCE')) return 'LICENCE';
  if (value.startsWith('MASTER')) return 'MASTER';
  if (value.startsWith('DOCTORAT')) return 'DOCTORAT';
  return value;
}

String normalizeFieldCode(String value) {
  final input = value.trim();
  if (input.isEmpty) return input;
  if (fieldLabels.containsKey(input)) return input;

  final fromLabel = fieldLabels.entries
      .where((e) => e.value.toLowerCase() == input.toLowerCase())
      .map((e) => e.key)
      .toList();
  if (fromLabel.isNotEmpty) return fromLabel.first;

  return _codeify(input);
}

String _codeify(String value) {
  return _stripAccents(value)
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _titleizeToken(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) {
    if (part.length <= 3 && RegExp(r'^[a-z0-9]+$').hasMatch(part)) {
      return part.toUpperCase();
    }
    return '${part[0].toUpperCase()}${part.substring(1)}';
  }).join(' ');
}

String _stripAccents(String input) {
  const from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿÇçÑñ';
  const to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuYyyCcNn';
  var result = input;
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result;
}
