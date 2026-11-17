import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';

/// Pantalla de consentimiento de privacidad según Ley 1581 de 2012 (Habeas Data)
class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback? onConsentAccepted;

  const PrivacyConsentScreen({super.key, this.onConsentAccepted});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _acceptedTerms = false;
  bool _loading = false;

  Future<void> _handleAccept() async {
    if (!_acceptedTerms) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.acceptPrivacyConsent();
    } catch (e) {
      debugPrint('Error accepting privacy consent: $e');
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (widget.onConsentAccepted != null) {
      try {
        widget.onConsentAccepted!();
        return;
      } catch (e) {
        debugPrint('onConsentAccepted failed, falling back to direct navigation: $e');
      }
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShellScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Privacidad y Permisos'),
        // Ocultar back si es flujo obligatorio (onConsentAccepted presente y no puede hacer pop útil)
        automaticallyImplyLeading: widget.onConsentAccepted == null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineDark, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 40, color: AppColors.primaryTeal),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Tu privacidad en la cocina es primordial',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Texto de política
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineDark, width: 2),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      AppConstants.habeasDataPolicy,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checkbox — envuelto en Material para evitar la aserción de ListTile
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _acceptedTerms
                          ? AppColors.mintSoft.withValues(alpha: 0.6)
                          : AppColors.mintSoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _acceptedTerms ? AppColors.primaryTeal : AppColors.outlineDark,
                        width: _acceptedTerms ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'Entiendo y autorizo el uso efímero de audio y cámara para el asistente culinario. '
                            'Ningún dato se almacena de forma permanente.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!_acceptedTerms)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Debes marcar la casilla para continuar.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_acceptedTerms && !_loading) ? _handleAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    disabledBackgroundColor: AppColors.outlineDark.withValues(alpha: 0.2),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _acceptedTerms ? 'Aceptar y Continuar' : 'Acepta los términos para continuar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
