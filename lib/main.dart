import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/app_logger.dart';
import 'data/services/auth_service.dart';
import 'data/services/local_storage_service.dart';
import 'features/auth/login_page.dart';
import 'features/home/main_navigation_page.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('Environment variables loaded');
  } catch (e) {
    AppLogger.error('Failed to load .env file', error: e);
    // Continue with empty env, will fail gracefully later
  }

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    AppLogger.info('Supabase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase', error: e);
    // Show error screen on startup
    runApp(const RoamQuestErrorScreen(
      error: 'Failed to connect to servers. Please check your connection.',
    ));
    return;
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const RoamQuestApp());
}

/// Main application widget with auth state management
class RoamQuestApp extends StatefulWidget {
  const RoamQuestApp({super.key});

  @override
  State<RoamQuestApp> createState() => _RoamQuestAppState();
}

class _RoamQuestAppState extends State<RoamQuestApp> {
  final AuthService _auth = AuthService();
  final LocalStorageService _localStorage = LocalStorageService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoamQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      locale: const Locale('en'), // Default to English
      home: StreamBuilder<AuthState>(
        stream: _auth.authStateChanges,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _AuthLoadingScreen();
          }

          if (snapshot.hasError) {
            return _ErrorScreen(error: snapshot.error.toString());
          }

          final session = snapshot.data?.session;

          // Handle auth state change
          _handleAuthStateChange(session);

          // Not authenticated - show login
          if (session == null) {
            return const LoginPage();
          }

          // Authenticated - go to home with bottom navigation
          return const MainNavigationPage();
        },
      ),
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling beyond 1.3 for better UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Handle auth state change to set/clear user ID for data isolation
  void _handleAuthStateChange(Session? session) {
    if (session != null && session.user != null) {
      // User is logged in - set user ID for data isolation
      _localStorage.setUserId(session.user.id).then((_) {
        AppLogger.info('User ID set for data isolation: ${session.user.id}');
      }).catchError((e) {
        AppLogger.error('Failed to set user ID', error: e);
      });
    } else {
      // User is logged out - clear user ID
      _localStorage.clearUserId().then((_) {
        AppLogger.info('User ID cleared on logout');
      }).catchError((e) {
        AppLogger.error('Failed to clear user ID', error: e);
      });
    }
  }
}

/// Loading screen for auth state check
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore,
                  size: 80,
                  color: AppColors.textOnDark,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  color: AppColors.textOnDark,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textOnDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error screen for auth errors
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connection Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to connect to server',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by reloading
                      if (kIsWeb) {
                        // Force page reload
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Reload'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error screen for startup failures
class RoamQuestErrorScreen extends StatelessWidget {
  final String error;

  const RoamQuestErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoamQuest Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Initialization Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // Restart app
                        try {
                          SupabaseConfig.initialize().then((_) {
                            runApp(const RoamQuestApp());
                          });
                        } catch (e) {
                          // Retry failed
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
