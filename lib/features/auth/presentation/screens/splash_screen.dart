import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_consent_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget? homeTarget;

  const SplashScreen({super.key, this.homeTarget});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNextScreen();
  }

  Future<void> _checkNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final isOnboardingDone = await LocalAuthRepository.isOnboardingCompleted();
    if (!mounted) return;

    if (!isOnboardingDone) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (!auth.user!.hasAcceptedPrivacyConsent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => PrivacyConsentScreen(
            onConsentAccepted: () {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      widget.homeTarget ?? const Scaffold(body: Center(child: Text('Home'))),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            widget.homeTarget ?? const Scaffold(body: Center(child: Text('Home'))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineDark, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.outlineDark.withValues(alpha: 0.2),
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 58,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: AppTypography.displayLarge.copyWith(fontSize: 38),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
