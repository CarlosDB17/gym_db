import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../widgets/boton_naranja_personalizado.dart';

class ListadoUsuariosActualizarScreen extends StatefulWidget {
  const ListadoUsuariosActualizarScreen({super.key});

  @override
  State<ListadoUsuariosActualizarScreen> createState() =>
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
  bool _estaCargando = false;
  bool _tieneFoto = false;

  Usuario? _usuario;

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      _usuario = ModalRoute.of(context)!.settings.arguments as Usuario;
      _nombreController.text = _usuario!.nombre;
      _emailController.text = _usuario!.email;
      _documentoIdentidadController.text = _usuario!.documentoIdentidad;
      _fechaNacimientoController.text = _usuario!.fechaNacimiento;
      _tieneFoto = _usuario!.foto != null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar Usuario: ${_usuario!.nombre}'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _seleccionarFoto,
                  child: Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _nuevaFoto != null
                              ? FileImage(_nuevaFoto!)
                              : (_usuario!.foto != null
                                  ? NetworkImage(_usuario!.foto!) as ImageProvider
                                  : const AssetImage('assets/images/default_avatar.png')),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.verdeOscuro,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
                      setState(() {
                        _fechaNacimientoController.text =
                          '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}';
                      });
                    }
                  },
                  soloLectura: true,
                ),
                const SizedBox(height: 30),
                Center(
                  child: BotonVerdePersonalizado(
                    onPressed: _actualizarUsuario,
                    texto: 'Actualizar Usuario',
                    isLoading: _estaCargando,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  ),
                ),
                const SizedBox(height: 20),
                if (_tieneFoto || _nuevaFoto != null)
                  Center(
                    child: BotonNaranjaPersonalizado(
                      onPressed: _eliminarFoto,
                      texto: 'Eliminar Foto',
                      icono: Icons.delete_forever,
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: BotonNaranjaPersonalizado(
                    onPressed: _mostrarDialogoConfirmacion,
                    texto: 'Eliminar Usuario',
                    icono: Icons.person_remove,
                  ),
                ),
              ],
            ),
          ),
          if (_estaCargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

Future<void> _actualizarUsuario() async {
  setState(() => _estaCargando = true);

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
      setState(() => _estaCargando = false);
      return;
    }

    final RegExp regexDocumento = RegExp(r'^[a-zA-Z0-9]{6,15}$');
    if (!regexDocumento.hasMatch(nuevoDocumentoIdentidad)) {
      _mostrarMensajeError(
          'El documento de identidad debe ser alfanumérico y tener entre 6 y 15 caracteres.');
      setState(() => _estaCargando = false);
      return;
    }

    // Verificar si se hicieron cambios
    bool cambiosRealizados = nuevoNombre != _usuario!.nombre ||
        nuevoEmail != _usuario!.email ||
        _nuevaFoto != null ||
        nuevaFechaNacimiento != _usuario!.fechaNacimiento ||
        nuevoDocumentoIdentidad != _usuario!.documentoIdentidad;

    if (!cambiosRealizados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se han realizado cambios.'),
          backgroundColor: Colors.grey,
        ),
      );
      setState(() => _estaCargando = false);
      return;
    }

    // Crear un mapa con solo los campos que se van a actualizar
    Map<String, dynamic> camposActualizados = {};

    if (nuevoNombre != _usuario!.nombre) {
      camposActualizados['nombre'] = nuevoNombre;
    }

    if (nuevoEmail != _usuario!.email) {
      camposActualizados['email'] = nuevoEmail;
    }

    if (nuevaFechaNacimiento != _usuario!.fechaNacimiento) {
      camposActualizados['fechaNacimiento'] = nuevaFechaNacimiento;
    }

    if (nuevoDocumentoIdentidad != _usuario!.documentoIdentidad) {
      camposActualizados['documento_identidad'] = nuevoDocumentoIdentidad; // Cambiar a snake_case
    }

    // Manejar la foto de manera especial
    String? urlFoto;
    if (_nuevaFoto != null) {
      urlFoto = await _usuarioService.subirFoto(
        _usuario!.documentoIdentidad, _nuevaFoto!);
      camposActualizados['foto'] = urlFoto;
    }

    // Verificar que el mapa no esté vacío
    if (camposActualizados.isEmpty) {
      _mostrarMensajeError('No se proporcionaron datos para actualizar.');
      setState(() => _estaCargando = false);
      return;
    }

    // Actualizar el usuario
    await _usuarioService.actualizarUsuario(
      _usuario!.documentoIdentidad, // Documento actual
      camposActualizados, // Campos actualizados, incluyendo el nuevo documento
    );

print('Campos actualizados antes de enviar: $camposActualizados');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario actualizado correctamente.'),
        backgroundColor: AppColors.verdeVibrante,
      ),
    );

    Navigator.pop(context, true);
  } catch (e) {
    _mostrarMensajeError('Error al actualizar el usuario: $e');
  } finally {
    if (mounted) {
      setState(() => _estaCargando = false);
    }
  }
}

  Future<void> _eliminarFoto() async {
    setState(() => _estaCargando = true);
    
    try {
      if (_nuevaFoto != null) {
        // Solo eliminar la nueva foto seleccionada sin llamar a la API
        setState(() {
          _nuevaFoto = null;
        });
      } else if (_usuario!.foto != null) {
        // Eliminar foto del servidor
        await _usuarioService.eliminarFotoUsuario(_usuario!.documentoIdentidad);
        setState(() {
          _usuario = Usuario(
            nombre: _usuario!.nombre,
            email: _usuario!.email,
            documentoIdentidad: _usuario!.documentoIdentidad,
            fechaNacimiento: _usuario!.fechaNacimiento,
            foto: null,
          );
          _tieneFoto = false;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto eliminada correctamente.'),
          backgroundColor: AppColors.verdeVibrante,
        ),
      );
    } catch (e) {
      _mostrarMensajeError('Error al eliminar la foto: $e');
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${_usuario!.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          BotonNaranjaPersonalizado(
            onPressed: () {
              Navigator.pop(context);
              _eliminarUsuario();
            },
            texto: 'Eliminar',
            icono: Icons.delete,
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario() async {
    setState(() => _estaCargando = true);
    
    try {
      await _usuarioService.eliminarUsuario(_usuario!.documentoIdentidad);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado correctamente.'),
          backgroundColor: AppColors.verdeVibrante,
        ),
      );
      
      // Volver a la pantalla anterior y actualizar la lista
      Navigator.pop(context, true);
      print('Usuario actualizado y regresando con true'); // Depuración
    } catch (e) {
      _mostrarMensajeError('Error al eliminar el usuario: $e');
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.naranjaOscuro,
      ),
    );
  }
}
