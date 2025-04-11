import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdministrarRolesActualizarScreen extends StatefulWidget {
  const AdministrarRolesActualizarScreen({super.key});

  @override
  State<AdministrarRolesActualizarScreen> createState() => _AdministrarRolesActualizarScreenState();
}

class _AdministrarRolesActualizarScreenState extends State<AdministrarRolesActualizarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _rolController = TextEditingController();
  Map<String, dynamic>? _usuario;
  bool _estaCargando = false;

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      _usuario = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _rolController.text = _usuario!['role'] ?? 'user';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar Rol: ${_usuario!['email']}'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _rolController,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _estaCargando ? null : _actualizarRol,
                    child: _estaCargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),
          if (_estaCargando)
            Container(
              color: Colors.black.withAlpha(76),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _actualizarRol() async {
    setState(() => _estaCargando = true);

    try {
      final nuevoRol = _rolController.text.trim();
      if (nuevoRol.isEmpty || nuevoRol == _usuario!['role']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se realizaron cambios o el campo está vacío.'),
            backgroundColor: Colors.grey,
          ),
        );
        setState(() => _estaCargando = false);
        return;
      }

      await _firestore.collection('users').doc(_usuario!['id']).update({'role': nuevoRol});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol actualizado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el rol: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _estaCargando = false);
    }
  }
}