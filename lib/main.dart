import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PUConnectionApp());
}

class PUConnectionApp extends StatelessWidget {
  const PUConnectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PU Connection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Welcome to PU Connection!')),
      ),
    );
  }
}
