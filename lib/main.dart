import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:testflutter/config/database_helper.dart';
import 'package:testflutter/config/service_locator.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';
import 'package:testflutter/presentation/routes/app_router.dart';

// 🎨 Global theme notifier
final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

Future<void> _initializeApp() async {
  try {
    print('[INFO] Starting initialization...');

    // Load environment variables from .env file
    await dotenv.load(fileName: '.env');
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (geminiApiKey.isEmpty) {
      print('[WARNING] GEMINI_API_KEY is missing. Add it to your .env file.');
    }

    // Initialize Database for non-web platforms
    Database? database;
    if (!kIsWeb) {
      print('[INFO] Initializing SQLite database...');
      database = await DatabaseHelper().database;
      print('[INFO] Database initialized successfully');
    } else {
      print('[INFO] Running on web - using SharedPreferences');
    }

    // Setup service locator
    print('[INFO] Setting up service locator...');
    await setupServiceLocator(database, geminiApiKey);
    print('[INFO] Service Locator initialized successfully');

    // REST API check via dio + interceptor (optional - won't block if offline)
    // ⚠️ SKIP this on offline mode to avoid blocking initialization
    try {
      // Only try if we have internet (do a quick DNS check or skip entirely for offline-first)
      // For now, skip to allow offline-first operation
      print('[INFO] Skipping REST API check (offline-first mode)');
    } catch (e) {
      print('[WARNING] REST API check failed (likely offline): $e');
    }
    
    // Test if NoteBloc can be retrieved
    print('[INFO] Testing NoteBloc instantiation...');
    final bloc = getIt<NoteBloc>();
    print('[INFO] NoteBloc retrieved successfully: $bloc');
    
  } catch (e, stacktrace) {
    print('[ERROR] Initialization failed: $e');
    print('[STACKTRACE] $stacktrace');
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(
      BlocProvider<NoteBloc>.value(
        value: getIt<NoteBloc>(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        title: 'Smart Vision Journal',
        home: Scaffold(
          appBar: AppBar(title: const Text('Smart Vision Journal')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Initialization Error: $e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final AppRouter _appRouter = AppRouter();

  /// Get system font family for offline support
  /// Returns platform-specific system font that doesn't require network download
  static String _getFontFamily() {
    if (kIsWeb) {
      // Web fallback: use system fonts instead of Google Fonts
      return '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
    } else {
      // Mobile: use system default
      return 'Roboto'; // Android has Roboto built-in, iOS uses system font
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDarkMode, child) {
        final baseScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        );

        return MaterialApp.router(
          title: 'Smart Vision Journal',
          theme: ThemeData(
            colorScheme: baseScheme,
            useMaterial3: true,
            fontFamily: _getFontFamily(),
            scaffoldBackgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7F4),
            appBarTheme: AppBarTheme(
              backgroundColor: baseScheme.surface,
              foregroundColor: baseScheme.onSurface,
              centerTitle: false,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: baseScheme.outlineVariant),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: baseScheme.primary,
              foregroundColor: baseScheme.onPrimary,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: baseScheme.surfaceContainerHighest,
              labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
              hintStyle: TextStyle(color: baseScheme.onSurfaceVariant.withValues(alpha: 0.8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: baseScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: baseScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: baseScheme.primary, width: 1.5),
              ),
            ),
          ),
          routerConfig: MyApp._appRouter.config(),
        );
      },
    );
  }
}

