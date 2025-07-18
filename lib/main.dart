import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'config/environment.dart';

void main() {
  // Set environment
  Environment.flavor = BuildFlavor.production; // or BuildFlavor.development
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final initializationProvider = FutureProvider<void>((ref) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // await Supabase.initialize(
  //   url: SupabaseConfig.url,
  //   anonKey: SupabaseConfig.anonKey,
  // );

  // Initialize Notifications
  await SupabaseConfig.initialize();
  await NotificationService.initialize();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(initializationProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Decreme App',
      debugShowCheckedModeBanner: settingsAsync.when(
        loading: () => false,
        error: (_, __) => false,
        data: (settings) => settings['is_demo_mode'] == 'true',
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      home: initialization.when(
        loading: () => const SplashScreen(),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
        data: (_) => const AuthWrapper(),
      ),
      // Define routes for navigation
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          default:
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
        }
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.initial:
      case AuthStatus.error:
      default:
        return const LoginScreen();
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decreme Cake Order App'),
      ),
      body: const Center(
        child: Text('Welcome to Decreme Cake Order App'),
      ),
    );
  }
}
