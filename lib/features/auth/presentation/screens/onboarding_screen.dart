import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../repositories/auth_repository.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.menu_book_rounded,
      'title': 'La Despensa Culinaria',
      'description':
          'Explora recetas deliciosas y adapta las cantidades de ingredientes al instante según el número de comensales.',
      'badge': 'Paso 1 de 3',
    },
    {
      'icon': Icons.outdoor_grill_rounded,
      'title': 'Guía Paso a Paso',
      'description':
          'Cocina con tranquilidad. Instrucciones en texto grande, pantalla siempre encendida y foco en un paso a la vez.',
      'badge': 'Paso 2 de 3',
    },
    {
      'icon': Icons.timer_rounded,
      'title': 'Mis Tiempos y el Chef IA',
      'description':
          'Controla múltiples temporizadores en paralelo con alertas en segundo plano y habla con el Chef Gemini Live.',
      'badge': 'Paso 3 de 3',
    },
  ];

  void _finishOnboarding() async {
    await LocalAuthRepository.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Saltar',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.highlightYellow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.outlineDark, width: 2),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: AppTypography.badge,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.outlineDark, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.outlineDark.withValues(alpha: 0.15),
                                offset: const Offset(4, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 72,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            slide['description'] as String,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.primaryTeal
                          : AppColors.mintMedium,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.outlineDark, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  if (_currentIndex == _slides.length - 1) {
                    _finishOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _currentIndex == _slides.length - 1
                      ? '¡A cocinar!'
                      : 'Siguiente',
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
