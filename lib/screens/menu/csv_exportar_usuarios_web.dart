import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> guardarArchivoWeb(String nombreArchivo, List<int> bytes) async {
  final content = base64Encode(bytes);
  final url = 'data:text/csv;charset=utf-8;base64,$content';
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', nombreArchivo)
    ..click();
}
