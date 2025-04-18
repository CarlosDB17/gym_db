import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/usuario.dart';
import '../../../services/usuario_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/campo_texto_personalizado.dart';
import '../../../widgets/boton_verde_personalizado.dart';
import '../../../widgets/boton_naranja_personalizado.dart';

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

  String _formatearFecha(String fecha) {
    final partes = fecha.split('-');
    if (partes.length == 3) {
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    }
    return fecha; // devuelve la fecha original si no tiene el formato esperado
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      _usuario = ModalRoute.of(context)!.settings.arguments as Usuario;
      _nombreController.text = _usuario!.nombre;
      _emailController.text = _usuario!.email;
      _documentoIdentidadController.text = _usuario!.documentoIdentidad;
      _fechaNacimientoController.text = _formatearFecha(_usuario!.fechaNacimiento);
      _tieneFoto = _usuario!.foto != null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Actualizar Usuario: ${_usuario!.nombre}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.verdeVibrante,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _seleccionarFoto,
                    child: Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(51), 
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3), 
                                ),
                              ],
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _nuevaFoto != null
                                  ? FileImage(_nuevaFoto!)
                                  : (_usuario!.foto != null
                                      ? NetworkImage(_usuario!.foto!) as ImageProvider
                                      : const AssetImage('assets/images/default_avatar.png')),
                            ),
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
                      // obtener la fecha actual del usuario del controlador
                      final String fechaActual = _fechaNacimientoController.text;
                      
                      // convertir la fecha en formato DD-MM-YYYY a un objeto DateTime
                      DateTime fechaInicial = DateTime.now();
                      if (fechaActual.isNotEmpty) {
                        final List<String> partes = fechaActual.split('-');
                        if (partes.length == 3) {
                          try {
                            fechaInicial = DateTime(
                              int.parse(partes[2]), 
                              int.parse(partes[1]), 
                              int.parse(partes[0]), 
                            );
                          } catch (e) {
                            // si hay un error de parseo, usar la fecha actual
                            print('Error al convertir la fecha: $e');
                          }
                        }
                      }
                      
                      final DateTime? fechaSeleccionada = await showDatePicker(
                        context: context,
                        initialDate: fechaInicial,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (fechaSeleccionada != null) {
                        setState(() {
                          _fechaNacimientoController.text =
                            '${fechaSeleccionada.day.toString().padLeft(2, '0')}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.year}';
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
                      icono: Icons.sync_outlined, 
                      isLoading: _estaCargando,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_tieneFoto || _nuevaFoto != null)
                        BotonNaranjaPersonalizado(
                          onPressed: _eliminarFoto,
                          texto: 'Eliminar Foto',
                          icono: Icons.delete_forever,
                        ),
                      BotonNaranjaPersonalizado(
                        onPressed: _mostrarDialogoConfirmacion,
                        texto: 'Eliminar Usuario',
                        icono: Icons.person_remove,
                      ),
                    ],
                  ),
                ],
              ),
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

Future<void> _actualizarUsuario() async {
  setState(() => _estaCargando = true);

  try {
    final String nuevoNombre = _nombreController.text.trim();
    final String nuevoEmail = _emailController.text.trim();
    final String nuevoDocumentoIdentidad =
        _documentoIdentidadController.text.trim();
    final String nuevaFechaNacimientoFormateada =
        _fechaNacimientoController.text.trim();
        
    // convertir la fecha formateada al formato original para comparar correctamente
    final String nuevaFechaNacimiento = _convertirFormatoFecha(nuevaFechaNacimientoFormateada);

    if (nuevoNombre.isEmpty ||
        nuevoEmail.isEmpty ||
        nuevoDocumentoIdentidad.isEmpty ||
        nuevaFechaNacimientoFormateada.isEmpty) {
      _mostrarSnackBar('Por favor, completa todos los campos.');
      setState(() => _estaCargando = false);
      return;
    }

    final RegExp regexDocumento = RegExp(r'^[a-zA-Z0-9]{6,15}$');
    if (!regexDocumento.hasMatch(nuevoDocumentoIdentidad)) {
      _mostrarSnackBar(
          'El documento de identidad debe ser alfanumérico y tener entre 6 y 15 caracteres.');
      setState(() => _estaCargando = false);
      return;
    }

    // verificar si se hicieron cambios
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

    // crear un mapa con solo los campos que se van a actualizar
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
      camposActualizados['documento_identidad'] = nuevoDocumentoIdentidad; 
    }

    
    
    String? urlFoto;
    if (_nuevaFoto != null) {
      urlFoto = await _usuarioService.subirFoto(
        _usuario!.documentoIdentidad, _nuevaFoto!);
      camposActualizados['foto'] = urlFoto;
    }

    // verificar quehizo cambios
    if (camposActualizados.isEmpty) {
      _mostrarSnackBar('No se proporcionaron datos para actualizar.');
      setState(() => _estaCargando = false);
      return;
    }

    // actualizar el usuario
    await _usuarioService.actualizarUsuario(
      _usuario!.documentoIdentidad, // documento actual
      camposActualizados, // campos actualizados, incluyendo el nuevo documento
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
  String mensajeError = 'Error al actualizar el usuario';
  
  // Extraer el mensaje de error desde la excepción
  if (e.toString().contains('Exception:')) {
    mensajeError = e.toString().replaceAll('Exception: ', '');
  } else {
    mensajeError = e.toString();
  }
  
  _mostrarSnackBar(mensajeError);
} finally {
  if (mounted) {
    setState(() => _estaCargando = false);
  }
}
}

// añadir este metodo para convertir del formato mostrado (DD-MM-YYYY) al formato almacenado (YYYY-MM-DD)
String _convertirFormatoFecha(String fechaFormateada) {
  final partes = fechaFormateada.split('-');
  if (partes.length == 3) {
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }
  return fechaFormateada;
}

  Future<void> _eliminarFoto() async {
    setState(() => _estaCargando = true);
    
    try {
      if (_nuevaFoto != null) {
        // solo eliminar la nueva foto seleccionada sin llamar a la API
        setState(() {
          _nuevaFoto = null;
        });
      } else if (_usuario!.foto != null) {
        // eliminar foto del servidor
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
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarSnackBar('Error al eliminar la foto: $e');
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
      
      // volver a la pantalla anterior y actualizar la lista
      Navigator.pop(context, true);
      print('Usuario actualizado y regresando con true');
    } catch (e) {
      _mostrarSnackBar('Error al eliminar el usuario: $e');
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

  void _mostrarSnackBar(String mensaje, {Color color = AppColors.naranjaOscuro}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
        ),
      );
    }
  }

  // ignore: unused_element (si se usa, en el on tap del boton)
  Future<void> _manejarSeleccionFoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: source);
    if (imagen != null) {
      setState(() {
        _nuevaFoto = File(imagen.path);
      });
    }
  }
}
