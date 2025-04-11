import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/campo_texto_personalizado.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

class RegistroUsuariosScreen extends StatefulWidget {
  const RegistroUsuariosScreen({super.key});

  @override
  State<RegistroUsuariosScreen> createState() => _RegistroUsuariosScreenState();
}

class _RegistroUsuariosScreenState extends State<RegistroUsuariosScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  File? _imagenSeleccionada;
  bool _estaCargando = false; 


  final UsuarioService _usuarioService = UsuarioService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // se reduce un poco la calidad para bajar el tamaño
      );

      if (pickedFile != null) {
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        final List<String> formatosPermitidos = ['png', 'jpg', 'jpeg', 'heic', 'heif'];

        if (!formatosPermitidos.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Formato de imagen no permitido. Use PNG, JPG, JPEG, HEIC o HEIF.'),
                backgroundColor: AppColors.naranjaOscuro,
              ),
            );
          }
          return;
        }

        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });

        print('Imagen seleccionada: ${pickedFile.path}');
        print('Formato: $extension');
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.naranjaOscuro,
          ),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        // verificar formato foto
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        final List<String> formatosPermitidos = ['png', 'jpg', 'jpeg', 'heic', 'heif'];

        if (!formatosPermitidos.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Formato de imagen no permitido. Use PNG, JPG, JPEG, HEIC o HEIF.'),
                backgroundColor: AppColors.naranjaOscuro,
              ),
            );
          }
          return;
        }

        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });

        print('Foto tomada: ${pickedFile.path}');
        print('Formato: $extension');
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: AppColors.naranjaOscuro,
          ),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  // funcion para validar email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _subirFotoUsuario(String documentoIdentidad) async {
    if (_imagenSeleccionada == null) return;

    try {
      print('Iniciando subida de foto para usuario: $documentoIdentidad');
      // pausa para asegurar que el registro se completo
      await Future.delayed(const Duration(milliseconds: 500));

      // verificar si el usuario existe antes de subir la foto
      bool usuarioExiste = await _usuarioService.verificarUsuarioExistente(documentoIdentidad);
      if (!usuarioExiste) {
        print('Error: El usuario $documentoIdentidad no existe para subir la foto');
        throw Exception('El usuario no existe para subir la foto');
      }

      await _usuarioService.subirFoto(documentoIdentidad, _imagenSeleccionada!);
      print('Foto subida correctamente para: $documentoIdentidad');
    } catch (e) {
      print('Error al subir la foto: $e');
      rethrow; // Re-lanzar para manejo externo
    }
  }

  // Función para manejar el registro de usuario
  Future<void> _registrarUsuario() async {
    // Validar los campos
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final documento = _documentoController.text.trim();
    final fechaNacimientoStr = _fechaNacimientoController.text.trim();

    if (nombre.isEmpty ||
        email.isEmpty ||
        documento.isEmpty ||
        fechaNacimientoStr.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todos los campos.'),
            backgroundColor: AppColors.naranjaOscuro,
          ),
        );
      }
      return;
    }

    // Validar formato de email
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un email válido.'),
          backgroundColor: AppColors.naranjaOscuro,
        ),
      );
      return;
    }

    setState(() {
      _estaCargando = true;
    });

    try {
      // formato actual es dd/mm/yyyy y necesitamos yyyy-mm-dd (para firebase)
      final fechaParts = fechaNacimientoStr.split('/');
      if (fechaParts.length != 3) {
        throw Exception('Formato de fecha inválido');
      }

      final fechaNacimiento = '${fechaParts[2]}-${fechaParts[1].padLeft(2, '0')}-${fechaParts[0].padLeft(2, '0')}';
      print('Fecha formateada para API: $fechaNacimiento');

      // verifico si el usuario ya existe
      bool usuarioExiste = await _usuarioService.verificarUsuarioExistente(documento);
      if (usuarioExiste) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe un usuario con ese documento de identidad.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _estaCargando = false;
        });
        return;
      }

      // Registrar usuario
      try {
        final usuario = Usuario(
          nombre: nombre,
          email: email,
          documentoIdentidad: documento,
          fechaNacimiento: fechaNacimiento,
        );

        print('Intentando registrar usuario con datos: ${usuario.toJson()}');
        Usuario usuarioRegistrado = await _usuarioService.registrarUsuario(usuario);
        String documentoRegistrado = usuarioRegistrado.documentoIdentidad;
        print('Usuario registrado exitosamente: $documentoRegistrado');

        // si hay foto seleccionada, la subimos y maanejo erroress
        if (_imagenSeleccionada != null) {
          try {
            // mensaje de que se esta subiendo la foto
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subiendo foto...'),
                  backgroundColor: AppColors.naranjaOscuro,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            await _subirFotoUsuario(documentoRegistrado);

            // registro con foto correcto
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario registrado y foto subida correctamente'),
                  backgroundColor: AppColors.verdeVibrante,
                ),
              );

              _limpiarFormulario();
            }
          } catch (fotoError) {
            print('Error al subir la foto: $fotoError');


            //si selecciona foto pero hay error subiendo la foto, eliminamos el usuario
            try {
              print('Eliminando usuario debido a fallo en subida de foto: $documentoRegistrado');
              await _usuarioService.eliminarUsuario(documentoRegistrado);
              print('Usuario eliminado tras fallar la subida de foto');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error al subir la foto. El registro ha sido cancelado. Por favor, inténtelo de nuevo.',
                    ),
                    backgroundColor: AppColors.naranjaOscuro,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            } catch (eliminarError) {
              print('Error al eliminar usuario: $eliminarError');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error al subir la foto. El usuario fue creado pero sin foto. '
                      'Contacte con el administrador Carlos.',
                    ),
                    backgroundColor: AppColors.naranjaOscuro,
                    duration: Duration(seconds: 10),
                  ),
                );
              }
            }
            return; 
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario registrado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
            _limpiarFormulario();
          }
        }
      } catch (e) {
        print('Error al registrar usuario: $e');

        // verifico si el usuario se registró a pesar del error
        try {
          bool existe = await _usuarioService.verificarUsuarioExistente(documento);
          if (existe) {
            print('El usuario parece haberse registrado a pesar del error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario registrado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );

              _limpiarFormulario();
            }
            return;
          }
        } catch (_) {
          print('Error al verificar si el usuario existe tras error de registro');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al verificar el registro del usuario'),
                backgroundColor: AppColors.naranjaOscuro,
              ),
            );
          }
        }


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar: ${e.toString()}'),
              backgroundColor: AppColors.naranjaOscuro,
            ),
          );
        }
      }
    } catch (e) {
      print('Error durante el registro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: ${e.toString()}'),
            backgroundColor: AppColors.naranjaOscuro,
            duration: const Duration(seconds: 8), 
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }


  void _limpiarFormulario() {
    _nombreController.clear();
    _emailController.clear();
    _documentoController.clear();
    _fechaNacimientoController.clear();
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - 32, // Altura de pantalla menos el padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    controlador: _documentoController,
                    texto: 'Documento de identidad',
                    iconoSufijo: const Icon(Icons.perm_identity, color: AppColors.verdeOscuro),
                  ),
                  const SizedBox(height: 20),
                  CampoTextoPersonalizado(
                    controlador: _fechaNacimientoController,
                    texto: 'Fecha de Nacimiento',
                    soloLectura: true,
                    iconoSufijo: const Icon(Icons.calendar_today, color: AppColors.verdeOscuro),
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
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Foto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_imagenSeleccionada != null)
                    Column(
                      children: [
                        Image.file(
                          _imagenSeleccionada!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 10),
                        BotonNaranjaPersonalizado(
                          onPressed: _removeSelectedImage,
                          texto: 'Eliminar foto',
                        ),
                      ],
                    )
                  else
                    //botones de seleccionar archivo y tomar foto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BotonVerdePersonalizado(
                          onPressed: _selectImageFromGallery,
                          icono: Icons.photo_library,
                          texto: 'Seleccionar archivo',
                        ),
                        const SizedBox(width: 10),
                        BotonVerdePersonalizado(
                          onPressed: _takePhotoWithCamera,
                          icono: Icons.camera_alt,
                          texto: 'Tomar foto',
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  Center(
                    child: BotonNaranjaPersonalizado(
                      onPressed: _registrarUsuario,
                      texto: 'Registrarse',
                      isLoading: _estaCargando,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // Añade espacio extra al final
                ],
              ),
            ),
          ),
          // indicador de carga que cubre toda la pantalla cuando esta registrando
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
}