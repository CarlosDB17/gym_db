import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';

class ListadoUsuariosScreen extends StatefulWidget {
  const ListadoUsuariosScreen({super.key});

  @override
  _ListadoUsuariosScreenState createState() => _ListadoUsuariosScreenState();
}

class _ListadoUsuariosScreenState extends State<ListadoUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _busquedaController = TextEditingController();
  List<Usuario> _usuarios = [];
  //Usuario? _usuarioSeleccionado;
  int _paginaActual = 0;
  int _totalUsuarios = 0;
  final int _usuariosPorPagina = 3;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios({String? filtro}) async {
    setState(() => _cargando = true);
    try {
      final data =
          filtro == null || filtro.isEmpty
              ? await _usuarioService.obtenerUsuarios(
                _paginaActual * _usuariosPorPagina,
                _usuariosPorPagina,
              )
              : await _usuarioService.buscarUsuariosPorValor(
                filtro,
                skip: _paginaActual * _usuariosPorPagina,
                limit: _usuariosPorPagina,
              );
      setState(() {
        _usuarios = data['usuarios'];
        _totalUsuarios = data['total'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Listado de Usuarios',
          style: TextStyle(
            color: AppColors.verdeVibrante, // Título en verde vibrante
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.blanco, // Fondo blanco
        iconTheme: const IconThemeData(color: AppColors.verdeOscuro),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.verdeOscuro, // Indicador de carga en verde oscuro
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0), // Padding general
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaController,
                          decoration: InputDecoration(
                            labelText: 'Buscar usuario',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5), // Fondo claro
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30), // Bordes redondeados
                              borderSide: BorderSide.none, // Sin borde
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _cargarUsuarios(filtro: _busquedaController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeVibrante, // Verde vibrante
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Bordes redondeados
                          ),
                        ),
                        child: const Text(
                          'Buscar',
                          style: TextStyle(color: AppColors.blanco),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _busquedaController.clear();
                          _cargarUsuarios();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.naranjaBrillante, // Naranja brillante
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Bordes redondeados
                          ),
                        ),
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(color: AppColors.blanco),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            AppColors.verdeVibrante.withOpacity(0.2),
                          ), // Fondo verde claro para encabezados
                          columnSpacing: 20, // Espaciado entre columnas
                          dataRowHeight: 60, // Altura de las filas
                          headingTextStyle: const TextStyle(
                            color: AppColors.verdeOscuro, // Texto de encabezados en verde oscuro
                            fontWeight: FontWeight.bold,
                          ),
                          columns: const [
                            DataColumn(label: Text('Foto')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Documento de identidad')),
                            DataColumn(label: Text('Fecha de Nacimiento')),
                          ],
                          rows: _usuarios.map((usuario) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  usuario.foto != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(25), // Bordes redondeados
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.verdeOscuro, // Borde verde oscuro
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            child: Image.network(
                                              usuario.foto!,
                                              height: 50,
                                              width: 50,
                                              fit: BoxFit.cover, // Ajustar la imagen al contenedor
                                            ),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(25), // Bordes redondeados
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              color: AppColors.naranjaBrillante, // Fondo naranja brillante
                                              border: Border.all(
                                                color: AppColors.naranjaOscuro, // Borde naranja oscuro
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: AppColors.blanco, // Ícono blanco
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/listado_usuarios_actualizar',
                                      arguments: usuario,
                                    );
                                  },
                                ),
                                DataCell(
                                  Text(usuario.nombre),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/listado_usuarios_actualizar',
                                      arguments: usuario,
                                    );
                                  },
                                ),
                                DataCell(
                                  Text(usuario.email),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/listado_usuarios_actualizar',
                                      arguments: usuario,
                                    );
                                  },
                                ),
                                DataCell(
                                  Text(usuario.documentoIdentidad),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/listado_usuarios_actualizar',
                                      arguments: usuario,
                                    );
                                  },
                                ),
                                DataCell(
                                  Text(usuario.fechaNacimiento),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/listado_usuarios_actualizar',
                                      arguments: usuario,
                                    );
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _paginaActual > 0
                            ? () {
                                setState(() => _paginaActual--);
                                _cargarUsuarios();
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_back,
                          color: _paginaActual > 0
                              ? AppColors.verdeOscuro
                              : Colors.grey, // Cambia a gris si no hay más páginas atrás
                        ),
                      ),
                      Text(
                        'Página ${_paginaActual + 1} / ${(_totalUsuarios / _usuariosPorPagina).ceil()}',
                        style: const TextStyle(color: AppColors.verdeOscuro),
                      ),
                      IconButton(
                        onPressed: (_paginaActual + 1) * _usuariosPorPagina < _totalUsuarios
                            ? () {
                                setState(() => _paginaActual++);
                                _cargarUsuarios();
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: (_paginaActual + 1) * _usuariosPorPagina < _totalUsuarios
                              ? AppColors.verdeOscuro
                              : Colors.grey, // Cambia a gris si no hay más páginas adelante
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
