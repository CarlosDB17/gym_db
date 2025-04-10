import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../services/usuario_service.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../theme/app_colors.dart';

class CsvUsuariosScreen extends StatefulWidget {
  const CsvUsuariosScreen({super.key});

  @override
  State<CsvUsuariosScreen> createState() => _CsvUsuariosScreenState();
}

class _CsvUsuariosScreenState extends State<CsvUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosPaginados = [];

  // Variables para paginación
  int paginaActual = 0;
  int limitePorPagina =
      4; // Cambiado a 4 para coincidir con ListadoUsuariosScreen
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _cargando
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.verdeOscuro),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20.0),
                    // Boton para seleccionar archivo
                    Center(
                      child: BotonNaranjaPersonalizado(
                        onPressed: _selectFile,
                        texto: 'Seleccionar Archivo',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                      ), // Añade padding por arriba de 10
                      child: const Text(
                        'Recuerda que debe ser un .csv separado por comas',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20.0),

                    // Tabla de usuarios
                    if (usuariosPaginados.isNotEmpty)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.verdeVibrante.withAlpha(
                                      (0.2 * 255).toInt(),
                                    ),
                                  ),
                                  columnSpacing: 20,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 60,
                                  headingTextStyle: const TextStyle(
                                    color: AppColors.verdeOscuro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(
                                      label: Text('Documento de identidad'),
                                    ),
                                    DataColumn(
                                      label: Text('Fecha de Nacimiento'),
                                    ),
                                  ],
                                  rows:
                                      usuariosPaginados
                                          .map(
                                            (usuario) => _crearDataRow(usuario),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'Desliza para ver el resto de datos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),

                          // Controles de paginación
                          if (usuarios.length > limitePorPagina)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed:
                                        paginaActual > 0
                                            ? () => _cambiarPagina(-1)
                                            : null,
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color:
                                          paginaActual > 0
                                              ? AppColors.verdeOscuro
                                              : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Página ${paginaActual + 1} / ${_getTotalPaginas() > 0 ? _getTotalPaginas() : 1}',
                                    style: const TextStyle(
                                      color: AppColors.verdeOscuro,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        (paginaActual + 1) < _getTotalPaginas()
                                            ? () => _cambiarPagina(1)
                                            : null,
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      color:
                                          (paginaActual + 1) <
                                                  _getTotalPaginas()
                                              ? AppColors.verdeOscuro
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                    // Botón de importación
                    if (usuarios.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: BotonVerdePersonalizado(
                            onPressed: _confirmarImportacion,
                            texto: 'Confirmar Importación',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  // Método para crear filas de datos
  DataRow _crearDataRow(Map<String, dynamic> usuario) {
    return DataRow(
      cells: [
        _crearDataCell(usuario['nombre'] ?? ''),
        _crearDataCell(usuario['email'] ?? ''),
        _crearDataCell(usuario['documento_identidad'] ?? ''),
        _crearDataCell(_formatFechaMostrar(usuario['fecha_nacimiento'] ?? '')),
      ],
    );
  }

  // Método para crear celdas de datos
  DataCell _crearDataCell(String texto) {
    return DataCell(Text(texto));
  }

  // Seleccionar archivo CSV
  Future<void> _selectFile() async {
    setState(() {
      _cargando = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _procesarArchivoCsv(file);
      }
    } catch (e) {
      _mostrarSnackBar('Error al seleccionar el archivo: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // Procesar archivo CSV
  Future<void> _procesarArchivoCsv(File file) async {
    try {
      final input = file.readAsStringSync();
      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter()
          .convert(input);

      // Obtener encabezados del CSV (primera fila)
      final headers = rowsAsListOfValues[0];

      // Convertir filas a lista de mapas
      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          String headerKey = headers[j].toString().trim();
          // Asegúrate de que los encabezados coinciden con las claves esperadas
          if (headerKey == 'nombre' ||
              headerKey == 'email' ||
              headerKey == 'documento_identidad' ||
              headerKey == 'fecha_nacimiento') {
            row[headerKey] = rowsAsListOfValues[i][j].toString().trim();
          }
        }

        // Formatear la fecha al formato esperado por la API
        if (row.containsKey('fecha_nacimiento')) {
          row['fecha_nacimiento'] = _formatFecha(row['fecha_nacimiento']);
        }

        // Solo agregar usuarios válidos
        if (_validarUsuario(row)) {
          data.add(row);
        }
      }

      setState(() {
        usuarios = data;
        paginaActual = 0; // Reiniciar a la primera página
        _actualizarUsuariosPaginados();
      });

      if (data.isEmpty) {
        _mostrarSnackBar('No se encontraron datos válidos en el archivo CSV.');
      }
    } catch (e) {
      _mostrarSnackBar('Error al procesar el archivo CSV: $e');
    }
  }

  // Validar un usuario individual
  bool _validarUsuario(Map<String, dynamic> usuario) {
    return usuario.containsKey('nombre') &&
        usuario['nombre'].isNotEmpty &&
        usuario.containsKey('email') &&
        usuario['email'].isNotEmpty &&
        usuario.containsKey('documento_identidad') &&
        usuario['documento_identidad'].isNotEmpty &&
        usuario.containsKey('fecha_nacimiento') &&
        usuario['fecha_nacimiento'].isNotEmpty;
  }

  // Formatear la fecha al formato yyyy-mm-dd para la API
  String _formatFecha(String fecha) {
    try {
      DateTime date = DateTime.parse(fecha);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      print('Fecha inválida: $fecha');
      return '';
    }
  }

  // Formatear la fecha para mostrar en la tabla (dd-mm-yyyy)
  String _formatFechaMostrar(String fecha) {
    try {
      final partes = fecha.split('-');
      if (partes.length == 3) {
        return '${partes[2]}-${partes[1]}-${partes[0]}';
      }
      return fecha; // Retorna la fecha original si no tiene el formato esperado
    } catch (e) {
      print('Fecha inválida para mostrar: $fecha');
      return '';
    }
  }

  // Actualizar los usuarios paginados
  void _actualizarUsuariosPaginados() {
    final inicio = paginaActual * limitePorPagina;
    final fin =
        (inicio + limitePorPagina) < usuarios.length
            ? (inicio + limitePorPagina)
            : usuarios.length;

    usuariosPaginados = usuarios.sublist(inicio, fin);
  }

  // Cambiar de página
  void _cambiarPagina(int direccion) {
    setState(() {
      paginaActual += direccion;
      _actualizarUsuariosPaginados();
    });
  }

  // Obtener el total de páginas
  int _getTotalPaginas() {
    return (usuarios.length / limitePorPagina).ceil();
  }

  // Validar todos los usuarios
  bool _validarUsuarios() {
    for (var usuario in usuarios) {
      if (!_validarUsuario(usuario)) {
        _mostrarSnackBar(
          'Todos los campos son obligatorios y deben tener un formato válido.',
        );
        return false;
      }
    }
    return true;
  }

  // Método para confirmar la importación de usuarios
  Future<void> _confirmarImportacion() async {
    setState(() {
      _cargando = true;
    });

    if (!_validarUsuarios()) {
      setState(() {
        _cargando = false;
      });
      return; // Detener si la validación falla
    }

    try {
      await _usuarioService.enviarUsuariosAlaAPI(usuarios);
      _mostrarSnackBar(
        'Usuarios importados exitosamente.',
        color: AppColors.verdeOscuro,
      );
      setState(() {
        usuarios.clear();
        usuariosPaginados.clear();
      });
    } catch (e) {
      _mostrarSnackBar('Error al importar usuarios: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // Mostrar mensajes
  void _mostrarSnackBar(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }
}
