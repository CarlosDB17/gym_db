import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CampoTextoPersonalizado extends StatelessWidget {
  final TextEditingController controlador;
  final String texto;
  final bool esContrasena;
  final bool soloLectura;
  final Widget? iconoSufijo;
  final VoidCallback? alTocar;
  final bool? textoOculto; // Propiedad para manejar visibilidad
  final VoidCallback? alternarVisibilidadContrasena; // Propiedad para alternar visibilidad

  const CampoTextoPersonalizado({
    Key? key,
    required this.controlador,
    required this.texto,
    this.esContrasena = false,
    this.soloLectura = false,
    this.iconoSufijo,
    this.alTocar,
    this.textoOculto,
    this.alternarVisibilidadContrasena,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      obscureText: esContrasena ? (textoOculto ?? true) : false,
      readOnly: soloLectura,
      onTap: alTocar,
      decoration: InputDecoration(
        labelText: texto,
        labelStyle: TextStyle(color: AppColors.verdeOscuro),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: AppColors.verdeOscuro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: AppColors.verdeVibrante),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: AppColors.naranjaOscuro),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: AppColors.naranjaOscuro),
        ),
        suffixIcon: esContrasena
            ? IconButton(
                icon: Icon(
                  textoOculto == true
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.verdeOscuro,
                ),
                onPressed: alternarVisibilidadContrasena,
              )
            : iconoSufijo,
      ),
    );
  }
}