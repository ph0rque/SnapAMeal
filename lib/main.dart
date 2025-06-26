import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:snapameal/pages/auth_gate.dart';
import 'package:snapameal/themes/light_mode.dart';
import 'package:snapameal/themes/dark_mode.dart';
import 'package:camera/camera.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/services/fasting_service.dart';
import 'package:snapameal/services/content_filter_service.dart';
import 'package:snapameal/services/notification_service.dart';
import 'package:snapameal/providers/fasting_state_provider.dart';
import 'package:snapameal/widgets/fasting_aware_navigation.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize cameras on mobile platforms
  if (defaultTargetPlatform == TargetPlatform.android || 
      defaultTargetPlatform == TargetPlatform.iOS) {
    cameras = await availableCameras();
  } else {
    cameras = [];
  }

  await dotenv.load(fileName: ".env");

  final FirebaseOptions firebaseOptions;

  if (defaultTargetPlatform == TargetPlatform.android) {
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
      appId: dotenv.env['FIREBASE_APP_ID_ANDROID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
      appId: dotenv.env['FIREBASE_APP_ID_IOS']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']!,
    );
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    // Use iOS configuration for macOS
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
      appId: dotenv.env['FIREBASE_APP_ID_IOS']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']!,
    );
  } else {
    throw UnsupportedError("Platform not supported");
  }

  // Check if Firebase is already initialized
  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  } catch (e) {
    // Firebase is already initialized, which is fine
    if (e.toString().contains('duplicate-app')) {
      // This is expected in some cases, continue silently
    } else {
      rethrow;
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        
        // Fasting-related services with dependencies
        Provider<FastingService>(
          create: (context) => FastingService(
            context.read<AuthService>(),
            context.read<NotificationService>(),
          ),
        ),
        Provider<ContentFilterService>(
          create: (context) => ContentFilterService(
            openAIService: context.read<OpenAIService>(),
            ragService: context.read<RAGService>(),
          ),
        ),
        
        // Fasting state provider that manages app-wide fasting state
        ChangeNotifierProvider<FastingStateProvider>(
          create: (context) => FastingStateProvider(
            fastingService: context.read<FastingService>(),
            contentFilterService: context.read<ContentFilterService>(),
          ),
        ),
      ],
      child: Consumer<FastingStateProvider>(
        builder: (context, fastingState, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: fastingState.appBarTitle,
            
            // Dynamic theme based on fasting state
            theme: fastingState.fastingModeEnabled 
                ? _buildFastingTheme(lightMode, fastingState.appThemeColor)
                : lightMode,
            darkTheme: fastingState.fastingModeEnabled
                ? _buildFastingTheme(darkMode, fastingState.appThemeColor)
                : darkMode,
            
            // Wrap the entire app with fasting-aware navigation
            home: FastingAwareNavigation(
              adaptiveTheme: true,
              showFloatingTimer: true,
              child: const AuthGate(),
            ),
            
            // Route generation with fasting protection
            onGenerateRoute: (settings) => _generateRoute(settings, fastingState),
            
            // Handle initial route with fasting context
            initialRoute: '/',
          );
        },
      ),
    );
  }

  /// Build fasting-adapted theme
  ThemeData _buildFastingTheme(ThemeData baseTheme, Color fastingColor) {
    return baseTheme.copyWith(
      primaryColor: fastingColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: fastingColor,
        secondary: fastingColor.withOpacity(0.7),
        surface: fastingColor.withOpacity(0.05),
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: fastingColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fastingColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: fastingColor,
      ),
      progressIndicatorTheme: baseTheme.progressIndicatorTheme.copyWith(
        color: fastingColor,
      ),
    );
  }

  /// Generate routes with fasting protection
  Route<dynamic>? _generateRoute(RouteSettings settings, FastingStateProvider fastingState) {
    // Import the route guard utility
    // Note: You'll need to import the utils/fasting_route_guard.dart file
    
    final routeName = settings.name ?? '/';
    
    // Get the base route without fasting protection first
    Widget? page = _getBasePage(routeName, settings.arguments);
    
    if (page == null) {
      return _createRoute(_buildNotFoundPage(), settings);
    }

    // Apply fasting protection if needed
    // This would use the FastingRouteGuard.wrapPage method
    // For now, we'll return the page as-is since the full implementation
    // would require importing all page widgets
    
    return _createRoute(page, settings);
  }

  /// Get base page widget for route
  Widget? _getBasePage(String routeName, Object? arguments) {
    switch (routeName) {
      case '/':
        return const AuthGate();
      case '/home':
        // Import and return HomePage
        return const AuthGate(); // Placeholder
      case '/fasting-timer':
        // Import and return fasting timer page
        return const AuthGate(); // Placeholder
      case '/health-dashboard':
        // Import and return health dashboard
        return const AuthGate(); // Placeholder
      default:
        return null;
    }
  }

  /// Create route with custom transition
  Route<dynamic> _createRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Custom transition that respects fasting mode
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Build not found page
  Widget _buildNotFoundPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelloWorldPage extends StatelessWidget {
  const HelloWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapConnect'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/images/image.png'),
            const SizedBox(height: 20),
            Text(
              'Hello Gauntlet world',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'flutter + firebase (coming soon)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
