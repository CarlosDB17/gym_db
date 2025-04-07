import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigation/app_routes.dart';
import 'theme/app_colors.dart';
import 'utils/session_manager.dart'; // Importa SessionManager

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Verificar si la sesión está activa
  final bool sesionActiva = await SessionManager.verificarSesionActiva();

  runApp(MyApp(sesionActiva: sesionActiva));
}

class MyApp extends StatelessWidget {
  final bool sesionActiva;

  const MyApp({super.key, required this.sesionActiva});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYM DB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.naranjaBrillante),
      ),
      // Define la ruta inicial según el estado de la sesión
      initialRoute: sesionActiva ? AppRoutes.menu : AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}