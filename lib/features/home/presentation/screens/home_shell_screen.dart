import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../recipes/presentation/screens/catalog_screen.dart';
import '../../../cooking/presentation/widgets/global_timer_banner.dart';
import '../../../cooking/presentation/widgets/active_cooking_banner.dart';
import '../../../cooking/presentation/widgets/active_timers_sheet.dart';
import '../../../cooking/presentation/widgets/add_manual_timer_dialog.dart';
import '../../../cooking/providers/timer_provider.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../ai_assistant/presentation/widgets/floating_ai_chef_badge.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final timerProv = context.watch<TimerProvider>();

    final List<Widget> pages = [
      CatalogScreen(
        onOpenTimers: () => setState(() => _currentIndex = 1),
      ),
      const ActiveTimersPage(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          // Banners flotantes globales: Chef IA activa, Receta en curso y Temporizadores
          if (_currentIndex != 1)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingAiChefBadge(),
                  ActiveCookingBanner(),
                  GlobalTimerBanner(),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.outlineDark, width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedLabelStyle: AppTypography.badge,
          unselectedLabelStyle: AppTypography.bodySmall,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              activeIcon: Icon(Icons.menu_book_rounded, color: AppColors.primaryTeal),
              label: 'La Despensa',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: timerProv.hasActiveTimers,
                label: Text('${timerProv.activeTimers.length}'),
                child: const Icon(Icons.timer_rounded),
              ),
              activeIcon: Badge(
                isLabelVisible: timerProv.hasActiveTimers,
                label: Text('${timerProv.activeTimers.length}'),
                child: const Icon(Icons.timer_rounded, color: AppColors.primaryTeal),
              ),
              label: 'Mis Tiempos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.primaryTeal),
              label: 'Mi Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveTimersPage extends StatelessWidget {
  const ActiveTimersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: const SafeArea(
        child: ActiveTimersSheet(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddManualTimerDialog.show(context),
        backgroundColor: AppColors.accentOrange,
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text('Nuevo Temporizador', style: AppTypography.badge),
      ),
    );
  }
}
