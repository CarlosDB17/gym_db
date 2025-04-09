import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BotonNaranjaPersonalizado extends StatelessWidget {
  final VoidCallback onPressed;
  final String texto;
  final IconData? icono;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

  const BotonNaranjaPersonalizado({
    super.key,
    required this.onPressed,
    required this.texto,
    this.icono,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (icono != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Icon(icono),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranjaBrillante,
          foregroundColor: AppColors.blanco,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranjaBrillante,
          foregroundColor: AppColors.blanco,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(texto),
      );
    }
  }
}
