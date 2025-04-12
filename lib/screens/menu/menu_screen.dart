import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registro_usuarios_screen.dart';
import 'listado_usuarios_screen.dart';
import 'qr_screen.dart';
import 'csv_usuarios_screen.dart';
import 'ajustes_screen.dart';
import '../../theme/app_colors.dart';
import '../../services/usuario_service.dart';
import '../../widgets/ventana_emergente_salida.dart';

// pantalla principal del menu
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;
  
  // Lista de pantallas disponibles
  final List<Widget> _screens = [
    const RegistroUsuariosScreen(),
    const ListadoUsuariosScreen(),
    const QrScreen(),
    const CsvUsuariosScreen(),
    const AjustesScreen(),
  ];

  // Títulos de las pantallas
  final List<String> _titles = [
    'Registro de usuarios',
    'Listado de usuarios',
    'QR',
    'Gestión de CSVs',
    'Ajustes',
  ];

  // Esta variable se debe establecer según el rol del usuario
  String userRole = 'user'; // Valor predeterminado

  @override
  void initState() {
    super.initState();
    _obtenerRolUsuario();
  }

  // Método para obtener el rol del usuario
  Future<void> _obtenerRolUsuario() async {
    try {
      // Obtener el usuario autenticado
      User? usuarioActual = FirebaseAuth.instance.currentUser;

      if (usuarioActual != null && usuarioActual.email != null) {
        // Obtener el rol del usuario desde Firestore
        String? rol = await UsuarioService().obtenerRolUsuarioPorEmail(usuarioActual.email!);

        if (rol != null) {
          setState(() {
            userRole = rol;
          });
        }
      } else {
        print('No se encontró un usuario autenticado o el email es nulo.');
      }
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
    }
  }

  // dialogo para confirmar la salida de la aplicacion
  void _mostrarDialogoSalida() {
    VentanaEmergenteSalida.mostrar(
      context: context,
      titulo: '¿Salir de la aplicación?',
      subtitulo: '¿Estás seguro que deseas salir de la aplicación?',
      botonAfirmativo: 'Salir',
      botonNegativo: 'Cancelar',
      onAccion: () {
        SystemNavigator.pop();
      },
    );
  }

  // Filtra las opciones según el rol del usuario
  List<Widget> getMenuItems() {
    if (userRole == 'admin') {
      return [
        _buildNavButton(0, Icons.person_add_rounded, 'Registro'),
        _buildNavButton(1, Icons.format_list_bulleted_rounded, 'Listado'),
        _buildNavButton(2, Icons.qr_code_scanner_rounded, 'QR'),
        _buildNavButton(3, Icons.file_upload_outlined, 'CSV'),
        _buildNavButton(4, Icons.settings_rounded, 'Ajustes'),
      ];
    } else if (userRole == 'ListAdmin') {
      return [
        _buildNavButton(0, Icons.person_add_rounded, 'Registro'),
        _buildNavButton(1, Icons.format_list_bulleted_rounded, 'Listado'),
        _buildNavButton(4, Icons.settings_rounded, 'Ajustes'),
      ];
    } else {
      return [
        _buildNavButton(0, Icons.person_add_rounded, 'Registro'),
        _buildNavButton(4, Icons.settings_rounded, 'Ajustes'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configuración de la barra de estado
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop) {
          _mostrarDialogoSalida();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.fondoClaro,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: Stack(
          children: [
            // Fondo superior
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.verdeVibrante,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sombra.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/gym_logo.png',
                            height: 30,
                          ),
                        ),
                        const SizedBox(width: 16), // espacio entre la imagen y el texto
                        Padding(
                          padding: const EdgeInsets.only(top: 8), 
                          child: Text(
                            _titles[_currentIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.only(top: 130, bottom: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.fondoClaro,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sombra.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: _screens[_currentIndex],
                ),
              ),
            ),
          ],
        ),
        
        // Menú de navegación
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sombra.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: getMenuItems(), // Usa el menú filtrado por rol
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => setState(() {
        _currentIndex = index;
      }),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.verdeVibrante : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.verdeVibrante.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textoOscuro.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.verdeVibrante : AppColors.textoOscuro.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
