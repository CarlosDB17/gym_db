import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class VentanaEmergenteSalida extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String botonAfirmativo;
  final String botonNegativo;
  final VoidCallback onAccion;
  final Color colorBotonAfirmativo;

  const VentanaEmergenteSalida({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    this.botonAfirmativo = 'Aceptar',
    this.botonNegativo = 'Cancelar',
    required this.onAccion,
    this.colorBotonAfirmativo = AppColors.naranjaBrillante,
  }) : super(key: key);

  /// Método estático para mostrar el diálogo personalizado
  static Future<bool?> mostrar({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    String botonAfirmativo = 'Aceptar',
    String botonNegativo = 'Cancelar',
    required VoidCallback onAccion,
    Color colorBotonAfirmativo = AppColors.naranjaBrillante,
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

  /// Método para mostrar diálogo específico para salir de la aplicación
  static Future<bool?> mostrarSalirApp(BuildContext context) {
    return mostrar(
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

  /// Método para mostrar diálogo específico para cerrar sesión
  static Future<bool?> mostrarCerrarSesion({
    required BuildContext context,
    required VoidCallback onCerrarSesion,
  }) {
    return mostrar(
      context: context,
      titulo: '¿Cerrar sesión?',
      subtitulo: '¿Estás seguro que deseas cerrar tu sesión?',
      botonAfirmativo: 'Cerrar sesión',
      botonNegativo: 'Cancelar',
      onAccion: onCerrarSesion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
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