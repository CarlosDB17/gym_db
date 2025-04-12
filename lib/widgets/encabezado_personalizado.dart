import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Encabezado extends StatelessWidget {
  final String titulo;
  final bool mostrarBotonAtras;
  final VoidCallback? onAtrasPressed;

  const Encabezado({
    Key? key,
    required this.titulo,
    this.mostrarBotonAtras = true,
    this.onAtrasPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // fondo verde con borde redondeado
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
                color: Colors.black.withOpacity(0.15),
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
                            color: Colors.black.withOpacity(0.15),
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
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        titulo,
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
        
        // boton para volver atras si hace falta
        if (mostrarBotonAtras)
            Positioned(
            top: MediaQuery.of(context).padding.top + 23,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_left_rounded, color: Colors.white, size: 60),
              onPressed: onAtrasPressed ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}