import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/usuario_service.dart';

class AdministrarRolesScreen extends StatefulWidget {
  const AdministrarRolesScreen({super.key});

  @override
  State<AdministrarRolesScreen> createState() => _AdministrarRolesScreenState();
}

class _AdministrarRolesScreenState extends State<AdministrarRolesScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _cargarUsuarios();
  }

  Future<void> _verificarAutenticacion() async {
    final usuarioActual = FirebaseAuth.instance.currentUser;
    if (usuarioActual == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      // Usando el método del servicio en lugar de acceder directamente a Firestore
      _usuarios = await _usuarioService.cargarUsuariosFirestore();
    } catch (e) {
      print('Error al cargar usuarios: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Roles'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rol')),
              ],
              rows: _usuarios.map((usuario) {
                return DataRow(
                  cells: [
                    DataCell(Text(usuario['email'])),
                    DataCell(Text(usuario['role'])),
                  ],
                  onSelectChanged: (_) {
                    Navigator.pushNamed(
                      context,
                      '/administrar_roles_actualizar',
                      arguments: usuario,
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}