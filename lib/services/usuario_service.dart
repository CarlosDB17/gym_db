import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';

class UsuarioService {
  final String _baseUrl = "https://pf25-carlos-db-v6-302016834907.europe-west1.run.app/usuarios";

  // Obtener usuarios con paginación
  Future<Map<String, dynamic>> obtenerUsuarios(int skip, int limit) async {
    final response = await http.get(Uri.parse("$_baseUrl?skip=$skip&limit=$limit"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Usuario> usuarios = List<Usuario>.from(data['usuarios'].map((u) => Usuario.fromJson(u)));
      return {
        'usuarios': usuarios,
        'total': data['total']
      };
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  // Registrar usuario
  Future<Usuario> registrarUsuario(Usuario usuario) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(usuario.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al registrar usuario');
    }
  }

  // Actualizar usuario
  Future<Usuario> actualizarUsuario(String documentoIdentidad, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse("$_baseUrl/$documentoIdentidad"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al actualizar usuario');
    }
  }

  // Eliminar usuario
  Future<void> eliminarUsuario(String documentoIdentidad) async {
    final response = await http.delete(Uri.parse("$_baseUrl/$documentoIdentidad"));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }

  // Subir foto
  Future<void> subirFoto(String documentoIdentidad, File foto) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$_baseUrl/$documentoIdentidad/foto"),
    );
    request.files.add(await http.MultipartFile.fromPath('file', foto.path));
    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception('Error al subir la foto');
    }
  }

  // Obtener foto
  Future<String> obtenerFoto(String documentoIdentidad) async {
    final response = await http.get(Uri.parse("$_baseUrl/$documentoIdentidad/foto"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['foto'];
    } else {
      throw Exception('Error al obtener foto');
    }
  }

  // Buscar por documento exacto
  Future<Usuario> buscarPorDocumentoExacto(String documentoIdentidad) async {
    final response = await http.get(Uri.parse("$_baseUrl/documento-exacto/$documentoIdentidad"));
    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  // Verificar si el usuario existe
  Future<bool> verificarUsuarioExistente(String documentoIdentidad) async {
    final response = await http.get(Uri.parse("$_baseUrl/$documentoIdentidad/"));
    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    } else {
      throw Exception('Error al verificar usuario');
    }
  }
}
