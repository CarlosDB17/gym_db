import 'package:flutter/material.dart';
import 'package:gym_db/models/usuario.dart';
import 'package:gym_db/screens/auth/login_screen.dart';
import 'package:gym_db/screens/menu/menu_screen.dart';
import 'package:gym_db/screens/menu/listado_usuarios_actualizar_screen.dart'; // Importa la pantalla

class AppRoutes {
  static const String login = '/';
  static const String menu = '/menu';
  static const String listadoUsuariosActualizar = '/listado_usuarios_actualizar'; // Define la constante

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case listadoUsuariosActualizar: // Agrega la nueva ruta
        final usuario = settings.arguments as Usuario; // Obtén los argumentos
        return MaterialPageRoute(
          builder: (_) => ListadoUsuariosActualizarScreen(),
          settings: RouteSettings(arguments: usuario), // Pasa los argumentos
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}