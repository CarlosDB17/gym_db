import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigation/app_routes.dart';
import 'theme/app_colors.dart';
import 'utils/session_manager.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  // Cargar las variables de entorno
  await dotenv.load(fileName: "config.env");
  //print('API Key: ${dotenv.env['FIREBASE_API_KEY']}');

  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase con las variables de entorno
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: "1:302016834907:android:e1859d26cbc7663fcb7e7e",
      messagingSenderId: "302016834907",
      projectId: "pf25-carlos-db",
    ),
  );

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
