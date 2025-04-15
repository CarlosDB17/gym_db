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
  
  // Variables para gestionar la tabla de resultados
  List<Map<String, dynamic>> resultadosImportacion = [];
  List<Map<String, dynamic>> resultadosPaginados = [];
  bool mostrarResultados = false;
  int paginaResultados = 0;
  final int limiteResultadosPorPagina = 3;
  
  // Variables para el resumen de la importación
  Map<String, dynamic> resumenImportacion = {};

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
                  : mostrarResultados
                    // Mostrar resultados de la importación
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Resultados de la importación',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.verdeOscuro,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Tabla de resultados
                            TablaPersonalizada<Map<String, dynamic>>(
                              columnas: const [
                                DataColumn(label: Text('Documento')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Información')),
                              ],
                              datos: resultadosPaginados,
                              crearFila: _crearDataRowResultado,
                              paginaActual: paginaResultados,
                              totalPaginas: _getTotalPaginasResultados(),
                              cambiarPagina: _cambiarPaginaResultados,
                              mensajeAyuda: 'Desliza para ver la tabla al completo.',
                            ),
                            
                            // Estadísticas de la importación
                            const SizedBox(height: 20),
                            _mostrarEstadisticasImportacion(),
                            
                            // Botón para volver a la pantalla de importación
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: BotonNaranjaPersonalizado(
                                  onPressed: () {
                                    setState(() {
                                      mostrarResultados = false;
                                      resultadosImportacion.clear();
                                      resultadosPaginados.clear();
                                    });
                                  },
                                  texto: 'Nueva Importación',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
      // Recibimos los resultados detallados de la API
      final resultados = await _usuarioService.enviarUsuariosAlaAPI(usuarios);
      
      // Verificamos si hay resultados detallados
      if (resultados.containsKey('resultados') && resultados['resultados'] is List) {
        // Preparar los resultados para la tabla
        setState(() {
          // Guardar el resumen de la importación
          if (resultados.containsKey('resumen')) {
            resumenImportacion = Map<String, dynamic>.from(resultados['resumen']);
          }
          
          // Convertir los datos a un formato adecuado para la tabla
          resultadosImportacion = List<Map<String, dynamic>>.from(
            resultados['resultados'].map((resultado) => {
              'documento': resultado['usuario'] ?? '',
              'status': resultado['status'] ?? '',
              'mensaje': resultado['mensaje'] ?? '',
            })
          );
          
          // Activar la visualización de resultados
          mostrarResultados = true;
          paginaResultados = 0;
          _actualizarResultadosPaginados();
          
          // Limpiar la lista de usuarios después de importar
          usuarios.clear();
          usuariosPaginados.clear();
        });
      } else {
        _mostrarSnackBar(
          'Usuarios importados exitosamente.',
          color: AppColors.verdeOscuro,
        );
        
        // Limpiar la lista de usuarios
        setState(() {
          usuarios.clear();
          usuariosPaginados.clear();
        });
      }
    } catch (e) {
      _mostrarSnackBar('Error al importar usuarios: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // Método para actualizar los resultados paginados
  void _actualizarResultadosPaginados() {
    final inicio = paginaResultados * limiteResultadosPorPagina;
    final fin = (inicio + limiteResultadosPorPagina) < resultadosImportacion.length
        ? (inicio + limiteResultadosPorPagina)
        : resultadosImportacion.length;

    resultadosPaginados = resultadosImportacion.sublist(inicio, fin);
  }
  
  // Método para cambiar de página en los resultados
  void _cambiarPaginaResultados(int direccion) {
    setState(() {
      paginaResultados += direccion;
      _actualizarResultadosPaginados();
    });
  }
  
  // Método para obtener el total de páginas de resultados
  int _getTotalPaginasResultados() {
    return (resultadosImportacion.length / limiteResultadosPorPagina).ceil() > 0
        ? (resultadosImportacion.length / limiteResultadosPorPagina).ceil()
        : 1;
  }
  
  // Método para crear filas de la tabla de resultados
  DataRow _crearDataRowResultado(Map<String, dynamic> resultado) {
    // Modificar para detectar "éxito" con tilde y también "exito" sin tilde
    final bool esExitoso = resultado['status'] == 'Éxito' || resultado['status'] == 'Exito';
    final Color colorEstado = esExitoso ? AppColors.verdeOscuro : AppColors.rojoError;
    final IconData iconoEstado = esExitoso ? Icons.check_circle : Icons.error;
    
    return DataRow(
      cells: [
        DataCell(Text(
          resultado['documento'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconoEstado,
                color: colorEstado,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                resultado['status'] ?? '',
                style: TextStyle(
                  color: colorEstado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                resultado['mensaje'] ?? '',
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 12,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método para mostrar resumen estadístico de la importación
  Widget _mostrarEstadisticasImportacion() {
    // Si tenemos el resumen de la API, usamos esos datos
    if (resumenImportacion.isNotEmpty) {
      int registradosCorrectamente = resumenImportacion['registrados_correctamente'] ?? 0;
      int conErrores = resumenImportacion['con_errores'] ?? 0;
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _crearTarjetaEstadistica(
                'Éxitos',
                registradosCorrectamente.toString(),
                Icons.check_circle,
                AppColors.verdeOscuro,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _crearTarjetaEstadistica(
                'Errores',
                conErrores.toString(),
                Icons.error_outline,
                Colors.red,
              ),
            ),
          ],
        ),
      );
    }
    
    // Si no tenemos datos del resumen de la API, calcular en base a resultados
    int exitosos = 0;
    int errores = 0;
    
    // Contar los resultados según su estado
    for (var resultado in resultadosImportacion) {
      if (resultado['status'] == 'éxito') {
        exitosos++;
      } else if (resultado['status'] == 'error') {
        errores++;
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Se eliminó el boxShadow
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _crearTarjetaEstadistica(
              'Éxitos',
              exitosos.toString(),
              Icons.check_circle,
              AppColors.verdeOscuro,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _crearTarjetaEstadistica(
              'Errores',
              errores.toString(),
              Icons.error_outline,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Método para crear tarjetas de estadísticas
  Widget _crearTarjetaEstadistica(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      color: AppColors.blanco, // Establecer color blanco explícitamente
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold, // Añadido para poner el título en negrita
              ),
            ),
          ],
        ),
      ),
    );
  }

  // metodo para mostrar mensajes
  void _mostrarSnackBar(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }
}