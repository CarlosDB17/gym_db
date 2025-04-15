import 'package:flutter/material.dart';
import '../../../utils/session_manager.dart'; 
import '../../../services/usuario_service.dart';
import '../../../widgets/ventana_emergente_salida.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String userRole = 'user';

  @override
  void initState() {
    super.initState();
    _obtenerRolUsuario();
  }

  Future<void> _obtenerRolUsuario() async {
    try {
      User? usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null && usuarioActual.email != null) {
        String? rol = await UsuarioService().obtenerRolUsuarioPorEmail(usuarioActual.email!);
        if (rol != null) {
          setState(() {
            userRole = rol;
          });
        }
      }
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    VentanaEmergenteSalida.mostrar(
      context: context,
      titulo: '¿Cerrar sesión?',
      subtitulo: '¿Estás seguro que deseas cerrar tu sesión?',
      botonAfirmativo: 'Cerrar sesión',
      botonNegativo: 'Cancelar',
      onAccion: () async {
        await SessionManager.cerrarSesion();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
      body: ListView(
        children: [
          if (userRole == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administrar roles'),
              onTap: () {
                Navigator.pushNamed(context, '/administrar_roles');
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => _cerrarSesion(context),
          ),
        ],
      ),
    );
  }
}