import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/campo_texto_personalizado.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController controladorCorreo = TextEditingController();
  final TextEditingController controladorContrasena = TextEditingController();
  final FirebaseAuth autenticacion = FirebaseAuth.instance;
  bool contrasenaVisible = false; // controla la visibilidad de la contraseña

  Future<void> iniciarSesionCorreoContrasena() async {
    final correo = controladorCorreo.text.trim();
    final contrasena = controladorContrasena.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      mostrarMensajeError('Por favor, completa todos los campos.');
      return;
    }

    if (!esCorreoValido(correo)) {
      mostrarMensajeError('Por favor, ingresa un correo válido.');
      return;
    }

    try {
      await autenticacion.signInWithEmailAndPassword(
        email: correo, password: contrasena);

      // Después de iniciar sesión, verificar o crear documento en Firestore
      await _verificarYAsignarRol();

      await SessionManager.guardarSesionActiva();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } on FirebaseAuthException catch (e) {
      manejarErrorAutenticacion(e);
    } catch (e) {
      mostrarMensajeError('Ocurrió un error inesperado. Inténtalo de nuevo.');
    }
  }

  Future<void> _verificarYAsignarRol() async {
    try {
      // Obtener el usuario actual
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Verificar si el documento del usuario existe en Firestore
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (!snapshot.exists) {
          // Si no existe, crear un documento con rol 'user' por defecto
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'email': user.email,
            'role': 'user', // Rol por defecto
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Documento del usuario creado con rol: user');
        } else {
          print('Usuario ya existe en Firestore.');
        }
      }
    } catch (e) {
      print('Error al verificar o asignar rol: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await autenticacion.signInWithCredential(credential);

      // Después de iniciar sesión con Google, verificar o crear documento en Firestore
      await _verificarYAsignarRol();

      await SessionManager.guardarSesionActiva();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    }
  }

  bool esCorreoValido(String correo) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(correo);
  }

  void mostrarMensajeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            AppColors.naranjaOscuro, // cambia el color del fondo del SnackBar
      ),
    );
  }

  void manejarErrorAutenticacion(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No se encontró una cuenta con este email.';
        break;
      case 'wrong-password':
        message = 'La contraseña es incorrecta.';
        break;
      case 'invalid-email':
        message = 'El email ingresado no es válido.';
        break;
      default:
        message = 'Ocurrió un error al iniciar sesión. Inténtalo de nuevo.';
    }
    mostrarMensajeError(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/gym_logo.png', height: 100),
                const SizedBox(height: 30),
                CampoTextoPersonalizado(
                  controlador: controladorCorreo,
                  texto: 'Email',
                ),
                const SizedBox(height: 20),
                CampoTextoPersonalizado(
                  controlador: controladorContrasena,
                  texto: 'Contraseña',
                  esContrasena: true,
                  textoOculto: !contrasenaVisible, // controla la visibilidad
                  alternarVisibilidadContrasena: () {
                    setState(() {
                      contrasenaVisible = !contrasenaVisible;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: iniciarSesionCorreoContrasena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.naranjaBrillante,
                    foregroundColor: AppColors.blanco,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 50,
                    ),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    '¿No tienes cuenta aún? Regístrate',
                    style: TextStyle(color: AppColors.verdeVibrante),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                  ),
                  label: const Text('Iniciar sesión con Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanco,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: AppColors.verdeOscuro),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
