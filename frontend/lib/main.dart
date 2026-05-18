import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/template_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ranking_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
//import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
// import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        if (status == AuthStatus.checking) return null;
        final isAuth = status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == '/login'            ||
                            state.matchedLocation == '/register'         ||
                            state.matchedLocation == '/welcome'          ||
                            state.matchedLocation == '/forgot-password';
        if (!isAuth && !isAuthRoute) return '/welcome';
        if (isAuth  && isAuthRoute)  return '/home';
        if (isAuth  && state.matchedLocation == '/') return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/',                builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/welcome',         builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: '/login',           builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register',        builder: (_, _) => const RegisterScreen()),
        // GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
        GoRoute(path: '/home',            builder: (_, _) => const HomeScreen()),
        // GoRoute(path: '/create-task',     builder: (_, _) => const CreateTaskScreen()),
        GoRoute(
          path: '/task/:id',
          builder: (_, state) => TaskDetailScreen(
            taskId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(path: '/profile',         builder: (_, _) => const ProfileScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el SettingsProvider para cambiar el tema reactivamente
    final isDark = context.select<SettingsProvider, bool>(
      (s) => s.isDarkTheme,
    );

    return MaterialApp.router(
      title:                    'Focus App',
      debugShowCheckedModeBanner: false,
      routerConfig:             _router,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode:                isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}