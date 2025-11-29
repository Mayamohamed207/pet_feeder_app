import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/pet_feeder_screen.dart';
import 'screens/history_screen.dart';

class Routes {
  static const String home = '/home';
  static const String feed = '/feed';
  static const String monitor = '/monitor';
  static const String history = '/history';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => HomeScreen(),
      feed: (context) => PetFeederScreen(),
      history: (context) => HistoryScreen(),
    };
  }
}
