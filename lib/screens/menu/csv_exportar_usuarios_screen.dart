import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/usuario_service.dart';
import '../../widgets/encabezado_personalizado.dart';

class CsvExportarUsuariosScreen extends StatefulWidget {
  const CsvExportarUsuariosScreen({super.key});

  @override
  State<CsvExportarUsuariosScreen> createState() => _CsvExportarUsuariosScreenState();
}

class _CsvExportarUsuariosScreenState extends State<CsvExportarUsuariosScreen> {
  // ignore: prefer_final_fields
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
            titulo: 'Exportar a CSV',
            mostrarBotonAtras: true,
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Container(
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
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            const Text(
                              'Pantalla de exportación de usuarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '(Pendiente de implementar)',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}