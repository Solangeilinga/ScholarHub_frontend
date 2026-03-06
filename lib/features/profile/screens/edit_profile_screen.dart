import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/countries.dart';
import '../../../core/constants/languages.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  String? _country;
  String? _level;
  List<String> _fields = [];
  List<String> _languages = [];
  bool _loading = false;

  static const _levelCodes = [
    'BEPC',
    'BACCALAUREAT',
    'LICENCE_1',
    'LICENCE_2',
    'LICENCE_3',
    'LICENCE',
    'MAITRISE',
    'MASTER_1',
    'MASTER_2',
    'MASTER',
    'DOCTORAT_1',
    'DOCTORAT_2',
    'DOCTORAT',
    'POSTDOC',
  ];

  static const _fieldCodes = [
    'STEM',
    'MEDECINE',
    'DROIT',
    'BUSINESS',
    'ARTS',
    'AGRICULTURE',
    'EDUCATION',
    'INGENIERIE',
    'INFORMATIQUE',
    'SCIENCES_SOCIALES',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticatedState) {
      _nameCtrl = TextEditingController(text: state.user['name'] ?? '');
      _bioCtrl = TextEditingController(text: state.user['bio'] ?? '');
      _country = normalizeCountryCode(state.user['country']?.toString());
      _level = normalizeLevelCode(state.user['level']?.toString());
      _fields = List<String>.from(state.user['fields'] ?? [])
          .map((e) => normalizeFieldCode(e.toString()))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      _languages = List<String>.from(state.user['languages'] ?? [])
          .map((e) => normalizeLanguageCode(e.toString()))
          .whereType<String>()
          .toSet()
          .toList();
    } else {
      _nameCtrl = TextEditingController();
      _bioCtrl = TextEditingController();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final normalizedLevel = normalizeLevelCode(_level);
    final payload = {
      'name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'country': normalizeCountryCode(_country),
      'level': normalizedLevel,
      'fields': _fields.map(normalizeFieldCode).toList(),
      'languages': _languages
          .map(normalizeLanguageCode)
          .whereType<String>()
          .toList(),
    };

    try {
      try {
        await context.read<ApiClient>().updateProfile(payload);
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        final backendError =
            (e.response?.data is Map<String, dynamic>)
                ? (e.response?.data['error']?.toString() ?? '')
                : '';
        final hasGranularLevel =
            (normalizedLevel ?? '').contains('_') || (normalizedLevel ?? '') == 'BACCALAUREAT';
        final isStudyLevelValidationError =
            backendError.contains('Expected StudyLevel') ||
            backendError.contains('Invalid value for argument `level`');

        // Compat backend: certains environnements n'acceptent que LICENCE/MASTER/DOCTORAT
        if ((status == 400 || status == 422 || (status >= 500 && isStudyLevelValidationError)) &&
            hasGranularLevel) {
          await context.read<ApiClient>().updateProfile({
            ...payload,
            'level': toBaseLevelCode(normalizedLevel),
          });
        } else {
          rethrow;
        }
      }

      // Refresh auth
      context.read<AuthBloc>().add(AuthCheckEvent());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour ✅'), backgroundColor: AppTheme.secondary),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: AppTheme.accent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outlined)),
                validator: (v) => v!.length >= 2 ? null : 'Nom requis',
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _country,
                hint: const Text('Pays'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined)),
                items: africanCountries
                    .map((country) => DropdownMenuItem(
                          value: country.code,
                          child: Text(country.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _country = v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _level,
                hint: const Text('Niveau d\'études'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                items: _levelCodes
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(formatLevelLabel(code)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 24),

              const Text('Domaines d\'intérêt', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _fieldCodes.map((code) => FilterChip(
                  label: Text(formatFieldLabel(code)),
                  selected: _fields.contains(code),
                  onSelected: (v) => setState(() {
                    if (v) {
                      if (!_fields.contains(code)) _fields.add(code);
                    } else {
                      _fields.remove(code);
                    }
                  }),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                )).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Langues maîtrisées', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: languages.map((lang) => FilterChip(
                  label: Text(lang.name),
                  selected: _languages.contains(lang.code),
                  onSelected: (v) => setState(() {
                    if (v) {
                      if (!_languages.contains(lang.code)) _languages.add(lang.code);
                    } else {
                      _languages.remove(lang.code);
                    }
                  }),
                  selectedColor: AppTheme.secondary.withOpacity(0.15),
                )).toList(),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Parlez de vous, vos ambitions...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer le profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
