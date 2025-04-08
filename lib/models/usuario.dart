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
  
  // Método para crear un mapa con valores para actualización parcial
  // Solo incluye los campos que se proporcionan, lo que permite actualizaciones selectivas
  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    String? email,
    String? fechaNacimiento,
    String? foto,
  }) {
    final Map<String, dynamic> updateData = {};
    
    if (nombre != null) updateData['nombre'] = nombre;
    if (email != null) updateData['email'] = email;
    if (fechaNacimiento != null) updateData['fecha_nacimiento'] = fechaNacimiento;
    if (foto != null) updateData['foto'] = foto;
    
    return updateData;
  }
  
  // Método para crear una copia del usuario con campos actualizados
  Usuario copyWith({
    String? nombre,
    String? email,
    String? documentoIdentidad,
    String? fechaNacimiento,
    String? foto,
  }) {
    return Usuario(
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      documentoIdentidad: documentoIdentidad ?? this.documentoIdentidad,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      foto: foto ?? this.foto,
    );
  }
}
