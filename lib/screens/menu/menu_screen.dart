import 'package:flutter/material.dart';
import 'registro_usuarios_screen.dart';
import 'listado_usuarios_screen.dart';
import 'qr_screen.dart';
import 'csv_usuarios_screen.dart';
import 'ajustes_screen.dart';
import '../../theme/app_colors.dart'; 

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RegistroUsuariosScreen(),
    const ListadoUsuariosScreen(),
    const QrScreen(),
    const CsvUsuariosScreen(),
    const AjustesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        backgroundColor: AppColors.naranjaBrillante, 
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.naranjaBrillante, 
        unselectedItemColor: AppColors.verdeOscuro, 
        backgroundColor: AppColors.blanco, 
        showUnselectedLabels: true, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Registro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Listado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: 'CSV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}