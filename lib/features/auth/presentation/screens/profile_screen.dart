import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import 'privacy_consent_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesión activa')),
      );
    }

    final prefs = user.preferences;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Mi Perfil Culinario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera de usuario
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.mintSoft,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTypography.titleLarge,
                        ),
                        Text(
                          user.email,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.highlightYellow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.outlineDark, width: 1.5),
                          ),
                          child: Text(
                            'Nivel: ${prefs.experience.label}',
                            style: AppTypography.badge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nivel de Experiencia
            Text('Nivel en la Cocina', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: CookingExperience.values.map((exp) {
                final isSelected = prefs.experience == exp;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(exp.label),
                      selected: isSelected,
                      selectedColor: AppColors.accentOrange,
                      backgroundColor: Colors.white,
                      labelStyle: AppTypography.badge.copyWith(
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          auth.updatePreferences(
                            prefs.copyWith(experience: exp),
                          );
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Preferencias Dietéticas
            Text('Preferencias y Dietas', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineDark, width: 2),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Vegetariano'),
                    subtitle: const Text('Excluir recetas con carne o pescado'),
                    value: prefs.isVegetarian,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      auth.updatePreferences(prefs.copyWith(isVegetarian: val));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Vegano'),
                    subtitle: const Text('Excluir todo producto de origen animal'),
                    value: prefs.isVegan,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      auth.updatePreferences(prefs.copyWith(isVegan: val));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sin Gluten'),
                    subtitle: const Text('Apto para personas con celiaquía o intolerancia'),
                    value: prefs.isGlutenFree,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      auth.updatePreferences(prefs.copyWith(isGlutenFree: val));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sin Lácteos'),
                    subtitle: const Text('Sin leche, mantequilla o crema de leche'),
                    value: prefs.isDairyFree,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) {
                      auth.updatePreferences(prefs.copyWith(isDairyFree: val));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Acceso a Privacidad / Habeas Data
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outlineDark, width: 1.5),
              ),
              tileColor: AppColors.mintSoft,
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.primaryTeal),
              title: const Text('Política de Privacidad y Habeas Data'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PrivacyConsentScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Botón cerrar sesión
            OutlinedButton.icon(
              onPressed: () => auth.signOut(),
              icon: const Icon(Icons.logout, color: AppColors.errorCoral),
              label: Text(
                'Cerrar Sesión',
                style: AppTypography.button.copyWith(color: AppColors.errorCoral),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorCoral, width: 2),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
