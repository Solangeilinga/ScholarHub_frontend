import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/countries.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedCountry;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  // SUPPRIMER ces deux constantes car elles sont maintenant dans countries.dart
  // static const _africanCountries = [...];
  // static const _countryNames = {...};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() => context.go('/auth/login');

  void _submit() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions d\'utilisation')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterEvent(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        country: _selectedCountry,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _goToLogin,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.accent),
            );
          } else if (state is AuthAuthenticatedState) {
            context.go('/home');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo centré
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ScholarHub',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text('Créer un compte', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Rejoignez des milliers d\'étudiants africains', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outlined)),
                  validator: (v) => v!.length >= 2 ? null : 'Nom requis',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v!.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v!.length >= 8 ? null : 'Minimum 8 caractères',
                ),
                const SizedBox(height: 16),

                // CORRECTION: Utiliser africanCountries du fichier partagé
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  hint: const Text('Sélectionner votre pays'),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined)),
                  items: africanCountries.map((country) => DropdownMenuItem(
                    value: country.code,
                    child: Text(country.displayName), // Utilise displayName avec drapeau
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCountry = v),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v!),
                      activeColor: AppTheme.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                        child: const Text('J\'accepte les conditions d\'utilisation et la politique de confidentialité'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state is AuthLoadingState ? null : _submit,
                      child: state is AuthLoadingState
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Créer mon compte'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: _goToLogin,
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}