import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';
import '../../theme/app_colors.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  // Controlador para el escáner
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  // Controlador para el scroll
  final ScrollController _scrollController = ScrollController();

  // Servicio de usuario
  final UsuarioService _usuarioService = UsuarioService();

  // Variables para controlar el estado
  bool scannerEnabled = true;
  bool leyendoQR = false;
  bool mostrarResultado = false;
  bool verificandoDatos = false;
  bool procesando = false;
  bool error = false;
  bool mostrarMensajeQRInvalido = false;

  // Mensajes
  String? mensaje;
  String mensajeVerificacion = '';
  String mensajeQRInvalido = '';

  // Datos del usuario
  Usuario? userData;

  // Último código procesado para evitar duplicados
  String? ultimoCodigoProcesado;

  @override
  void dispose() {
    cameraController.dispose();
    _scrollController.dispose(); // Liberar el controlador de scroll
    super.dispose();
  }

  // Verifica si el QR tiene el formato correcto
  bool esCodigoQRValido(String codigo) {
    try {
      final data = jsonDecode(codigo);
      return data != null &&
          data['nombre'] != null &&
          data['email'] != null &&
          data['documento_identidad'] != null &&
          data['fecha_nacimiento'] != null;
    } catch (e) {
      return false;
    }
  }

  // Procesa el código QR escaneado
  void procesarCodigoQR(String result) {
    debugPrint('Procesando código QR: $result');
    
    // Pausar el escáner temporalmente
    setState(() {
      scannerEnabled = false;
    });

    try {
      final Map<String, dynamic> scannedData = jsonDecode(result);
      
      // Crear un objeto Usuario desde los datos del QR
      final Usuario scannedUserData = Usuario(
        nombre: scannedData['nombre'],
        email: scannedData['email'],
        documentoIdentidad: scannedData['documento_identidad'],
        fechaNacimiento: scannedData['fecha_nacimiento'],
      );
      
      setState(() {
        userData = scannedUserData;
        mostrarResultado = true;
        leyendoQR = false;
        verificandoDatos = true;
        mensajeVerificacion = 'Comprobando datos del QR...';
      });

      // Desplazar hacia abajo para mostrar los datos del usuario
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      // Pequeña pausa para mostrar "Comprobando datos del QR..."
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        
        setState(() {
          mensajeVerificacion = 'Verificando si el usuario ya está registrado...';
        });
        
        // Verificar si el usuario ya existe usando el servicio de usuario
        _usuarioService.verificarUsuarioExistente(scannedUserData.documentoIdentidad).then((existeUsuario) {
          if (!mounted) return;
          
          if (existeUsuario) {
            // El usuario ya existe
            setState(() {
              mensaje = "Este usuario ya ha sido registrado anteriormente";
              error = true;
              verificandoDatos = false;
              mensajeVerificacion = '';
            });
            debugPrint('Usuario ya registrado: ${scannedUserData.nombre}');
          } else {
            // Registrar al usuario usando el servicio
            setState(() {
              verificandoDatos = true;
              mensajeVerificacion = 'Registrando usuario...';
            });
            
            _usuarioService.registrarUsuario(scannedUserData).then((_) {
              if (!mounted) return;
              
              setState(() {
                mensaje = 'Usuario registrado correctamente';
                error = false;
                verificandoDatos = false;
                mensajeVerificacion = '';
              });
            }).catchError((e) {
              if (!mounted) return;
              
              setState(() {
                mensaje = 'Error al registrar usuario: ${e.toString()}';
                error = true;
                verificandoDatos = false;
                mensajeVerificacion = '';
              });
            });
          }
        }).catchError((e) {
          if (!mounted) return;
          
          setState(() {
            mensaje = 'Error al verificar usuario: ${e.toString()}';
            error = true;
            verificandoDatos = false;
            mensajeVerificacion = '';
          });
        });
      });
    } catch (e) {
      // QR no válido
      debugPrint('Error al procesar el QR: $e');
      setState(() {
        mensaje = 'El QR no es válido';
        error = true;
        mostrarResultado = true;
        leyendoQR = false;
        verificandoDatos = false;
        mensajeVerificacion = '';
      });
    }
  }

  // Reanudar el escáner para escanear otro código
  void reanudarEscaner() {
    setState(() {
      scannerEnabled = true;
      leyendoQR = false;
      mostrarResultado = false;
      mensaje = null;
      error = false;
      userData = null;
      verificandoDatos = false;
      mensajeVerificacion = '';
      procesando = false;
      ultimoCodigoProcesado = null;
    });
  }

  // Widget para mostrar cuando se está leyendo un QR
  Widget _buildReadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(179), // 0.7 * 255 = 179
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Leyendo QR...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar cuando el escáner está en pausa
  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black.withAlpha(179), // 0.7 * 255 = 179
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escáner en pausa',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: reanudarEscaner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranjaBrillante,
                foregroundColor: AppColors.blanco,
              ),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      ),
    );
  }

  // Formatea la fecha al formato dd-mm-yyyy
  String _formatearFecha(String fecha) {
    try {
      final DateTime parsedDate = DateTime.parse(fecha);
      return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
    } catch (e) {
      return 'Formato inválido';
    }
  }

  // Widget para mostrar los resultados del escaneo
  Widget _buildResultadoWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), 
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del Usuario',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.verdeVibrante),
            textAlign: TextAlign.center,
            
          ),
          const SizedBox(height: 16),
          _buildUserDataField('Nombre:', userData?.nombre ?? 'No disponible'),
          _buildUserDataField('Email:', userData?.email ?? 'No disponible'),
          _buildUserDataField('Documento:', userData?.documentoIdentidad ?? 'No disponible'),
          _buildUserDataField(
            'Fecha de nacimiento:',
            userData?.fechaNacimiento != null
                ? _formatearFecha(userData!.fechaNacimiento)
                : 'No disponible',
          ),
          
          if (verificandoDatos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mensajeVerificacion,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          
          if (!verificandoDatos && mensaje != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: error ? AppColors.rojoError.withAlpha(26) : AppColors.verdeVibrante.withAlpha(26), // Cambiar a rojo si hay error
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error ? AppColors.rojoError : AppColors.verdeVibrante, // Cambiar a rojo si hay error
                ),
              ),
              child: Text(
                mensaje!,
                style: TextStyle(
                  color: error ? AppColors.rojoError : AppColors.verdeVibrante, // Cambiar a rojo si hay error
                  fontSize: 16,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          Center(
            child: ElevatedButton(
              onPressed: reanudarEscaner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVibrante,
                foregroundColor: AppColors.blanco,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Escanear otro código'),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para mostrar un campo de datos de usuario
  Widget _buildUserDataField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Cambiar color a negro
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController, // Vincular el controlador de scroll
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Scanner container
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51), 
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          if (scannerEnabled)
                            MobileScanner(
                              controller: cameraController,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  if (barcode.rawValue != null && 
                                      !procesando && 
                                      ultimoCodigoProcesado != barcode.rawValue) {
                                    
                                    setState(() {
                                      procesando = true;
                                      leyendoQR = true;
                                      ultimoCodigoProcesado = barcode.rawValue;
                                    });
                                    
                                    if (esCodigoQRValido(barcode.rawValue!)) {
                                      procesarCodigoQR(barcode.rawValue!);
                                    } else {
                                      setState(() {
                                        mostrarMensajeQRInvalido = true;
                                        mensajeQRInvalido = 'Código QR no válido';
                                        leyendoQR = false;
                                      });
                                      
                                      Future.delayed(const Duration(seconds: 3), () {
                                        if (mounted) {
                                          setState(() {
                                            mostrarMensajeQRInvalido = false;
                                            mensajeQRInvalido = '';
                                            procesando = false;
                                          });
                                        }
                                      });
                                    }
                                  }
                                }
                              },
                            ),
                          
                          // QR frame indicators
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          
                          // Reading overlay
                          if (leyendoQR) _buildReadingOverlay(),
                          
                          // Paused overlay
                          if (!scannerEnabled && !mostrarResultado) _buildPausedOverlay(),
                        ],
                      ),
                    ),

                    // Texto debajo de la cámara
                    if (!mostrarResultado)
                      const SizedBox(height: 16),
                    if (!mostrarResultado)
                      const Text(
                        'Escanea el código QR para registrar al usuario',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                    // QR invalid message
                    if (mostrarMensajeQRInvalido)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.naranjaBrillante.withAlpha(26), // 0.1 * 255 = 26
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.naranjaBrillante),
                        ),
                        child: Text(
                          mensajeQRInvalido,
                          style: TextStyle(color: AppColors.naranjaBrillante),
                        ),
                      ),
                      
                    // Resultados
                    if (mostrarResultado) _buildResultadoWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}