import 'package:flutter/material.dart';
import 'package:gym_db/screens/auth/login_screen.dart';
import 'package:gym_db/screens/menu/menu_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String menu = '/menu';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
