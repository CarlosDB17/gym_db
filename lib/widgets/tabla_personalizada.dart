import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TablaPersonalizada<T> extends StatelessWidget {
  final List<DataColumn> columnas;
  final List<T> datos;
  final DataRow Function(T) crearFila;
  final int paginaActual;
  final int totalPaginas;
  final Function(int) cambiarPagina;
  final bool mostrarPaginacion;
  final String? mensajeAyuda;

  const TablaPersonalizada({
    super.key,
    required this.columnas,
    required this.datos,
    required this.crearFila,
    required this.paginaActual,
    required this.totalPaginas,
    required this.cambiarPagina,
    this.mostrarPaginacion = true,
    this.mensajeAyuda,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Tabla
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.verdeVibrante.withAlpha((0.2 * 255).toInt())
                  ),
                  columnSpacing: 20,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  headingTextStyle: const TextStyle(
                    color: AppColors.verdeOscuro,
                    fontWeight: FontWeight.bold,
                  ),
                  columns: columnas,
                  rows: datos.map((item) => crearFila(item)).toList(),
                ),
              ),
            ),
          ),

          // Mensaje de ayuda
          if (mensajeAyuda != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                mensajeAyuda!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),

          // Controles de paginación
          if (mostrarPaginacion && totalPaginas > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: paginaActual > 0
                      ? () => cambiarPagina(-1)
                      : null,
                    icon: Icon(
                      Icons.arrow_back,
                      color: paginaActual > 0
                        ? AppColors.verdeOscuro
                        : Colors.grey,
                    ),
                  ),
                  Text(
                    'Página ${paginaActual + 1} / $totalPaginas',
                    style: const TextStyle(color: AppColors.verdeOscuro),
                  ),
                  IconButton(
                    onPressed: (paginaActual + 1) < totalPaginas
                      ? () => cambiarPagina(1)
                      : null,
                    icon: Icon(
                      Icons.arrow_forward,
                      color: (paginaActual + 1) < totalPaginas
                        ? AppColors.verdeOscuro
                        : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}