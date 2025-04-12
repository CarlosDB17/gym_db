import 'package:flutter/material.dart';
import '../../widgets/boton_naranja_personalizado.dart';
import 'csv_importar_usuarios_screen.dart';
import 'csv_exportar_usuarios_screen.dart';

class CsvUsuariosScreen extends StatefulWidget {
  const CsvUsuariosScreen({super.key});

  @override
  State<CsvUsuariosScreen> createState() => _CsvUsuariosScreenState();
}

class _CsvUsuariosScreenState extends State<CsvUsuariosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [      
            // Botón para exportar usuarios
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: BotonNaranjaPersonalizado(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CsvExportarUsuariosScreen(),
                    ),
                  );
                },
                texto: 'Exportar Archivo',
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                icono: Icons.file_download_outlined,
              ),
            ),
            
            // Botón para importar usuarios
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: BotonNaranjaPersonalizado(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CsvImportarUsuariosScreen(),
                    ),
                  );
                },
                texto: 'Importar Archivo',
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                icono: Icons.file_upload_outlined,
              ),
            ),
            
            // Texto informativo
            const Padding(
              padding: EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 0.0),
              child: Text(
              'Selecciona una opción para gestionar los archivos CSV de usuarios',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}