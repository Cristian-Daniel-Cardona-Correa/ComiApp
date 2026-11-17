import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import 'privacy_consent_screen.dart';
import 'register_screen.dart';
import '../widgets/google_account_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShellScreen()),
      (route) => false,
    );
  }

  void _navigateToPrivacyThenHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PrivacyConsentScreen(),
      ),
      (route) => false,
    );
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user != null && !user.hasAcceptedPrivacyConsent) {
      _navigateToPrivacyThenHome();
    } else {
      _navigateToHome();
    }
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
    return null;
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

  Future<void> _handleLogin() async {
    final emailErr = _validateEmail(_emailController.text);
    final passErr = _validatePassword(_passwordController.text);
    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
      });
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else {
      _showError(auth.errorMessage ?? 'Error al iniciar sesión. Revisa tus credenciales.');
    }
  }

  Future<void> _handleGoogleLogin() async {
    final account = await GoogleAccountDialog.show(context);
    if (account == null) return; // Usuario canceló la selección

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(
      email: account['email'],
      name: account['name'],
    );
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else {
      _showError(auth.errorMessage ?? 'No se pudo iniciar sesión con Google.');
    }
  }

  Future<void> _handleGuestLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInAsGuest();
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else {
      _showError(auth.errorMessage ?? 'Error al entrar como invitado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outlineDark, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.outlineDark.withValues(alpha: 0.15),
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: AppTypography.displayLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Tu cocina inteligente, siempre contigo',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Card formulario
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
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: _emailError,
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onSubmitted: (_) => isLoading ? null : _handleLogin(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: _passwordError,
                          errorStyle: const TextStyle(color: AppColors.errorCoral, fontWeight: FontWeight.w600),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Iniciar Sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Separador
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.outlineDark)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continúa con',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.outlineDark)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _handleGoogleLogin,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Continuar con Google'),
                  ),
                ),
                const SizedBox(height: 12),

                // Invitado
                SizedBox(
                  height: 54,
                  child: TextButton(
                    onPressed: isLoading ? null : _handleGuestLogin,
                    child: Text(
                      'Entrar como invitado (sin cuenta)',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primaryDarkTeal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Crear cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Aún no tienes cuenta? ', style: AppTypography.bodyMedium),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              ),
                      child: Text(
                        'Regístrate aquí',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
