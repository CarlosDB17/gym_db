import 'package:flutter/material.dart';
import 'package:gym_db/models/usuario.dart';
import 'package:gym_db/screens/auth/login_screen.dart';
import 'package:gym_db/screens/menu/menu_screen.dart';
import 'package:gym_db/screens/menu/listado_usuarios_actualizar_screen.dart';
import '../screens/menu/administrar_roles_screen.dart';
import '../screens/menu/administrar_roles_actualizar_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String menu = '/menu';
  static const String listadoUsuariosActualizar = '/listado_usuarios_actualizar';
  static const String administrarRoles = '/administrar_roles';
  static const String administrarRolesActualizar = '/administrar_roles_actualizar';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case listadoUsuariosActualizar:
        // Aquí esperamos un objeto Usuario (de los usuarios que registras)
        final usuario = settings.arguments as Usuario;
        return MaterialPageRoute(
          builder: (_) => ListadoUsuariosActualizarScreen(),
          settings: RouteSettings(arguments: usuario),
        );
      case administrarRoles:
        return MaterialPageRoute(builder: (_) => const AdministrarRolesScreen());
      case administrarRolesActualizar:
        // Aquí esperamos un Map<String, dynamic> (de la colección users de Firebase)
        // No intentamos convertirlo a Usuario
        return MaterialPageRoute(
          builder: (_) => const AdministrarRolesActualizarScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}