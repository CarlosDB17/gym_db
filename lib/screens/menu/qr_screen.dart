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
  // controlador para el escaner
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  // controlador para el scroll
  final ScrollController _scrollController = ScrollController();

  // servicio de usuario
  final UsuarioService _usuarioService = UsuarioService();

  bool scannerEnabled = true;
  bool leyendoQR = false;
  bool mostrarResultado = false;
  bool verificandoDatos = false;
  bool procesando = false;
  bool error = false;
  bool mostrarMensajeQRInvalido = false;
  String? mensaje;
  String mensajeVerificacion = '';
  String mensajeQRInvalido = '';
  Usuario? userData;
  String? ultimoCodigoProcesado;


  @override
  void dispose() {
    cameraController.dispose();
    _scrollController.dispose(); 
    super.dispose();
  }

  // verifica si el qr tiene el formato correcto
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

  // metodo para mostrar mensajes de error o exito
  void _mostrarMensaje(String mensaje, bool esError) {
    setState(() {
      this.mensaje = mensaje;
      error = esError;
      verificandoDatos = false;
      mensajeVerificacion = '';
    });
  }

  void _manejarError(String mensajeError) {
    _mostrarMensaje(mensajeError, true);
  }

  void _manejarExito(String mensajeExito) {
    _mostrarMensaje(mensajeExito, false);
  }

  // procesa el codigo qr escaneado
  void procesarCodigoQR(String result) {
    debugPrint('procesando codigo qr: $result');
    
    // pausar el escaner temporalmente
    setState(() {
      scannerEnabled = false;
    });

    try {
      final Map<String, dynamic> scannedData = jsonDecode(result);
      
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
        mensajeVerificacion = 'comprobando datos del qr...';
      });

      // desplazar hacia abajo para mostrar los datos del usuario
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });

      // pequeña pausa para mostrar  mensaje
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        
        setState(() {
          mensajeVerificacion = 'verificando si el usuario ya esta registrado...';
        });
        
        // verificar si el usuario ya existe usando el servicio de usuario
        _usuarioService.verificarUsuarioExistente(scannedUserData.documentoIdentidad).then((existeUsuario) {
          if (!mounted) return;
          
          if (existeUsuario) {
            debugPrint('usuario ya registrado: ${scannedUserData.nombre}');
            _manejarError("este usuario ya ha sido registrado anteriormente");
          } else {
            setState(() {
              verificandoDatos = true;
              mensajeVerificacion = 'registrando usuario...';
            });
            
            _usuarioService.registrarUsuario(scannedUserData).then((_) {
              if (!mounted) return;
              _manejarExito('usuario registrado correctamente');
            }).catchError((e) {
              if (!mounted) return;
              _manejarError('error al registrar usuario: ${e.toString()}');
            });
          }
        }).catchError((e) {
          if (!mounted) return;
          _manejarError('error al verificar usuario: ${e.toString()}');
        });
      });
    } catch (e) {
      // qr no valido
      debugPrint('error al procesar el qr: $e');
      setState(() {
        mensaje = 'el qr no es valido';
        error = true;
        mostrarResultado = true;
        leyendoQR = false;
        verificandoDatos = false;
        mensajeVerificacion = '';
      });
    }
  }

  // reanudar el escaner para escanear otro codigo
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

  // widget para mostrar cuando se esta leyendo un qr
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
              'leyendo qr...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // widget para mostrar cuando el escaner esta en pausa
  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black.withAlpha(179), // 0.7 * 255 = 179
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'escaner en pausa',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: reanudarEscaner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranjaBrillante,
                foregroundColor: AppColors.blanco,
              ),
              child: const Text('reanudar'),
            ),
          ],
        ),
      ),
    );
  }

  // formatea la fecha al formato dd-mm-yyyy
  String _formatearFecha(String fecha) {
    try {
      final DateTime parsedDate = DateTime.parse(fecha);
      return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
    } catch (e) {
      return 'formato invalido';
    }
  }

  // widget para mostrar los resultados del escaneo
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
            'datos del usuario',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.verdeVibrante),
            textAlign: TextAlign.center,
            
          ),
          const SizedBox(height: 16),
          _buildUserDataField('nombre:', userData?.nombre ?? 'no disponible'),
          _buildUserDataField('email:', userData?.email ?? 'no disponible'),
          _buildUserDataField('documento:', userData?.documentoIdentidad ?? 'no disponible'),
          _buildUserDataField(
            'fecha de nacimiento:',
            userData?.fechaNacimiento != null
                ? _formatearFecha(userData!.fechaNacimiento)
                : 'no disponible',
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
                //cambio a rojo si hay error
                color: error ? AppColors.rojoError.withAlpha(26) : AppColors.verdeVibrante.withAlpha(26), 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error ? AppColors.rojoError : AppColors.verdeVibrante, 
                ),
              ),
              child: Text(
                mensaje!,
                style: TextStyle(
                  color: error ? AppColors.rojoError : AppColors.verdeVibrante, 
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
              child: const Text('escanear otro codigo'),
            ),
          ),
        ],
      ),
    );
  }

  // widget auxiliar para mostrar un campo de datos de usuario
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
              color: Colors.black, 
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
          controller: _scrollController, 
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                          
                          if (leyendoQR) _buildReadingOverlay(),
                          
                          if (!scannerEnabled && !mostrarResultado) _buildPausedOverlay(),
                        ],
                      ),
                    ),

                    // texto debajo camara qr
                    if (!mostrarResultado)
                      const SizedBox(height: 16),
                    if (!mostrarResultado)
                      const Text(
                        'Escanea el código QR para registrar al usuario',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),

                    // qr invalido 
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