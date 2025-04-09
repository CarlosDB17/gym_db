import 'package:flutter/material.dart';
import '../../utils/session_manager.dart'; // Importa SessionManager

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await SessionManager.cerrarSesion(); // Elimina la sesión activa
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // Redirige al login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text('Ajustes'),
  automaticallyImplyLeading: false, // Desactiva la flecha de retroceso
),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _cerrarSesion(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Botón de color rojo
          ),
          child: const Text('Cerrar sesión'),
        ),
      ),
    );
  }
}