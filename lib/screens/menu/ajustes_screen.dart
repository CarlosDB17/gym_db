import 'package:flutter/material.dart';
import '../../utils/session_manager.dart'; 
import '../../widgets/boton_naranja_personalizado.dart'; 

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await SessionManager.cerrarSesion(); // elimina la sesion activa
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // redirige al login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BotonNaranjaPersonalizado(
          onPressed: () => _cerrarSesion(context),
          texto: 'Cerrar sesión',
          icono: Icons.logout, 
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
    );
  }
}