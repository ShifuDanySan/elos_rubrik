import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/usuario.dart';

/// URL base de la API de autenticación.
const String _baseUrl = 'https://api.example.com/auth'; // Reemplaza con tu URL real

/// Repositorio encargado de interactuar con la API para la gestión de usuarios
/// y autenticación.
class MySqlUserRepository {
  String? _currentToken;

  /// Retorna el token de sesión actual.
  String? get currentToken => _currentToken;

  /// Establece el token de sesión actual para usar en peticiones futuras.
  void setCurrentToken(String token) {
    _currentToken = token;
  }

  /// Limpia el token de sesión.
  void clearToken() {
    _currentToken = null;
  }

  /// Realiza la solicitud de inicio de sesión con DNI y contraseña.
  /// Retorna AuthResult si es exitoso, o null si las credenciales son incorrectas.
  /// Lanza una excepción en caso de error de red o servidor.
  Future<AuthResult?> login(String dni, String password) async {
    final uri = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dni': dni, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Éxito: retorna el token y el usuario
        final json = jsonDecode(response.body);
        return AuthResult.fromJson(json);
      } else if (response.statusCode == 401) {
        // No autorizado: credenciales inválidas
        return null;
      } else {
        // Otro error del servidor
        throw Exception('Fallo al iniciar sesión. Código: ${response.statusCode}');
      }
    } catch (e) {
      // Error de red, timeout, etc.
      throw Exception('Error de conexión al servidor: $e');
    }
  }

  /// Valida un token existente y obtiene los datos del usuario asociado.
  /// Retorna el Usuario si el token es válido, o null si es inválido/expirado.
  Future<Usuario?> getUserByToken(String token) async {
    final uri = Uri.parse('$_baseUrl/validate');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Token válido: establece el token en el repositorio y retorna el usuario
        final json = jsonDecode(response.body);
        setCurrentToken(token); // Refresca el token en el repositorio
        return Usuario.fromJson(json['usuario']);
      } else if (response.statusCode == 401) {
        // Token inválido/expirado
        return null;
      } else {
        throw Exception('Fallo al validar token. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al validar el token: $e');
    }
  }

// Puedes añadir aquí otros métodos como register, updatePassword, etc.
}