import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../services/usuario_service.dart';

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
  int limitePorPagina = 3;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importar Usuarios desde CSV',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            
            // Selector de archivo
            Center(
              child: ElevatedButton(
                onPressed: _selectFile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Seleccionar Archivo'),
              ),
            ),
            const SizedBox(height: 20.0),
            
            // Tabla de usuarios
            if (usuariosPaginados.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: [
                    // Encabezados de tabla
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('Nombre'),
                          _buildHeaderCell('Email'),
                          _buildHeaderCell('Documento'),
                          _buildHeaderCell('Fecha Nacimiento'),
                        ],
                      ),
                    ),
                    
                    // Filas de datos
                    ...usuariosPaginados.map((usuario) => Row(
                      children: [
                        _buildDataCell(usuario['nombre'] ?? ''),
                        _buildDataCell(usuario['email'] ?? ''),
                        _buildDataCell(usuario['documento_identidad'] ?? ''),
                        _buildDataCell(_formatFechaMostrar(usuario['fecha_nacimiento'] ?? '')),
                      ],
                    )).toList(),
                  ],
                ),
              ),
            
            // Controles de paginación
            if (usuarios.length > limitePorPagina)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: paginaActual > 0 ? () => _cambiarPagina(-1) : null,
                      child: const Text('Anterior'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Página ${paginaActual + 1} de ${_getTotalPaginas()}'),
                    ),
                    ElevatedButton(
                      onPressed: paginaActual + 1 < _getTotalPaginas() ? () => _cambiarPagina(1) : null,
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ),
            
            // Botón de importación
            if (usuarios.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: _importarUsuariosDesdeCSV,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Confirmar Importación',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widgets para construir la tabla
  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        color: Colors.blue,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey),
            right: BorderSide(color: Colors.grey),
          ),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Seleccionar archivo CSV
  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      await _procesarArchivoCsv(file);
    }
  }

  // Procesar archivo CSV
  Future<void> _procesarArchivoCsv(File file) async {
    try {
      final input = file.readAsStringSync();
      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(input);
      
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
        _actualizarUsuariosPaginados();
      });
    } catch (e) {
      _mostrarSnackBar('Error al procesar el archivo CSV: $e');
    }
  }

  // Validar un usuario individual
  bool _validarUsuario(Map<String, dynamic> usuario) {
    return usuario.containsKey('nombre') && usuario['nombre'].isNotEmpty &&
           usuario.containsKey('email') && usuario['email'].isNotEmpty &&
           usuario.containsKey('documento_identidad') && usuario['documento_identidad'].isNotEmpty &&
           usuario.containsKey('fecha_nacimiento') && usuario['fecha_nacimiento'].isNotEmpty;
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
      DateTime date = DateTime.parse(fecha);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      print('Fecha inválida para mostrar: $fecha');
      return '';
    }
  }

  // Actualizar los usuarios paginados
  void _actualizarUsuariosPaginados() {
    final inicio = paginaActual * limitePorPagina;
    final fin = (inicio + limitePorPagina) < usuarios.length 
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
        _mostrarSnackBar('Todos los campos son obligatorios y deben tener un formato válido.');
        return false;
      }
    }
    return true;
  }

  // Importar usuarios desde CSV
  void _importarUsuariosDesdeCSV() async {
    try {
      await _usuarioService.importarUsuariosDesdeCSV();
      _mostrarSnackBar('Usuarios importados con éxito.');
      setState(() {
        usuarios = [];
        usuariosPaginados = [];
      });
    } catch (e) {
      _mostrarSnackBar('Error al importar usuarios: $e');
    }
  }

  // Mostrar mensajes
  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}