import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../services/usuario_service.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../widgets/tabla_personalizada.dart';
import '../../widgets/encabezado_personalizado.dart';
import '../../theme/app_colors.dart';

class CsvImportarUsuariosScreen extends StatefulWidget {
  const CsvImportarUsuariosScreen({super.key});

  @override
  State<CsvImportarUsuariosScreen> createState() => _CsvImportarUsuariosScreenState();
}

class _CsvImportarUsuariosScreenState extends State<CsvImportarUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosPaginados = [];

  int paginaActual = 0;
  int limitePorPagina = 3;
  bool _cargando = false;

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
            titulo: 'Importar CSV',
            mostrarBotonAtras: true,
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height - 130,
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
                  : usuarios.isEmpty
                    // Si no hay usuarios cargados, mostrar el contenido centrado
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                        ),
                      )
                    // Si hay usuarios cargados, mostrar la tabla con scroll
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                DataColumn(label: Text('Foto')),
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
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar avatar por defecto cuando no hay foto
  Widget _avatarPorDefecto() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: AppColors.naranjaBrillante,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  // metodo para crear las filas con los datos del csv
  DataRow _crearDataRow(Map<String, dynamic> usuario) {
    return DataRow(
      cells: [
        DataCell(
          (usuario['foto'] != null && usuario['foto'].toString().isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    usuario['foto'],
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _avatarPorDefecto(),
                  ),
                )
              : _avatarPorDefecto(),
        ),
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
      // Leer el contenido del archivo
      final String input = await file.readAsString();
      print('===== INICIO PROCESAMIENTO CSV =====');
      print('Longitud del archivo: ${input.length} caracteres');
      
      // Usar la configuración estándar para CSV
      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        shouldParseNumbers: false, // Mantener todos los valores como strings
      ).convert(input);
      
      print('Filas detectadas en el CSV: ${rowsAsListOfValues.length}');
      
      if (rowsAsListOfValues.isEmpty) {
        throw Exception('El archivo CSV está vacío o no tiene un formato válido');
      }
      
      // Obtener encabezados del CSV (primera fila)
      final List<String> headers = rowsAsListOfValues[0].map((e) => e.toString().trim().toLowerCase()).toList();
      print('Encabezados detectados: $headers');
      
      // Validar que los encabezados necesarios estén presentes
      final requiredHeaders = ['nombre', 'email', 'documento_identidad', 'fecha_nacimiento'];
      for (var header in requiredHeaders) {
        if (!headers.contains(header)) {
          throw Exception('El archivo CSV no contiene la columna obligatoria: $header');
        }
      }
      
      // Convertir filas a lista de mapas
      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        // Ignorar filas vacías
        if (rowsAsListOfValues[i].every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue;
        }
        
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          // Verificar que no estemos accediendo fuera del rango de la fila
          if (j < rowsAsListOfValues[i].length) {
            String encabezado = headers[j];
            String valor = rowsAsListOfValues[i][j].toString().trim();
            
            // Procesar solo las columnas que nos interesan
            if (encabezado == 'nombre' ||
                encabezado == 'email' ||
                encabezado == 'documento_identidad' ||
                encabezado == 'fecha_nacimiento' ||
                encabezado == 'foto') {
              
              // Tratar valores "null" o vacíos apropiadamente
              if (valor.toLowerCase() == 'null' || valor.isEmpty) {
                if (encabezado == 'foto') {
                  row[encabezado] = null;
                } else if (encabezado == 'fecha_nacimiento') {
                  row[encabezado] = '';
                } else {
                  row[encabezado] = '';
                }
              } else {
                row[encabezado] = valor;
              }
            }
          }
        }

        // Formatear la fecha al formato esperado por la API
        if (row.containsKey('fecha_nacimiento') && row['fecha_nacimiento'] != null && row['fecha_nacimiento'].isNotEmpty) {
          row['fecha_nacimiento'] = _formatFecha(row['fecha_nacimiento']);
        }
        
        // Solo agregar usuarios válidos
        if (_validarUsuario(row)) {
          data.add(row);
          print('Usuario #${data.length} procesado: ${row['nombre']} (${row['email']})');
        } else {
          print('Usuario en fila ${i+1} ignorado por datos incompletos: ${row.toString()}');
        }
      }

      setState(() {
        usuarios = data;
        paginaActual = 0; // reinicio a la primera pagina
        _actualizarUsuariosPaginados();
      });

      print('Total usuarios válidos encontrados: ${data.length}');
      print('===== FIN PROCESAMIENTO CSV =====');
      
      if (data.isEmpty) {
        _mostrarSnackBar('No se encontraron datos válidos en el archivo CSV.');
      }
    } catch (e) {
      print('ERROR al procesar CSV: $e');
      _mostrarSnackBar('Error al procesar el archivo CSV: $e');
    }
  }

  // validar cada user
  bool _validarUsuario(Map<String, dynamic> usuario) {
    return usuario.containsKey('nombre') &&
        usuario['nombre'] != null &&
        usuario['nombre'].isNotEmpty &&
        usuario.containsKey('email') &&
        usuario['email'] != null &&
        usuario['email'].isNotEmpty &&
        usuario.containsKey('documento_identidad') &&
        usuario['documento_identidad'] != null &&
        usuario['documento_identidad'].isNotEmpty &&
        usuario.containsKey('fecha_nacimiento') &&
        usuario['fecha_nacimiento'] != null &&
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
      // Ahora recibimos los resultados detallados de la API
      final resultados = await _usuarioService.enviarUsuariosAlaAPI(usuarios);
      
      // Verificamos si hay resultados detallados
      if (resultados.containsKey('resultados') && resultados['resultados'] is List) {
        _mostrarDialogoResultados(resultados['resultados']);
      } else {
        _mostrarSnackBar(
          'Usuarios importados exitosamente.',
          color: AppColors.verdeOscuro,
        );
      }
      
      // Limpiar la lista de usuarios después de importar
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
  
  // Método para mostrar un diálogo con los resultados detallados
  void _mostrarDialogoResultados(List<dynamic> resultados) {
    int registradosCorrectamente = 0;
    int yaRegistrados = 0;
    
    // Contar los resultados según su estado
    for (var resultado in resultados) {
      if (resultado['status'] == 'registrado correctamente') {
        registradosCorrectamente++;
      } else if (resultado['status'] == 'ya registrado') {
        yaRegistrados++;
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resultados de la importación', style: TextStyle(color: AppColors.verdeOscuro)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total de usuarios procesados: ${resultados.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Registrados correctamente: $registradosCorrectamente',
                  style: const TextStyle(color: AppColors.verdeOscuro),
                ),
                Text(
                  'Ya existentes en la base de datos: $yaRegistrados',
                  style: const TextStyle(color: Colors.orange),
                ),
                const Divider(height: 20),
                const Text(
                  'Detalle de la importación:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Lista detallada de resultados
                ...resultados.map((resultado) {
                  final Color statusColor = resultado['status'] == 'registrado correctamente'
                      ? AppColors.verdeOscuro
                      : Colors.orange;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            resultado['usuario'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            resultado['status'] ?? '',
                            style: TextStyle(color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.verdeOscuro,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // metodo para mostrar mensajes
  void _mostrarSnackBar(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }
}