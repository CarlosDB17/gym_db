class Usuario {
  final String nombre;
  final String email;
  final String documentoIdentidad;
  final String fechaNacimiento;
  final String? foto;

  Usuario({
    required this.nombre,
    required this.email,
    required this.documentoIdentidad,
    required this.fechaNacimiento,
    this.foto,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombre: json['nombre'],
      email: json['email'],
      documentoIdentidad: json['documento_identidad'],
      fechaNacimiento: json['fecha_nacimiento'],
      foto: json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'documento_identidad': documentoIdentidad,
      'fecha_nacimiento': fechaNacimiento,
      if (foto != null) 'foto': foto,
    };
  }
}
