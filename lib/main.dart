import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/recipes/repositories/recipe_repository.dart';
import 'features/recipes/providers/recipe_provider.dart';
import 'features/cooking/repositories/cooking_repository.dart';
import 'features/cooking/services/notification_service.dart';
import 'features/cooking/providers/timer_provider.dart';
import 'features/cooking/providers/cooking_session_provider.dart';
import 'features/ai_assistant/providers/ai_chef_provider.dart';
import 'features/home/presentation/screens/home_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepo = LocalAuthRepository();
  final recipeRepo = LocalRecipeRepository();
  final cookingRepo = CookingRepository();
  final notificationService = LocalCookingNotificationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => RecipeProvider(recipeRepo)),
        ChangeNotifierProvider(
          create: (_) => TimerProvider(
            repository: cookingRepo,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CookingSessionProvider(repository: cookingRepo),
        ),
        ChangeNotifierProvider(create: (_) => AiChefProvider()),
      ],
      child: const ComiApp(),
    ),
  );
}

class ComiApp extends StatelessWidget {
  const ComiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(
        homeTarget: HomeShellScreen(),
      ),
    );
  }
}
