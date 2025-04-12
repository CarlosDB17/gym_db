import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/usuario_service.dart';

class CsvExportarUsuariosScreen extends StatefulWidget {
  const CsvExportarUsuariosScreen({super.key});

  @override
  State<CsvExportarUsuariosScreen> createState() => _CsvExportarUsuariosScreenState();
}

class _CsvExportarUsuariosScreenState extends State<CsvExportarUsuariosScreen> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text('Pantalla de exportación de usuarios (pendiente de implementar)'),
      ),
    );
  }
}