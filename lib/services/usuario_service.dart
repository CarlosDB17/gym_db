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
    try {
      print('Intentando registrar usuario: ${usuario.toJson()}');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );
      
      print('Respuesta del servidor - Código: ${response.statusCode}');
      print('Respuesta del servidor - Cuerpo: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Si la respuesta contiene un objeto anidado 'usuario', usamos ese
        if (responseData is Map<String, dynamic> && responseData.containsKey('usuario')) {
          return Usuario.fromJson(responseData['usuario']);
        } 
        // Si la respuesta es el usuario directamente
        else if (responseData is Map<String, dynamic> && 
                responseData.containsKey('documento_identidad')) {
          return Usuario.fromJson(responseData);
        }
        // Si no podemos extraer el usuario, busquémoslo por su ID
        return await buscarPorDocumentoExacto(usuario.documentoIdentidad);
      } else {
        var errorMessage = 'Error al registrar usuario';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            errorMessage = errorBody['detail'];
          } else if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {
          // Si no se puede decodificar como JSON, usar el body directamente
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        throw Exception('$errorMessage (Código: ${response.statusCode})');
      }
    } catch (e) {
      print('Excepción capturada: $e');
      rethrow; // Relanzar la excepción para que se maneje en la interfaz
    }
  }
  
  // Actualizar usuario parcialmente (solo los campos proporcionados)
  Future<Usuario> actualizarUsuarioParcial(String documentoIdentidad, {
    String? nombre,
    String? email,
    String? fechaNacimiento,
    String? foto,
  }) async {
    final updateData = Usuario.toUpdateJson(
      nombre: nombre,
      email: email,
      fechaNacimiento: fechaNacimiento,
      foto: foto,
    );
    
    if (updateData.isEmpty) {
      // No hay nada que actualizar
      return buscarPorDocumentoExacto(documentoIdentidad);
    }
    
    return actualizarUsuario(documentoIdentidad, updateData);
  }

  // Actualizar usuario
  Future<Usuario> actualizarUsuario(String documentoIdentidad, Map<String, dynamic> data) async {
    // Verificar si el documentoIdentidad o email ya existen en otro usuario
    if (data.containsKey('documento_identidad') || data.containsKey('email')) {
      final nuevoDocumento = data['documento_identidad'];
      final nuevoEmail = data['email'];

      if (nuevoDocumento != null && nuevoDocumento != documentoIdentidad) {
        final existeDocumento = await verificarUsuarioExistente(nuevoDocumento);
        if (existeDocumento) {
          throw Exception('Ya existe un usuario con el documento de identidad proporcionado.');
        }
      }

      if (nuevoEmail != null) {
        final usuariosConEmail = await buscarUsuariosPorValor(nuevoEmail, skip: 0, limit: 1);
        if (usuariosConEmail['total'] > 0) {
          final usuarioEncontrado = usuariosConEmail['usuarios'][0];
          if (usuarioEncontrado.documentoIdentidad != documentoIdentidad) {
            throw ('Ya existe un usuario con el email proporcionado.'); // Cambiado a un simple String
          }
        }
      }
    }

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
Future<String> subirFoto(String documentoIdentidad, File foto) async {
  try {
    // Verificar si el archivo existe
    if (!await foto.exists()) {
      throw Exception('El archivo de imagen no existe');
    }
    
    int fileSize = await foto.length();
    print('Subiendo foto para usuario: $documentoIdentidad');
    print('Tamaño del archivo: ${fileSize ~/ 1024} KB');
    print('Ruta del archivo: ${foto.path}');
    
    // Crear la solicitud multipart
    final uri = Uri.parse("$_baseUrl/$documentoIdentidad/foto");
    print('URL de destino: $uri');
    
    final request = http.MultipartRequest('POST', uri);
    
    // Probar con diferentes nombres de campo - 'file' primero
    request.files.add(await http.MultipartFile.fromPath('file', foto.path));
    
    // También podemos agregar algunos encabezados que pueden ser necesarios
    request.headers['Accept'] = 'application/json';
    
    // Enviar la solicitud
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    
    print('Código de estado de la respuesta: ${streamedResponse.statusCode}');
    print('Cuerpo de la respuesta: $responseBody');
    
    if (streamedResponse.statusCode == 200) {
      // Intentar extraer la URL de la foto de la respuesta
      try {
        final responseData = jsonDecode(responseBody);
        if (responseData is Map && responseData.containsKey('foto')) {
          return responseData['foto'];
        }
        return responseBody; // Devolver la respuesta completa si no hay campo 'foto'
      } catch (_) {
        return responseBody; // Si no es JSON, devolver la respuesta como texto
      }
    } else {
      // Manejar error
      throw Exception('Error al subir la foto: $responseBody (Código: ${streamedResponse.statusCode})');
    }
  } catch (e) {
    print('Error al subir foto: $e');
    rethrow;
  }
}

// Eliminar foto
Future<void> eliminarFotoUsuario(String documentoIdentidad) async {
  final response = await http.delete(Uri.parse("$_baseUrl/$documentoIdentidad/foto"));
  if (response.statusCode != 200) {
    throw Exception('Error al eliminar la foto');
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


// Buscar usuarios por valor con paginación
Future<Map<String, dynamic>> buscarUsuariosPorValor(String valor, {int skip = 0, int limit = 3}) async {
  final response = await http.get(
    Uri.parse("$_baseUrl/buscar/$valor?skip=$skip&limit=$limit"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Usuario> usuarios = List<Usuario>.from(data['usuarios'].map((u) => Usuario.fromJson(u)));
    return {
      'usuarios': usuarios,
      'total': data['total'],
    };
  } else if (response.statusCode == 404) {
    return {
      'usuarios': [],
      'total': 0,
    };
  } else {
    throw Exception('Error al buscar usuarios: ${response.body}');
  }
}

}
