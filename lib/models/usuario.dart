/// Clase modelo para representar a un Usuario en el sistema.
class Usuario {
  final String dni;
  final String nombre;
  final String apellido;
  final String email;
  final String tipoUsuario;
  // Nota: La contraseña no se almacena aquí por seguridad.

  Usuario({
    required this.dni,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.tipoUsuario,
  });

  /// Factory constructor para crear una instancia de Usuario a partir de un mapa JSON.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      dni: json['dni'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      tipoUsuario: json['tipoUsuario'] as String,
    );
  }
}

/// Clase modelo para el resultado de una autenticación exitosa.
/// Contiene el token de sesión y los datos del usuario.
class AuthResult {
  final String token;
  final Usuario user;

  AuthResult({
    required this.token,
    required this.user,
  });

  /// Factory constructor para crear una instancia de AuthResult a partir de un mapa JSON.
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      // Los datos del usuario vienen anidados
      user: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}