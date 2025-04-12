import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/usuario_service.dart';
import '../../widgets/tabla_personalizada.dart';
import '../../theme/app_colors.dart';

class AdministrarRolesScreen extends StatefulWidget {
  const AdministrarRolesScreen({super.key});

  @override
  State<AdministrarRolesScreen> createState() => _AdministrarRolesScreenState();
}

class _AdministrarRolesScreenState extends State<AdministrarRolesScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;
  int _paginaActual = 0;
  final int _itemsPorPagina = 8;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _cargarUsuarios();
  }

  Future<void> _verificarAutenticacion() async {
    final usuarioActual = FirebaseAuth.instance.currentUser;
    if (usuarioActual == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      // Usando el método del servicio en lugar de acceder directamente a Firestore
      _usuarios = await _usuarioService.cargarUsuariosFirestore();
    } catch (e) {
      print('Error al cargar usuarios: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _cambiarPagina(int incremento) {
    setState(() {
      _paginaActual += incremento;
    });
  }

  List<Map<String, dynamic>> _getUsuariosPaginados() {
    final start = _paginaActual * _itemsPorPagina;
    final end = start + _itemsPorPagina < _usuarios.length 
        ? start + _itemsPorPagina 
        : _usuarios.length;
        
    if (start >= _usuarios.length) {
      return [];
    }
    
    return _usuarios.sublist(start, end);
  }

  int get _totalPaginas => 
      (_usuarios.length / _itemsPorPagina).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Roles'),
        backgroundColor: AppColors.verdeVibrante,
        foregroundColor: AppColors.blanco,
      ),
      body: Container(
        width: double.infinity,
        color: AppColors.fondoClaro,
        padding: const EdgeInsets.all(16.0),
        child: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.naranjaBrillante),
              ),
            )
          : Center( // Centrar todo el contenido
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
                children: [
                  Expanded(
                    child: Center( // Centrar horizontalmente
                      child: TablaPersonalizada<Map<String, dynamic>>(
                        columnas: const [
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Rol')),
                        ],
                        datos: _getUsuariosPaginados(),
                        crearFila: (usuario) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                usuario['email'],
                                style: const TextStyle(color: AppColors.textoOscuro),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: usuario['role'] == 'admin' 
                                      ? AppColors.naranjaOscuro.withAlpha(51)
                                      : AppColors.verdeVibrante.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    usuario['role'],
                                    style: TextStyle(
                                      color: usuario['role'] == 'admin' 
                                          ? AppColors.naranjaOscuro
                                          : AppColors.verdeOscuro,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onSelectChanged: (_) async {
                              final actualizado = await Navigator.pushNamed(
                                context,
                                '/administrar_roles_actualizar',
                                arguments: usuario,
                              );
                              
                              if (actualizado == true) {
                                _cargarUsuarios(); // Recarga los usuarios cuando vuelve con cambios
                              }
                            },
                          );
                        },
                        paginaActual: _paginaActual,
                        totalPaginas: _totalPaginas,
                        cambiarPagina: _cambiarPagina,
                        mensajeAyuda: _usuarios.isEmpty 
                            ? 'No hay usuarios registrados' 
                            : 'Pulsa sobre un usuario para editar su rol.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}