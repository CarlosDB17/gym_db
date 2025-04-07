import 'package:flutter/material.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text('Registro de QR'),
  automaticallyImplyLeading: false, // Desactiva la flecha de retroceso
),
      body: const Center(child: Text('Pantalla de Qr')),
    );
  }
}
