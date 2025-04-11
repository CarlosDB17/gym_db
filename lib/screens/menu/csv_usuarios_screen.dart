import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../services/usuario_service.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../widgets/tabla_personalizada.dart';
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

  int paginaActual = 0;
  int limitePorPagina = 3;
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.white,

      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.verdeOscuro),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Si no hay usuarios cargados, centrar el botón y el texto en la pantalla
                  if (usuarios.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Añadir espacio para centrar verticalmente
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          
                          BotonNaranjaPersonalizado(
                            onPressed: _selectFile,
                            texto: 'Seleccionar Archivo',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Recuerda que debe ser un .csv separado por comas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Si hay usuarios cargados, mostrar el botón en la parte superior
                    Column(
                      children: [
                        Center(
                          child: BotonNaranjaPersonalizado(
                            onPressed: _selectFile,
                            texto: 'Seleccionar Archivo',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Recuerda que debe ser un .csv separado por comas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20.0),
                        
                        // Tabla de usuarios
                        TablaPersonalizada<Map<String, dynamic>>(
                          columnas: const [
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Documento de identidad')),
                            DataColumn(label: Text('Fecha de Nacimiento')),
                          ],
                          datos: usuariosPaginados,
                          crearFila: _crearDataRow,
                          paginaActual: paginaActual,
                          totalPaginas: _getTotalPaginas(),
                          cambiarPagina: _cambiarPagina,
                          mensajeAyuda: 'Desliza para ver el resto de datos.',
                        ),
                        
                        // Botón de confirmar importación
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
                ],
              ),
            ),
    );
  }

  // metodo para crear las filas con los datos del csv
  DataRow _crearDataRow(Map<String, dynamic> usuario) {
    return DataRow(
      cells: [
        DataCell(Text(usuario['nombre'] ?? '')),
        DataCell(Text(usuario['email'] ?? '')),
        DataCell(Text(usuario['documento_identidad'] ?? '')),
        DataCell(Text(_formatFechaMostrar(usuario['fecha_nacimiento'] ?? ''))),
      ],
    );
  }

  // seleccionar archivo csv
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

  // procesar archivo csv
  Future<void> _procesarArchivoCsv(File file) async {
    try {
      final input = file.readAsStringSync();
      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter()
          .convert(input);

      // obtener encabezados del csv (primera fila)
      final headers = rowsAsListOfValues[0];

      // convertir filas a lista de mapas
      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          String encabezado = headers[j].toString().trim();
          if (encabezado == 'nombre' ||
              encabezado == 'email' ||
              encabezado == 'documento_identidad' ||
              encabezado == 'fecha_nacimiento') {
            row[encabezado] = rowsAsListOfValues[i][j].toString().trim();
          }
        }

        // formatear la fecha al formato esperado por la api
        if (row.containsKey('fecha_nacimiento')) {
          row['fecha_nacimiento'] = _formatFecha(row['fecha_nacimiento']);
        }

        // solo agregar usuarios validos
        if (_validarUsuario(row)) {
          data.add(row);
        }
      }

      setState(() {
        usuarios = data;
        paginaActual = 0; // reinicio a la primera pagina
        _actualizarUsuariosPaginados();
      });

      if (data.isEmpty) {
        _mostrarSnackBar('No se encontraron datos válidos en el archivo CSV.');
      }
    } catch (e) {
      _mostrarSnackBar('Error al procesar el archivo CSV: $e');
    }
  }

  // validar cada user
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

  // metodo para formatear al formato yyyy-mm-dd para la api
  String _formatFecha(String fecha) {
    try {
      DateTime date = DateTime.parse(fecha);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      print('Fecha inválida: $fecha');
      return '';
    }
  }

  // metodo para formatear la fecha para mostrar en la tabla (dd-mm-yyyy)
  String _formatFechaMostrar(String fecha) {
    try {
      final partes = fecha.split('-');
      if (partes.length == 3) {
        return '${partes[2]}-${partes[1]}-${partes[0]}';
      }
      return fecha; // devuelve la fecha original si no tiene el formato esperado
    } catch (e) {
      print('Fecha inválida para mostrar: $fecha');
      return '';
    }
  }

  // actualizar los usuarios paginados
  void _actualizarUsuariosPaginados() {
    final inicio = paginaActual * limitePorPagina;
    final fin =
        (inicio + limitePorPagina) < usuarios.length
            ? (inicio + limitePorPagina)
            : usuarios.length;

    usuariosPaginados = usuarios.sublist(inicio, fin);
  }

  // metodo para cambiar de pagina
  void _cambiarPagina(int direccion) {
    setState(() {
      paginaActual += direccion;
      _actualizarUsuariosPaginados();
    });
  }

  // metodo para obtener el total de paginas
  int _getTotalPaginas() {
    return (usuarios.length / limitePorPagina).ceil() > 0
        ? (usuarios.length / limitePorPagina).ceil()
        : 1;
  }

  // metodo para validar todos los usuarios
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

  // metodo para confirmar la importacion de usuarios
  Future<void> _confirmarImportacion() async {
    setState(() {
      _cargando = true;
    });

    if (!_validarUsuarios()) {
      setState(() {
        _cargando = false;
      });
      return; // lo detengo si la validacion falla
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

  // metodo para mostrar mensajes
  void _mostrarSnackBar(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }
}