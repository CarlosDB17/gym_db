import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';

class RegistroUsuariosScreen extends StatefulWidget {
  const RegistroUsuariosScreen({super.key});

  @override
  _RegistroUsuariosScreenState createState() => _RegistroUsuariosScreenState();
}

class _RegistroUsuariosScreenState extends State<RegistroUsuariosScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
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
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.verdeOscuro,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: _buildInputDecoration('Nombre'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: _buildInputDecoration('Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _documentoController,
              decoration: _buildInputDecoration(
                'Documento de identidad',
                suffixIcon: const Icon(Icons.perm_identity, color: AppColors.verdeOscuro),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _fechaNacimientoController,
              decoration: _buildInputDecoration(
                'Fecha de Nacimiento',
                suffixIcon: const Icon(Icons.calendar_today, color: AppColors.verdeOscuro),
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _fechaNacimientoController.text =
                        '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_selectedImage != null)
              Column(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _removeSelectedImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.naranjaOscuro,
                    ),
                    child: const Text('Eliminar foto'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeOscuro,
                      foregroundColor: AppColors.blanco,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _takePhotoWithCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeOscuro,
                      foregroundColor: AppColors.blanco,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final nombre = _nombreController.text.trim();
                  final email = _emailController.text.trim();
                  final documento = _documentoController.text.trim();
                  final fechaNacimiento =
                      _fechaNacimientoController.text.trim();

                  if (nombre.isEmpty ||
                      email.isEmpty ||
                      documento.isEmpty ||
                      fechaNacimiento.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Por favor, completa todos los campos.'),
                        backgroundColor: AppColors.naranjaOscuro,
                      ),
                    );
                    return;
                  }

                  print('Nombre: $nombre');
                  print('Email: $email');
                  print('Documento: $documento');
                  print('Fecha de Nacimiento: $fechaNacimiento');
                  print('Foto seleccionada: ${_selectedImage?.path}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.naranjaBrillante,
                  foregroundColor: AppColors.blanco,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 50,
                  ),
                ),
                child: const Text('Registrarse'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}