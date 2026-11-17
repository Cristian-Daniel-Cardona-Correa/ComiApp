import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import 'privacy_consent_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'cocinero@comiapp.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null && !user.hasAcceptedPrivacyConsent) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PrivacyConsentScreen(
            onConsentAccepted: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShellScreen()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShellScreen()),
        (route) => false,
      );
    }
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.errorCoral,
        ),
      );
    }
  }

  void _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.errorCoral,
        ),
      );
    }
  }

  void _handleGuestLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInAsGuest();
    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.errorCoral,
        ),
      );
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
                // Logo culinario
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outlineDark, width: 3),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 48,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: AppTypography.displayLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Entra a tu cocina personalizada',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Card de formulario con trazo grueso
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
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textDark),
                                ),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Google
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continuar con Google'),
                ),
                const SizedBox(height: 12),

                // Botón invitado
                TextButton(
                  onPressed: isLoading ? null : _handleGuestLogin,
                  child: Text(
                    'Entrar como invitado (sin cuenta)',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primaryDarkTeal,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Aún no tienes cuenta? ',
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Regístrate aquí',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w800,
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
