import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';

class UsuarioService {

  final String _baseUrl = "http://192.168.1.38:8000/usuarios";
  //final String _baseUrl = "https://pf25-carlos-db-v6-302016834907.europe-west1.run.app/usuarios";

  // Obtener usuarios con paginación
  Future<Map<String, dynamic>> obtenerUsuarios(int skip, int limit) async {
    final response = await http.get(
      Uri.parse("$_baseUrl?skip=$skip&limit=$limit"),
      headers: {'Accept': 'application/json; charset=utf-8'}, // Asegurar UTF-8
    );

    if (response.statusCode == 200) {
      // Decodificar explícitamente como UTF-8
      final utf8Body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(utf8Body);

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
        headers: {
          'Content-Type': 'application/json; charset=utf-8', // Asegurar UTF-8
        },
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
  // Crear un mapa solo con los valores que no son nulos
  final Map<String, dynamic> updateData = {};
  
  if (nombre != null) updateData['nombre'] = nombre;
  if (email != null) updateData['email'] = email;
  if (fechaNacimiento != null) updateData['fecha_nacimiento'] = fechaNacimiento;
  if (foto != null) updateData['foto'] = foto;
  
  if (updateData.isEmpty) {
    // No hay nada que actualizar
    return buscarPorDocumentoExacto(documentoIdentidad);
  }
  
  // Realizar la actualización
  final response = await http.patch(
    Uri.parse("$_baseUrl/$documentoIdentidad"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(updateData),
  );
  if (response.statusCode == 200) {
    // Después de actualizar correctamente, obtener el usuario completo actualizado
    return await buscarPorDocumentoExacto(documentoIdentidad);
  } else {
    throw Exception('Error al actualizar usuario');
  }
}

// Actualizar usuario
Future<Usuario> actualizarUsuario(String documentoIdentidad, Map<String, dynamic> data) async {
  print('Iniciando actualización del usuario...');
  print('Documento actual: $documentoIdentidad');
  print('Datos enviados antes de ajustes: $data');

  // Convertir email a minúsculas y documento a mayúsculas
  if (data.containsKey('email')) {
    data['email'] = data['email'].toString().toLowerCase();
  }
  if (data.containsKey('documentoIdentidad')) {
    data['documentoIdentidad'] = data['documentoIdentidad'].toString().toUpperCase();
  }
  if (data.containsKey('documento_identidad')) {
    data['documento_identidad'] = data['documento_identidad'].toString().toUpperCase();
  }

  // Convertir fecha al formato YYYY-MM-DD si está presente
  if (data.containsKey('fechaNacimiento')) {
    final fecha = data['fechaNacimiento'];
    if (fecha is String && fecha.contains('-')) {
      final partes = fecha.split('-');
      if (partes.length == 3) {
        data['fechaNacimiento'] = '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
      }
    }
  }

  // Convertir claves a snake_case
  final Map<String, dynamic> dataSnakeCase = {};
  data.forEach((key, value) {
    final snakeCaseKey = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
    dataSnakeCase[snakeCaseKey] = value;
  });

  // Convertir el documento actual a mayúsculas
  documentoIdentidad = documentoIdentidad.toUpperCase();

  // Verificar si el documentoIdentidad o email ya existen en otro usuario
  if (data.containsKey('documentoIdentidad') || data.containsKey('email')) {
    final nuevoDocumento = data['documentoIdentidad'];
    final nuevoEmail = data['email'];

    print('URL de la solicitud: $_baseUrl/$documentoIdentidad');
    print('Encabezados de la solicitud: ${{'Content-Type': 'application/json; charset=utf-8'}}');
    print('Cuerpo de la solicitud (JSON): ${jsonEncode(data)}');

    if (nuevoDocumento != null && nuevoDocumento != documentoIdentidad) {
      print('Verificando si el nuevo documento ya existe: $nuevoDocumento');
      final existeDocumento = await verificarUsuarioExistente(nuevoDocumento);
      if (existeDocumento) {
        print('Error: Ya existe un usuario con el documento de identidad proporcionado.');
        throw Exception('Ya existe un usuario con el documento de identidad proporcionado.');
      }
    }

    if (nuevoEmail != null) {
      print('Verificando si el nuevo email ya existe: $nuevoEmail');
      final usuariosConEmail = await buscarUsuariosPorValor(nuevoEmail, skip: 0, limit: 1);
      if (usuariosConEmail['total'] > 0) {
        final usuarioEncontrado = usuariosConEmail['usuarios'][0];
        if (usuarioEncontrado.documentoIdentidad != documentoIdentidad) {
          print('Error: Ya existe un usuario con el email proporcionado.');
          throw ('Ya existe un usuario con el email proporcionado.');
        }
      }
    }
  }

  // Si el documentoIdentidad ha cambiado, actualizar el valor en el cuerpo de la solicitud
  final nuevoDocumentoIdentidad = data['documentoIdentidad'] ?? documentoIdentidad;
  data['documentoIdentidad'] = nuevoDocumentoIdentidad; // Asegurarse de que el nuevo documento esté en el cuerpo

  print('Documento que se usará en la URL: $documentoIdentidad');
  print('Documento que se usará en el cuerpo: $nuevoDocumentoIdentidad');
  print('Datos enviados después de ajustes: $dataSnakeCase');

  try {
    print('URL de la solicitud: $_baseUrl/$documentoIdentidad');
    print('Encabezados de la solicitud: ${{'Content-Type': 'application/json; charset=utf-8'}}');
    print('Cuerpo de la solicitud: ${jsonEncode(dataSnakeCase)}');

    final response = await http.patch(
      Uri.parse("$_baseUrl/$documentoIdentidad"), // Usar el documento antiguo en la URL
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(dataSnakeCase), // Enviar el nuevo documento en el cuerpo si ha cambiado
    );

    print('Respuesta del servidor - Código: ${response.statusCode}');
    print('Respuesta del servidor - Cuerpo: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Si el documentoIdentidad cambió, usar el nuevo documento en mayúsculas
      if (responseData is Map && responseData.containsKey('nuevo_documento_identidad')) {
        final nuevoDocumento = responseData['nuevo_documento_identidad'].toString().toUpperCase();
        print('El documentoIdentidad ha cambiado. Nuevo documento: $nuevoDocumento');
        return await buscarPorDocumentoExacto(nuevoDocumento);
      }

      // Si no cambió, buscar el usuario actualizado con el documento actual
      print('El documentoIdentidad no cambió. Buscando usuario actualizado...');
      return await buscarPorDocumentoExacto(documentoIdentidad);
    } else {
      print('Error al actualizar usuario: ${response.body}');
      throw Exception('Error al actualizar usuario');
    }
  } catch (e) {
    print('Excepción capturada durante la actualización: $e');
    rethrow;
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
  try {
    // Imprimir la URL completa para depuración
    final url = "$_baseUrl/buscar/$valor?skip=$skip&limit=$limit";
    print('Realizando petición a: $url');
    
    final response = await http.get(Uri.parse(url));

    // Imprimir información detallada de la respuesta
    print('Código de respuesta para búsqueda "$valor": ${response.statusCode}');
    print('Cuerpo de respuesta: ${response.body}');
    
    // Si la respuesta es exitosa (200 OK)
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        // Verificar estructura de datos completa
        if (data is Map && data.containsKey('usuarios') && data.containsKey('total')) {
          // Convertir los datos a objetos Usuario
          try {
            List<Usuario> usuarios = (data['usuarios'] as List)
                .map((u) => Usuario.fromJson(u as Map<String, dynamic>))
                .toList();
            return {
              'usuarios': usuarios,
              'total': data['total'],
            };
          } catch (e) {
            print('Error al convertir datos a objetos Usuario: $e');
            return {'usuarios': <Usuario>[], 'total': 0};
          }
        } else {
          print('Respuesta sin estructura esperada: $data');
          return {'usuarios': <Usuario>[], 'total': 0};
        }
      } catch (e) {
        print('Error al decodificar JSON: $e');
        return {'usuarios': <Usuario>[], 'total': 0};
      }
    } 
    // Si no se encontraron resultados (404 Not Found u otros códigos de error)
    else {
      print('No se encontraron usuarios para "$valor" - Código: ${response.statusCode}');
      
      // Intentar extraer el mensaje de error
      String mensajeError = "No se encontraron usuarios";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          mensajeError = errorData['detail'];
        }
      } catch (e) {
        print('Error al decodificar mensaje de error: $e');
      }
      
      // Devolver una lista vacía y el mensaje de error
      return {
        'usuarios': <Usuario>[],
        'total': 0,
        'mensaje_error': mensajeError
      };
    }
  } catch (e) {
    print('Excepción capturada en buscarUsuariosPorValor: $e');
    // Devolver estructura válida incluso en caso de excepción
    return {
      'usuarios': <Usuario>[],
      'total': 0,
      'mensaje_error': 'Error al realizar la búsqueda: $e'
    };
  }
}

}
