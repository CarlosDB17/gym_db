
import 'package:flutter/material.dart';
import '../../../../../services/usuario_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../widgets/boton_verde_personalizado.dart';
import '../../../../../widgets/boton_naranja_personalizado.dart';

class AdministrarRolesActualizarScreen extends StatefulWidget {
  const AdministrarRolesActualizarScreen({super.key});

  @override
  State<AdministrarRolesActualizarScreen> createState() => _AdministrarRolesActualizarScreenState();
}

class _AdministrarRolesActualizarScreenState extends State<AdministrarRolesActualizarScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _rolController = TextEditingController();
  Map<String, dynamic>? _usuario;
  bool _estaCargando = false;
  final List<String> _rolesDisponibles = ['user', 'admin', 'ListAdmin'];
  String _rolSeleccionado = 'user';

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      _usuario = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _rolSeleccionado = _usuario!['role'] ?? 'user';
      _rolController.text = _rolSeleccionado;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar Rol: ${_usuario!['email']}'),
        backgroundColor: AppColors.verdeVibrante,
        foregroundColor: AppColors.blanco,
      ),
      body: Container(
        width: double.infinity,
        color: AppColors.fondoClaro,
        child: Stack(
          children: [
            Center( // Centrar todo el contenido
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center( // Centrar la tarjeta horizontalmente
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500), // Limitar el ancho máximo para mejor visualización
                    child: Card(
                      elevation: 4,
                      shadowColor: AppColors.sombra,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email del usuario
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.grisSuave,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    color: AppColors.verdeOscuro,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _usuario!['email'] ?? 'Sin correo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textoOscuro,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Selecciona el rol:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textoOscuro,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Selector de roles con opciones visuales
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.grisSuave),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: _rolesDisponibles.map((rol) {
                                  final bool estaSeleccionado = _rolSeleccionado == rol;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _rolSeleccionado = rol;
                                        _rolController.text = rol;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: estaSeleccionado 
                                            ? rol == 'admin' 
                                                ? AppColors.naranjaOscuro.withAlpha(51)
                                                : rol == 'ListAdmin'
                                                  ? AppColors.naranjaBrillante.withAlpha(51)
                                                  : AppColors.verdeVibrante.withAlpha(51)
                                            : Colors.transparent,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.grisSuave,
                                            width: rol != _rolesDisponibles.last ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            estaSeleccionado
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: estaSeleccionado
                                                ? rol == 'admin' 
                                                    ? AppColors.naranjaOscuro
                                                    : rol == 'ListAdmin'
                                                        ? AppColors.naranjaBrillante
                                                        : AppColors.verdeVibrante
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _obtenerDescripcionRol(rol),
                                              style: TextStyle(
                                                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                                                color: estaSeleccionado
                                                    ? rol == 'admin' 
                                                        ? AppColors.naranjaOscuro
                                                        : rol == 'ListAdmin'
                                                            ? AppColors.naranjaBrillante
                                                            : AppColors.verdeVibrante
                                                    : AppColors.textoOscuro,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Botones de acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BotonNaranjaPersonalizado(
                                  onPressed: () => Navigator.pop(context),
                                  texto: 'Cancelar',
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                const SizedBox(width: 16),
                                BotonVerdePersonalizado(
                                  onPressed: _actualizarRol,
                                  texto: 'Guardar Cambios',
                                  isLoading: _estaCargando,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_estaCargando)
              Container(
                color: Colors.black.withAlpha(76),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.naranjaBrillante),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _obtenerDescripcionRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador - Acceso total al sistema';
      case 'ListAdmin':
        return 'Administrador de Listas - Acceso a registro y listado';
      case 'user':
        return 'Usuario - Acceso solo al registro de usuarios';
      default:
        return rol;
    }
  }

  Future<void> _actualizarRol() async {
    if (_rolSeleccionado == _usuario!['role']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se realizaron cambios en el rol.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() => _estaCargando = true);

    try {
      // Usando el método del servicio en lugar de acceder directamente a Firestore
      await _usuarioService.actualizarRolUsuario(_usuario!['id'], _rolSeleccionado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol actualizado correctamente a $_rolSeleccionado.'),
          backgroundColor: AppColors.verdeVibrante,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el rol: $e'),
          backgroundColor: AppColors.rojoError,
        ),
      );
    } finally {
      setState(() => _estaCargando = false);
    }
  }
}