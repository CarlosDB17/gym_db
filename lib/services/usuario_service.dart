import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class UsuarioService {

 // final String _baseUrl = "http://192.168.1.38:8000/usuarios";
  final String _baseUrl = "https://pf25-carlos-db-v6-302016834907.europe-west1.run.app/usuarios";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // obtener usuarios con paginacion
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


// Método para obtener el rol del usuario desde Firestore
  Future<String?> obtenerRolUsuarioPorEmail(String email) async {
    try {
      // Verifica si el usuario está autenticado
      var usuarioActual = FirebaseAuth.instance.currentUser;

      if (usuarioActual == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Busca el documento del usuario en la colección 'users' usando el UID
      var docUsuario = await FirebaseFirestore.instance.collection('users').doc(usuarioActual.uid).get();

      if (docUsuario.exists) {
        // Retorna el rol del usuario desde Firestore
        return docUsuario.data()?['role'] ?? 'user'; // 'user' es el valor por defecto si no tiene rol
      } else {
        throw Exception('Usuario no encontrado en la base de datos');
      }
    } catch (e) {
      print('Error al obtener rol de usuario: $e');
      return null;
    }
  }



// Método para cargar todos los usuarios de Firestore
Future<List<Map<String, dynamic>>> cargarUsuariosFirestore() async {
  try {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'email': data['email'] ?? '',
        'role': data['role'] ?? 'user',
        'id': doc.id,
      };
    }).toList();
  } catch (e) {
    print('Error al cargar usuarios: $e');
    throw Exception('Error al cargar usuarios: $e');
  }
}

// Método para actualizar el rol de un usuario en Firestore
Future<void> actualizarRolUsuario(String userId, String nuevoRol) async {
  try {
    if (nuevoRol.isEmpty) {
      throw Exception('El rol no puede estar vacío');
    }

    await _firestore.collection('users').doc(userId).update({'role': nuevoRol});
  } catch (e) {
    print('Error al actualizar el rol: $e');
    throw Exception('Error al actualizar el rol: $e');
  }
}

  // registrar usuario
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
  
// actualizar usuario parcialmente (solo los campos proporcionados)
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

// actualizar usuario
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
        data['fechaNacimiento'] = '${partes[0]}-${partes[1].padLeft(2, '0')}-${partes[2].padLeft(2, '0')}';
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
          throw Exception('Ya existe un usuario con el email proporcionado.');
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
      // Extraer el mensaje de error detallado de la respuesta
      String errorMessage = 'Error al actualizar usuario';
      try {
        // Decodificar explícitamente como UTF-8
        final utf8Body = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(utf8Body);
        
        if (errorData is Map && errorData.containsKey('detail')) {
          final detail = errorData['detail'];
          
          // El detalle puede ser una cadena o un array
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            errorMessage = detail[0].toString();
          }
        }
      } catch (decodeError) {
        print('Error al decodificar respuesta: $decodeError');
        errorMessage = response.body;
      }
      
      print('Mensaje de error formatado: $errorMessage');
      throw Exception(errorMessage);
    }
  } catch (e) {
    print('Excepción en actualizar usuario: $e');
    rethrow; // Relanzar la excepción para que se maneje en la interfaz
  }
}

  // eliminar usuario
  Future<void> eliminarUsuario(String documentoIdentidad) async {
    final response = await http.delete(Uri.parse("$_baseUrl/$documentoIdentidad"));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }

  // subir foto
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

// eliminar foto
Future<void> eliminarFotoUsuario(String documentoIdentidad) async {
  final response = await http.delete(Uri.parse("$_baseUrl/$documentoIdentidad/foto"));
  if (response.statusCode != 200) {
    throw Exception('Error al eliminar la foto');
  }
}

  // obtener foto
  Future<String> obtenerFoto(String documentoIdentidad) async {
    final response = await http.get(Uri.parse("$_baseUrl/$documentoIdentidad/foto"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['foto'];
    } else {
      throw Exception('Error al obtener foto');
    }
  }

  // buscar por documento exacto
  Future<Usuario> buscarPorDocumentoExacto(String documentoIdentidad) async {
    final response = await http.get(Uri.parse("$_baseUrl/documento-exacto/$documentoIdentidad"));
    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  // verificar si el usuario existe
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

// buscar usuarios por valor con paginacion
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
        // decodificar explicitamente como UTF-8
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(utf8Body);
        
        // verificar estructura de datos completa
        if (data is Map && data.containsKey('usuarios') && data.containsKey('total')) {
          // convertir los datos a objetos Usuario
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
    // si no se encontraron resultados (404 Not Found u otros codigos de error)
    else {
      print('No se encontraron usuarios para "$valor" - Código: ${response.statusCode}');
      
      //  extraer el mensaje de error
      String mensajeError = "No se encontraron usuarios";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          mensajeError = errorData['detail'];
        }
      } catch (e) {
        print('Error al decodificar mensaje de error: $e');
      }
      
      // devolver una lista vacia y el mensaje de error
      return {
        'usuarios': <Usuario>[],
        'total': 0,
        'mensaje_error': mensajeError
      };
    }
  } catch (e) {
    print('Excepción capturada en buscarUsuariosPorValor: $e');
    // devolver estructura valida incluso en caso de excepcion
    return {
      'usuarios': <Usuario>[],
      'total': 0,
      'mensaje_error': 'Error al realizar la búsqueda: $e'
    };
  }
}

// importar multiples usuarios desde un archivo csv
Future<void> importarUsuarios(List<Map<String, dynamic>> usuarios) async {
  try {
    print('Iniciando importación de usuarios...');
    print('Usuarios a importar: ${usuarios.length}');
    print('URL de la solicitud: $_baseUrl/multiples');
    
    // Imprimir los datos de cada usuario
    for (var usuario in usuarios) {
      print('Datos del usuario: $usuario');
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/multiples"),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({'usuarios': usuarios}),
    );

    print('Respuesta de la API: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      var errorMessage = 'Error al importar usuarios';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'];
        } else if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'];
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      print('Error al importar usuarios: $errorMessage (Código: ${response.statusCode})');
      throw Exception('$errorMessage (Código: ${response.statusCode})');
    } else {
      print('Importación de usuarios exitosa.');
    }
  } catch (e) {
    print('Excepción capturada: $e');
    rethrow;
  }
}



Future<Map<String, dynamic>> enviarUsuariosAlaAPI(List<Map<String, dynamic>> usuarios) async {
  try {
    print('Iniciando importación de usuarios...');
    print('URL de la solicitud: $_baseUrl/multiples');

    // Asegurar que cada usuario tenga los campos correctamente formateados
    List<Map<String, dynamic>> usuariosFormateados = usuarios.map((usuario) {
      // Convertir las claves a snake_case si es necesario
      Map<String, dynamic> usuarioFormateado = {};
      usuario.forEach((key, value) {
        String formattedKey = key;
        if (!key.contains('_')) {
          // Convertir camelCase a snake_case solo si no tiene guiones bajos
          formattedKey = key.replaceAllMapped(
              RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
        }
        usuarioFormateado[formattedKey] = value;
      });
      
      // Asegurarse de que el campo foto esté incluido correctamente
      // Verificar si la foto existe y no es nula antes de verificar si está vacía
      if (usuario.containsKey('foto') && usuario['foto'] != null && usuario['foto'].isNotEmpty) {
        usuarioFormateado['foto'] = usuario['foto'];
      } else {
        // Si no hay foto o es nula, establecerla explícitamente como null
        usuarioFormateado['foto'] = null;
      }
      
      return usuarioFormateado;
    }).toList();

    // Enviar los usuarios formateados a la API
    final response = await http.post(
      Uri.parse("$_baseUrl/multiples"),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(usuariosFormateados),
    );

    print('Respuesta de la API: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      var errorMessage = 'Error al importar usuarios';
      try {
        // Decodificar explícitamente como UTF-8
        final utf8Body = utf8.decode(response.bodyBytes);
        final errorBody = jsonDecode(utf8Body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'];
        } else if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'];
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      print('Error al importar usuarios: $errorMessage (Código: ${response.statusCode})');
      throw Exception('$errorMessage (Código: ${response.statusCode})');
    } else {
      print('Importación de usuarios exitosa.');
      
      // Decodificar explícitamente como UTF-8 para manejar correctamente los caracteres especiales
      final utf8Body = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(utf8Body);
      return responseData; // Devuelve la respuesta completa con los resultados
    }
  } catch (e) {
    print('Excepción capturada: $e');
    rethrow;
  }
}



}




