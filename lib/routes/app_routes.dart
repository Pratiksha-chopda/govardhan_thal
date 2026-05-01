import 'package:flutter/material.dart';
import '../features/main/main_screen.dart';

class AppRoutes {
  // static const splash = '/';
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    // splash: (context) => const SplashScreen(),
    // home: (context) => const HomeScreen(),
    home: (context) => const MainScreen(),
  };
}
