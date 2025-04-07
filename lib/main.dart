import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importamos Firestore
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Inicializamos Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYM DB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.naranjaBrillante),
      ),
      home: const MyHomePage(title: 'GYM DB 2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String firebaseStatus = "Verificando conexión con Firebase...";

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Intentamos escribir un dato de prueba en Firestore
      await FirebaseFirestore.instance.collection('test').doc('connection').set({
        'timestamp': DateTime.now(),
      });

      setState(() {
        firebaseStatus = "Firebase está funcionando correctamente 👌";
      });
    } catch (e) {
      setState(() {
        firebaseStatus = "Error al conectar con Firebase: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(firebaseStatus), // Mostramos el estado de Firebase
          ],
        ),
      ),
    );
  }
}
