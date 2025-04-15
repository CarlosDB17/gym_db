import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Añadido para Clipboard
// Comentamos la importación del paquete de permisos por ahora
// import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';
import '../../widgets/encabezado_personalizado.dart';

class CsvExportarUsuariosScreen extends StatefulWidget {
  const CsvExportarUsuariosScreen({super.key});

  @override
  State<CsvExportarUsuariosScreen> createState() => _CsvExportarUsuariosScreenState();
}

class _CsvExportarUsuariosScreenState extends State<CsvExportarUsuariosScreen> {
  bool _cargando = false;
  String _mensaje = '';
  bool _exito = false;
  final _usuarioService = UsuarioService();
  int _totalUsuarios = 0;
  String? _csvData;
  String? _nombreArchivo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoClaro,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          // Encabezado reutilizable
          const Encabezado(
            titulo: 'Exportar a CSV',
            mostrarBotonAtras: true,
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.verdeOscuro),
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                            Text(
                              _exito ? 'Usuarios disponibles: $_totalUsuarios' : '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdeOscuro,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _exportarUsuarios,
                              child: const Text(
                                'Exportar datos de usuarios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_exito)
                              const Text(
                                'Esta herramienta exportará todos los datos de los usuarios a un archivo CSV.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            
                            const SizedBox(height: 10),
                            // Mostrar botón para copiar al portapapeles si hay datos
                            if (_csvData != null && _csvData!.isNotEmpty)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.verdeOscuro,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => _copiarAlPortapapeles(_csvData!),
                                child: const Text(
                                  'Copiar datos al portapapeles',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (_mensaje.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _mensaje,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _exito ? Colors.green : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _exportarUsuarios() async {
    setState(() {
      _cargando = true;
      _mensaje = '';
      _exito = false;
      _csvData = null;
      _nombreArchivo = null;
    });

    try {
      // Obtener todos los usuarios desde la API
      final resultado = await _usuarioService.obtenerUsuarios(0, 9999999999);
      final List<Usuario> usuarios = resultado['usuarios'];
      final int totalUsuarios = resultado['total'];

      // Generar el archivo CSV
      final String csvData = _generarCSV(usuarios);
      _csvData = csvData;
      
      // Guardar el archivo CSV y manejar posibles errores
      try {
        await _guardarArchivo(csvData);
      } catch (e) {
        print("Error al guardar archivo: $e");
        // Si hay un error al guardar, almacenamos los datos para copiar al portapapeles
        _nombreArchivo = 'gym_db_usuarios_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.csv';
        
        setState(() {
          _mensaje = 'No se pudo guardar el archivo. '
                    'Puedes copiar los datos al portapapeles.';
          _exito = false;
        });
      }

      setState(() {
        _totalUsuarios = totalUsuarios;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al exportar usuarios: ${e.toString()}';
        _exito = false;
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  String _generarCSV(List<Usuario> usuarios) {
    StringBuffer csvContent = StringBuffer();
    
    print('===== INICIO GENERACIÓN CSV =====');
    print('Generando CSV para ${usuarios.length} usuarios');
    
    // Añadir la cabecera en una línea separada
    csvContent.writeln('nombre,email,documento_identidad,fecha_nacimiento,foto');
    print('Encabezados CSV: nombre,email,documento_identidad,fecha_nacimiento,foto');
    
    // Añadir los datos de cada usuario en líneas separadas
    for (var usuario in usuarios) {
      // Manejar posibles comas en los campos
      String nombre = usuario.nombre.contains(',') ? '"${usuario.nombre}"' : usuario.nombre;
      String email = usuario.email.contains(',') ? '"${usuario.email}"' : usuario.email;
      String docId = usuario.documentoIdentidad;
      String fecha = usuario.fechaNacimiento;
      
      // Construir la fila con los campos adecuadamente escapados
      String fila = '$nombre,$email,$docId,$fecha,';
      
      // Añadir foto solo si existe, en caso contrario añadir "null"
      if (usuario.foto != null && usuario.foto!.isNotEmpty) {
        String foto = usuario.foto!.contains(',') ? '"${usuario.foto}"' : usuario.foto!;
        fila += foto;
      } else {
        fila += 'null';
      }
      
      // Añadir la línea completa al CSV (asegurándonos que cada usuario esté en una nueva línea)
      csvContent.writeln(fila);
      print('Fila añadida: $fila');
    }
    
    final csvString = csvContent.toString();
    print('Primeros 200 caracteres del CSV generado: ${csvString.length > 200 ? '${csvString.substring(0, 200)}...' : csvString}');
    print('===== FIN GENERACIÓN CSV =====');
    
    return csvString;
  }

  Future<void> _guardarArchivo(String csvData) async {
    // Generar el nombre del archivo con la fecha y hora actual
    final String fechaHora = DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now());
    final String nombreArchivo = 'gym_db_usuarios_$fechaHora.csv';
    _nombreArchivo = nombreArchivo;

    // Asegurar que los datos estén codificados en UTF-8
    List<int> bytes = utf8.encode(csvData);
    
    // Añadir BOM (Byte Order Mark) para que Excel reconozca correctamente UTF-8
    List<int> bytesWithBOM = [0xEF, 0xBB, 0xBF, ...bytes];

    try {
      // Primero preguntamos al usuario dónde quiere guardar el archivo
      String? directorioSeleccionado = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona dónde guardar el archivo CSV',
      );
      
      if (directorioSeleccionado == null) {
        throw Exception('Operación cancelada por el usuario');
      }
      
      // Guardar el archivo en la ubicación seleccionada por el usuario con codificación UTF-8
      final File file = File('$directorioSeleccionado/$nombreArchivo');
      await file.writeAsBytes(bytesWithBOM);
      
      setState(() {
        _mensaje = 'Archivo guardado en: ${file.path}';
        _exito = true;
      });
      return;
    } catch (e) {
      print('Error al usar FilePicker: $e');
      
      // Si falla FilePicker, intentar con métodos alternativos
      try {
        // Intentar guardar en el directorio de documentos
        final directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/$nombreArchivo');
        await file.writeAsBytes(bytesWithBOM);
        
        setState(() {
          _mensaje = 'No se pudo guardar en la ubicación seleccionada. '
                   'Archivo guardado en: ${file.path}';
          _exito = true;
        });
        return;
      } catch (e2) {
        print('Error al guardar en directorio de documentos: $e2');
        
        // Si estamos en Android, intentar con almacenamiento externo
        if (Platform.isAndroid) {
          try {
            final directory = await getExternalStorageDirectory();
            if (directory != null) {
              final File file = File('${directory.path}/$nombreArchivo');
              await file.writeAsBytes(bytesWithBOM);
              
              setState(() {
                _mensaje = 'Archivo guardado automáticamente en: ${file.path}';
                _exito = true;
              });
              return;
            }
          } catch (e3) {
            print('Error al guardar en almacenamiento externo: $e3');
          }
        }
        
        // Si todo falla, notificar para usar el portapapeles
        throw Exception('No se pudo guardar el archivo. Intenta copiar los datos al portapapeles.');
      }
    }
  }
  
  void _copiarAlPortapapeles(String datos) async {
    try {
      await Clipboard.setData(ClipboardData(text: datos));
      setState(() {
        _mensaje = 'Datos copiados al portapapeles. Puedes pegarlos en Excel o un editor de texto.'
                 '\nNombre del archivo recomendado: $_nombreArchivo';
        _exito = true;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al copiar al portapapeles: ${e.toString()}';
        _exito = false;
      });
    }
  }
}