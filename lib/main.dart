import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(PetParadiseApp());
}

class PetParadiseApp extends StatelessWidget {
  const PetParadiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Paradise',
      theme: AppTheme.mainTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        ...Routes.getRoutes(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
