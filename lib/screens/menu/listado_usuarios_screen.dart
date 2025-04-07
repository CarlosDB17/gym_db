
import 'package:flutter/material.dart';

class ListadoUsuariosScreen extends StatelessWidget {
  const ListadoUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text('Listado de Usuarios'),
  automaticallyImplyLeading: false, // Desactiva la flecha de retroceso
),
      body: const Center(child: Text('Pantalla de Listado de Usuarios')),

    );
  }
}
