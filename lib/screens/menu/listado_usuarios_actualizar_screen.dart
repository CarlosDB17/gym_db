import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/campo_texto_personalizado.dart';

class ListadoUsuariosActualizarScreen extends StatefulWidget {
  const ListadoUsuariosActualizarScreen({super.key});

  @override
  _ListadoUsuariosActualizarScreenState createState() =>
      _ListadoUsuariosActualizarScreenState();
}

class _ListadoUsuariosActualizarScreenState
    extends State<ListadoUsuariosActualizarScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoIdentidadController =
      TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  File? _nuevaFoto;

  Usuario? _usuario;

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      _usuario = ModalRoute.of(context)!.settings.arguments as Usuario;
      _nombreController.text = _usuario!.nombre;
      _emailController.text = _usuario!.email;
      _documentoIdentidadController.text = _usuario!.documentoIdentidad;
      _fechaNacimientoController.text = _usuario!.fechaNacimiento;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar Usuario: ${_usuario!.nombre}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _seleccionarFoto,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _nuevaFoto != null
                      ? FileImage(_nuevaFoto!)
                      : (_usuario!.foto != null
                          ? NetworkImage(_usuario!.foto!) as ImageProvider
                          : const AssetImage('assets/images/default_avatar.png')),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CampoTextoPersonalizado(
              controlador: _nombreController,
              texto: 'Nombre',
            ),
            const SizedBox(height: 20),
            CampoTextoPersonalizado(
              controlador: _emailController,
              texto: 'Email',
            ),
            const SizedBox(height: 20),
            CampoTextoPersonalizado(
              controlador: _documentoIdentidadController,
              texto: 'Documento de Identidad',
            ),
            const SizedBox(height: 20),
            CampoTextoPersonalizado(
              controlador: _fechaNacimientoController,
              texto: 'Fecha de Nacimiento',
              alTocar: () async {
                final DateTime? fechaSeleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (fechaSeleccionada != null) {
                  _fechaNacimientoController.text =
                      fechaSeleccionada.toIso8601String().split('T').first;
                }
              },
              soloLectura: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _actualizarUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranjaBrillante,
                foregroundColor: AppColors.blanco,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Center(child: Text('Actualizar Usuario')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarUsuario() async {
    try {
      final String nuevoNombre = _nombreController.text.trim();
      final String nuevoEmail = _emailController.text.trim();
      final String nuevoDocumentoIdentidad =
          _documentoIdentidadController.text.trim();
      final String nuevaFechaNacimiento =
          _fechaNacimientoController.text.trim();

      if (nuevoNombre.isEmpty ||
          nuevoEmail.isEmpty ||
          nuevoDocumentoIdentidad.isEmpty ||
          nuevaFechaNacimiento.isEmpty) {
        _mostrarMensajeError('Por favor, completa todos los campos.');
        return;
      }

      if (nuevoDocumentoIdentidad != _usuario!.documentoIdentidad) {
        final existe = await _usuarioService
            .verificarUsuarioExistente(nuevoDocumentoIdentidad);
        if (existe) {
          _mostrarMensajeError('El documento de identidad ya está registrado.');
          return;
        }
      }

      final actualizado = await _usuarioService.actualizarUsuarioParcial(
        _usuario!.documentoIdentidad,
        nombre: nuevoNombre,
        email: nuevoEmail,
        fechaNacimiento: nuevaFechaNacimiento,
        foto: _nuevaFoto != null
            ? await _usuarioService.subirFoto(
                _usuario!.documentoIdentidad, _nuevaFoto!)
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado correctamente.')),
      );

      Navigator.pop(context, actualizado);
    } catch (e) {
      _mostrarMensajeError('Error al actualizar el usuario: $e');
    }
  }

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _nuevaFoto = File(imagen.path);
      });
    }
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.naranjaOscuro,
      ),
    );
  }
}
