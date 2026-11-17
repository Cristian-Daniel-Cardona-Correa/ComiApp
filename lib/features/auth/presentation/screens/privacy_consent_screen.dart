import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de consentimiento de privacidad según Ley 1581 de 2012 (Habeas Data)
class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback? onConsentAccepted;

  const PrivacyConsentScreen({super.key, this.onConsentAccepted});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Privacidad y Permisos'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Material(
                color: AppColors.mintSoft.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CheckboxListTile(
                    value: _acceptedTerms,
                    activeColor: AppColors.primaryTeal,
                    title: Text(
                      'Entiendo y autorizo el uso efímero de audio y cámara para el asistente culinario.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _acceptedTerms = val ?? false;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _acceptedTerms
                    ? () async {
                        final auth = context.read<AuthProvider>();
                        await auth.acceptPrivacyConsent();
                        if (widget.onConsentAccepted != null) {
                          widget.onConsentAccepted!();
                        } else {
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                ),
                child: const Text('Aceptar y Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
