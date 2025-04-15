import 'dart:convert';
import 'package:web/web.dart' as web;

Future<void> guardarArchivoWeb(String nombreArchivo, List<int> bytes) async {
  final content = base64Encode(bytes);
  final url = 'data:text/csv;charset=utf-8;base64,$content';

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = nombreArchivo;

  // Necesario para que funcione el click
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
