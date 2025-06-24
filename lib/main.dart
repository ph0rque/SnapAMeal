import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/pages/auth_gate.dart';
import 'package:snapameal/themes/light_mode.dart';
import 'package:snapameal/themes/dark_mode.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
