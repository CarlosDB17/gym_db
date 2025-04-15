import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VentanaEmergenteSalida extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String botonAfirmativo;
  final String botonNegativo;
  final VoidCallback onAccion;
  final Color colorBotonAfirmativo;

  const VentanaEmergenteSalida({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.botonAfirmativo = 'Aceptar',
    this.botonNegativo = 'Cancelar',
    required this.onAccion,
    this.colorBotonAfirmativo = AppColors.verdeVibrante,
  });

  /// Método estático para mostrar el diálogo personalizado
  static Future<bool?> mostrar({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    String botonAfirmativo = 'Aceptar',
    String botonNegativo = 'Cancelar',
    required VoidCallback onAccion,
    Color colorBotonAfirmativo = AppColors.verdeVibrante,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VentanaEmergenteSalida(
        titulo: titulo,
        subtitulo: subtitulo,
        botonAfirmativo: botonAfirmativo,
        botonNegativo: botonNegativo,
        onAccion: onAccion,
        colorBotonAfirmativo: colorBotonAfirmativo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // Fondo blanco añadido
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold), // Título en negrita
      ),
      content: Text(subtitulo),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(botonNegativo, style: TextStyle(color: AppColors.textoOscuro)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onAccion();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorBotonAfirmativo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(botonAfirmativo, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}