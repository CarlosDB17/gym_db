import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/boton_verde_personalizado.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import '../../widgets/tabla_personalizada.dart';

class ListadoUsuariosScreen extends StatefulWidget {
  const ListadoUsuariosScreen({super.key});

  @override
  State<ListadoUsuariosScreen> createState() => _ListadoUsuariosScreenState();
}

class _ListadoUsuariosScreenState extends State<ListadoUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _busquedaController = TextEditingController();
  List<Usuario> _usuarios = [];
  int _paginaActual = 0;
  int _totalUsuarios = 0;
  final int _usuariosPorPagina = 4;
  bool _cargando = false;
  bool _busquedaRealizada = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios({String? filtro}) async {
    setState(() {
      _cargando = true;
      _mensajeError = null; // Limpiamos mensaje de error anterior
    });

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
        _busquedaRealizada = filtro != null && filtro.isNotEmpty;
        
        // Capturar mensaje de error si existe
        if (data.containsKey('mensaje_error')) {
          _mensajeError = data['mensaje_error'];
          
          // Mostrar mensaje de error en SnackBar si no se encontraron usuarios
          if (_usuarios.isEmpty && mounted) {
            _mostrarSnackBar(_mensajeError!);
          }
        }
      });
    } catch (e) {
      _mostrarSnackBar('Error: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  String _formatearFecha(String fecha) {
    final partes = fecha.split('-');
    if (partes.length == 3) {
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    }
    return fecha; // Retorna la fecha original si no tiene el formato esperado
  }

  // Método para mostrar un SnackBar
  void _mostrarSnackBar(String mensaje, {Color color = Colors.red}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
        ),
      );
    }
  }

  // Método para navegar y recargar usuarios si es necesario
  Future<void> _navegarYRecargar(Usuario usuario) async {
    final resultado = await Navigator.pushNamed(
      context,
      '/listado_usuarios_actualizar',
      arguments: usuario,
    );
    if (resultado == true) {
      _cargarUsuarios();
    }
  }

  // Método para crear filas de datos
  DataRow _crearDataRow(Usuario usuario) {
    return DataRow(
      cells: [
        DataCell(
          usuario.foto != null
              ? ClipOval(
                  child: Image.network(
                    usuario.foto!,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : ClipOval(
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.naranjaBrillante,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.blanco,
                      size: 30,
                    ),
                  ),
                ),
          onTap: () => _navegarYRecargar(usuario),
        ),
        DataCell(Text(usuario.nombre), onTap: () => _navegarYRecargar(usuario)),
        DataCell(Text(usuario.email), onTap: () => _navegarYRecargar(usuario)),
        DataCell(Text(usuario.documentoIdentidad), onTap: () => _navegarYRecargar(usuario)),
        DataCell(Text(_formatearFecha(usuario.fechaNacimiento)), onTap: () => _navegarYRecargar(usuario)),
      ],
    );
  }

  // Cambiar página
  void _cambiarPagina(int direccion) {
    setState(() => _paginaActual += direccion);
    _cargarUsuarios(
      filtro: _busquedaRealizada ? _busquedaController.text : null
    );
  }

  // Obtener total de páginas
  int _getTotalPaginas() {
    return (_totalUsuarios / _usuariosPorPagina).ceil() > 0 
            ? (_totalUsuarios / _usuariosPorPagina).ceil() 
            : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.white,
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.verdeOscuro,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
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
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: AppColors.verdeVibrante, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: AppColors.verdeVibrante, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: AppColors.verdeVibrante, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BotonVerdePersonalizado(
                          onPressed: () {
                            if (_busquedaController.text.trim().isEmpty) {
                              _mostrarSnackBar('Escribe antes de realizar una búsqueda');
                            } else {
                              _cargarUsuarios(filtro: _busquedaController.text);
                            }
                          },
                          texto: 'Buscar',
                        ),
                        const SizedBox(width: 8),
                        BotonNaranjaPersonalizado(
                          onPressed: () {
                            if (_busquedaRealizada) {
                              _busquedaController.clear();
                              setState(() {
                                _busquedaRealizada = false;
                              });
                              _cargarUsuarios();
                            }
                          },
                          texto: 'Limpiar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mostrar mensaje de error si no hay resultados
                    if (_usuarios.isEmpty && _busquedaRealizada)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Sin resultados',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    // Si hay resultados o no se ha realizado búsqueda, mostrar la tabla
                    else if (_usuarios.isNotEmpty || !_busquedaRealizada) 
                      Expanded(
                        child: TablaPersonalizada<Usuario>(
                          columnas: const [
                            DataColumn(label: Text('Foto')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Documento de identidad')),
                            DataColumn(label: Text('Fecha de Nacimiento')),
                          ],
                          datos: _usuarios,
                          crearFila: _crearDataRow,
                          paginaActual: _paginaActual,
                          totalPaginas: _getTotalPaginas(),
                          cambiarPagina: _cambiarPagina,
                          mostrarPaginacion: _totalUsuarios > _usuariosPorPagina,
                          mensajeAyuda: 'Pulsa en un usuario para editarlo. Desliza para ver el resto de datos.',
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}