import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import 'privacy_consent_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShellScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppColors.errorCoral,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String? _validateName(String? val) {
    if (val == null || val.trim().isEmpty) return 'El nombre es obligatorio';
    if (val.trim().length < 2) return 'El nombre debe tener al menos 2 caracteres';
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'El correo es obligatorio';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(val.trim())) return 'Ingresa un correo válido (ej: tu@correo.com)';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'La contraseña es obligatoria';
    if (val.length < 6) return 'Mínimo 6 caracteres';
    if (!val.contains(RegExp(r'[A-Za-z]'))) return 'Debe contener al menos una letra';
    return null;
  }

  String? _validateConfirm(String? val) {
    if (val == null || val.isEmpty) return 'Repite la contraseña';
    if (val != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  bool _validate() {
    final nameErr = _validateName(_nameController.text);
    final emailErr = _validateEmail(_emailController.text);
    final passErr = _validatePassword(_passwordController.text);
    final confirmErr = _validateConfirm(_confirmPasswordController.text);
    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmError = confirmErr;
    });
    return nameErr == null && emailErr == null && passErr == null && confirmErr == null;
  }

  Future<void> _handleRegister() async {
    if (!_validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      final user = auth.user;
      if (user != null && !user.hasAcceptedPrivacyConsent) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PrivacyConsentScreen(),
          ),
          (route) => false,
        );
      } else {
        _navigateToHome();
      }
    } else {
      _showError(auth.errorMessage ?? 'No se pudo crear la cuenta. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¡Únete a ${AppConstants.appName}!',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Aprende a cocinar fácil y con guía inteligente',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.outlineDark, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.outlineDark.withValues(alpha: 0.1),
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nombre
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                        decoration: InputDecoration(
                          labelText: 'Tu nombre o apodo culinario',
                          hintText: 'ej: Chef Carlos',
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _nameError,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: _emailError,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Contraseña
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                          if (_confirmError != null) setState(() => _confirmError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Contraseña (mín. 6 caracteres)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: _passwordError,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirmar contraseña
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onSubmitted: (_) => isLoading ? null : _handleRegister(),
                        onChanged: (_) { if (_confirmError != null) setState(() => _confirmError = null); },
                        decoration: InputDecoration(
                          labelText: 'Repetir contraseña',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          errorText: _confirmError,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleRegister,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Crear mi cuenta'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Ya tengo una cuenta. Iniciar sesión',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primaryDarkTeal,
                        fontSize: 15,
                      ),
                    ),
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
