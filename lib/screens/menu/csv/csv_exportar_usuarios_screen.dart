import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Añadido para Clipboard
import 'package:flutter/foundation.dart' show kIsWeb;
// Import condicional solo para web
import 'csv_exportar_usuarios_stub.dart'
    if (dart.library.html) 'csv_exportar_usuarios_web.dart';
// Comentamos la importación del paquete de permisos por ahora
// import 'package:permission_handler/permission_handler.dart';
import '../../../theme/app_colors.dart';
import '../../../services/usuario_service.dart';
import '../../../models/usuario.dart';
import '../../../widgets/encabezado_personalizado.dart';

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
    
    // Añadir la cabecera exactamente como la importación la espera
    csvContent.writeln('nombre,email,documento_identidad,fecha_nacimiento,foto');
    print('Encabezados CSV: nombre,email,documento_identidad,fecha_nacimiento,foto');
    
    // Añadir los datos de cada usuario en líneas separadas
    for (var usuario in usuarios) {
      // Prepara cada campo, escapando comillas y comas según sea necesario
      // Cada campo se debe procesar para asegurar que no rompa el formato CSV
      String nombre = _escaparCampoCSV(usuario.nombre);
      String email = _escaparCampoCSV(usuario.email);
      String docId = _escaparCampoCSV(usuario.documentoIdentidad);
      
      // Asegurar que la fecha tiene el formato correcto
      String fecha = _escaparCampoCSV(usuario.fechaNacimiento);
      
      // Manejar la foto según sea necesario
      String foto = usuario.foto != null && usuario.foto!.isNotEmpty 
          ? _escaparCampoCSV(usuario.foto!)
          : "null";
      
      // Añadir la línea completa al CSV
      csvContent.writeln('$nombre,$email,$docId,$fecha,$foto');
    }
    
    final csvString = csvContent.toString();
    print('CSV generado correctamente con ${usuarios.length} registros');
    print('===== FIN GENERACIÓN CSV =====');
    
    return csvString;
  }

  // Función auxiliar para escapar correctamente campos CSV
  String _escaparCampoCSV(String valor) {
    // Si el valor contiene comas, comillas o saltos de línea, lo encerramos entre comillas
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      // Reemplazar comillas dobles con dobles comillas dobles (estándar CSV)
      String valorEscapado = valor.replaceAll('"', '""');
      return '"$valorEscapado"';
    }
    return valor;
  }

  Future<void> _guardarArchivo(String csvData) async {
    final String fechaHora = DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now());
    final String nombreArchivo = 'gym_db_usuarios_$fechaHora.csv';
    _nombreArchivo = nombreArchivo;
    List<int> bytes = utf8.encode(csvData);

    if (kIsWeb) {
      try {
        await guardarArchivoWeb(nombreArchivo, bytes);
        setState(() {
          _mensaje = 'Archivo CSV descargado correctamente.';
          _exito = true;
        });
        return;
      } catch (e) {
        print('Error al descargar archivo en web: $e');
        throw Exception('No se pudo descargar el archivo en web.');
      }
    }

    // Guardar en disco para Android/iOS/Windows
    try {
      String? directorioSeleccionado = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona dónde guardar el archivo CSV',
      );
      if (directorioSeleccionado == null) {
        throw Exception('Operación cancelada por el usuario');
      }
      final File file = File('$directorioSeleccionado/$nombreArchivo');
      await file.writeAsBytes(bytes);
      setState(() {
        _mensaje = 'Archivo guardado en: ${file.path}';
        _exito = true;
      });
      print('===== ARCHIVO GUARDADO =====');
      print('Ruta: ${file.path}');
      print('Tamaño: ${bytes.length} bytes');
      print('Codificación: UTF-8');
      print('========================');
      return;
    } catch (e) {
      print('Error al usar FilePicker: $e');
      try {
        final directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/$nombreArchivo');
        await file.writeAsBytes(bytes);
        setState(() {
          _mensaje = 'No se pudo guardar en la ubicación seleccionada. '
                   'Archivo guardado en: ${file.path}';
          _exito = true;
        });
        return;
      } catch (e2) {
        print('Error al guardar en directorio de documentos: $e2');
        if (Platform.isAndroid) {
          try {
            final directory = await getExternalStorageDirectory();
            if (directory != null) {
              final File file = File('${directory.path}/$nombreArchivo');
              await file.writeAsBytes(bytes);
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