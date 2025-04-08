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
  Usuario? _usuarioSeleccionado;
  int _paginaActual = 0;
  int _totalUsuarios = 0;
  final int _usuariosPorPagina = 5;
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

  Future<void> _actualizarUsuario(Usuario usuario) async {
    // Implementar lógica de actualización
  }

  Future<void> _eliminarFotoUsuario(String documentoIdentidad) async {
    try {
      await _usuarioService.eliminarFotoUsuario(documentoIdentidad);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada correctamente.')),
      );
      _cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _eliminarUsuario(String documentoIdentidad) async {
    try {
      await _usuarioService.eliminarUsuario(documentoIdentidad);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado correctamente.')),
      );
      _cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Usuarios'),
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar usuario',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            () => _cargarUsuarios(
                              filtro: _busquedaController.text,
                            ),
                        child: const Text('Buscar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _busquedaController.clear();
                          _cargarUsuarios();
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          showCheckboxColumn: false,
                                          columns: const [
                                            DataColumn(label: Text('Foto')),
                                            DataColumn(label: Text('Nombre')),
                                            DataColumn(label: Text('Email')),
                                            DataColumn(label: Text('Documento de identidad')),
                                            DataColumn(label: Text('Fecha de Nacimiento')),
                                          ],
                                          rows: _usuarios.map((usuario) {
                                            return DataRow(
                                              onSelectChanged: (selected) {
                                                if (selected == true) {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/listado_usuarios_actualizar',
                                                    arguments: usuario,
                                                  );
                                                }
                                              },
                                              cells: [
                                                DataCell(
                                                  usuario.foto != null
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(25), // Bordes redondeados
                                                          child: Image.network(
                                                            usuario.foto!,
                                                            height: 50,
                                                            width: 50,
                                                            fit: BoxFit.cover, // Ajustar la imagen al contenedor
                                                          ),
                                                        )
                                                      : ClipRRect(
                                                          borderRadius: BorderRadius.circular(25), // Bordes redondeados
                                                          child: Image.asset(
                                                            'assets/images/default_avatar.png',
                                                            height: 50,
                                                            width: 50,
                                                            fit: BoxFit.cover, // Ajustar la imagen al contenedor
                                                          ),
                                                        ),
                                                ),
                                                DataCell(Text(usuario.nombre)),
                                                DataCell(Text(usuario.email)),
                                                DataCell(Text(usuario.documentoIdentidad)),
                                                DataCell(Text(usuario.fechaNacimiento)),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Espacio amplio entre la tabla y el texto
                                  const SizedBox(height: 10),
                                  // Texto instructivo
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 26.0),
                                    child: Text(
                                      'Pulsa sobre un usuario para editarlo',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
                // Botones de paginación en una Row separada
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          _paginaActual > 0
                              ? () {
                                setState(() => _paginaActual--);
                                _cargarUsuarios();
                              }
                              : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text('Página ${_paginaActual + 1}'),
                    IconButton(
                      onPressed:
                          (_paginaActual + 1) * _usuariosPorPagina <
                                  _totalUsuarios
                              ? () {
                                setState(() => _paginaActual++);
                                _cargarUsuarios();
                              }
                              : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_usuarioSeleccionado != null)
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.blanco,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(_usuarioSeleccionado!.nombre),
                      subtitle: Text(_usuarioSeleccionado!.email),
                      leading:
                          _usuarioSeleccionado!.foto != null
                              ? Image.network(
                                _usuarioSeleccionado!.foto!,
                                height: 50,
                                width: 50,
                              )
                              : const Icon(Icons.person),
                    ),
                    const Divider(),
                    ElevatedButton(
                      onPressed:
                          () => _actualizarUsuario(_usuarioSeleccionado!),
                      child: const Text('Actualizar'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => _eliminarFotoUsuario(
                            _usuarioSeleccionado!.documentoIdentidad,
                          ),
                      child: const Text('Eliminar Foto'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => _eliminarUsuario(
                            _usuarioSeleccionado!.documentoIdentidad,
                          ),
                      child: const Text('Eliminar Usuario'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
