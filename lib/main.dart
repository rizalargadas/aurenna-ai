import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/app_themes.dart';
import 'config/supabase.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const AurennaApp());
}

class AurennaApp extends StatelessWidget {
  const AurennaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const _MaterialAppWithTheme(),
    );
  }
}

class _MaterialAppWithTheme extends StatefulWidget {
  const _MaterialAppWithTheme();

  @override
  State<_MaterialAppWithTheme> createState() => _MaterialAppWithThemeState();
}

class _MaterialAppWithThemeState extends State<_MaterialAppWithTheme> {
  ThemeData? _cachedTheme;
  AppThemeType? _lastThemeType;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Only rebuild theme if it actually changed
        if (_lastThemeType != themeProvider.currentTheme || _cachedTheme == null) {
          try {
            _cachedTheme = AurennaTheme.buildTheme(themeProvider.themeData);
            _lastThemeType = themeProvider.currentTheme;
          } catch (e) {
            // Fallback to default theme if theme building fails
            _cachedTheme = AurennaTheme.buildTheme(AppThemes.aurennaTheme);
            _lastThemeType = AppThemeType.aurenna;
          }
        }
        
        return MaterialApp(
          title: 'Aurenna AI',
          theme: _cachedTheme!,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
