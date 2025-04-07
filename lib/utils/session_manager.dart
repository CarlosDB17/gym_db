import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> guardarSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesion_iniciada', true);
  }

  static Future<bool> verificarSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sesion_iniciada') ?? false;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sesion_iniciada');
  }
}