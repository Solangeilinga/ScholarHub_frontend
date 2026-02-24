import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

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

  static const _africanCountries = {
    'BF': '🇧🇫 Burkina Faso', 'ML': '🇲🇱 Mali', 'NE': '🇳🇪 Niger',
    'SN': '🇸🇳 Sénégal', 'CI': '🇨🇮 Côte d\'Ivoire', 'TG': '🇹🇬 Togo',
    'BJ': '🇧🇯 Bénin', 'GN': '🇬🇳 Guinée', 'GH': '🇬🇭 Ghana',
    'NG': '🇳🇬 Nigeria', 'CM': '🇨🇲 Cameroun', 'KE': '🇰🇪 Kenya',
    'ET': '🇪🇹 Éthiopie', 'ZA': '🇿🇦 Afrique du Sud', 'EG': '🇪🇬 Égypte',
    'MA': '🇲🇦 Maroc', 'DZ': '🇩🇿 Algérie', 'TN': '🇹🇳 Tunisie',
  };

  static const _domaines = ['STEM', 'Médecine', 'Droit', 'Business', 'Arts', 'Agriculture', 'Éducation', 'Ingénierie', 'Informatique', 'Sciences sociales'];
  static const _langues = ['Français', 'Anglais', 'Arabe', 'Portugais', 'Swahili'];

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticatedState) {
      _nameCtrl = TextEditingController(text: state.user['name'] ?? '');
      _bioCtrl = TextEditingController(text: state.user['bio'] ?? '');
      _country = state.user['country'];
      _level = state.user['level'];
      _fields = List<String>.from(state.user['fields'] ?? []);
      _languages = List<String>.from(state.user['languages'] ?? []);
    } else {
      _nameCtrl = TextEditingController();
      _bioCtrl = TextEditingController();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<ApiClient>().updateProfile({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'country': _country,
        'level': _level,
        'fields': _fields,
        'languages': _languages,
      });
      // Refresh auth
      context.read<AuthBloc>().add(AuthCheckEvent());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour ✅'), backgroundColor: AppTheme.secondary),
        );
        context.pop();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: AppTheme.accent),
      );
    } finally {
      setState(() => _loading = false);
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
                items: _africanCountries.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _country = v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _level,
                hint: const Text('Niveau d\'études'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                items: ['LICENCE', 'MASTER', 'DOCTORAT', 'POSTDOC'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 24),

              const Text('Domaines d\'intérêt', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _domaines.map((d) => FilterChip(
                  label: Text(d),
                  selected: _fields.contains(d),
                  onSelected: (v) => setState(() => v ? _fields.add(d) : _fields.remove(d)),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                )).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Langues maîtrisées', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _langues.map((l) => FilterChip(
                  label: Text(l),
                  selected: _languages.contains(l),
                  onSelected: (v) => setState(() => v ? _languages.add(l) : _languages.remove(l)),
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
