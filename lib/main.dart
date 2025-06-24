import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:snapameal/pages/auth_gate.dart';
import 'package:snapameal/themes/light_mode.dart';
import 'package:snapameal/themes/dark_mode.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

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
  } else {
    throw UnsupportedError("Platform not supported");
  }

  await Firebase.initializeApp(
    options: firebaseOptions,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapAMeal',
      theme: lightMode,
      darkTheme: darkMode,
      home: const AuthGate(),
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
