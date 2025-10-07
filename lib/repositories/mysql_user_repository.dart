// lib/repositories/mysql_user_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elos_rubrik/config/app_config.dart';
import 'package:elos_rubrik/models/usuario.dart';

class MySQLUserRepository {
  // Cliente HTTP para realizar las peticiones.
  final client = http.Client();
  final String _baseUrl = AppConfig.apiUrl;
  final String _loginPath = AppConfig.loginEndpoint;

  /// Método que realiza la llamada HTTP POST para iniciar sesión.
  ///
  /// Envía el email y la contraseña al servidor y espera un token
  /// y los datos del usuario.
  Future<Map<String, dynamic>> login(String email, String password) async {
    // 1. Construye la URL completa del endpoint de login
    final url = Uri.parse('$_baseUrl$_loginPath');

    // 2. Define el cuerpo (body) de la solicitud como un mapa Dart
    final body = {
      'email': email,
      'password': password,
    };

    try {
      // 3. Realiza la llamada HTTP POST
      final response = await client.post(
        url,
        // Es fundamental indicar al servidor que estamos enviando JSON
        headers: {'Content-Type': 'application/json'},
        // Codifica el mapa Dart a una cadena JSON
        body: json.encode(body),
      );

      // 4. Procesa la respuesta del servidor
      if (response.statusCode == 200) {
        // Login exitoso (código 200 OK)
        final responseBody = json.decode(response.body);

        // Retorna un mapa con éxito y los datos importantes
        return {
          'success': true,
          'message': responseBody['message'],
          'token': responseBody['token'] as String, // Token para la sesión
          'user': Usuario.fromJson(responseBody['user']),
        };
      } else {
        // Errores de API (ej: 401 No Autorizado, 400 Bad Request)
        // Se asume que el servidor devuelve un cuerpo JSON con un mensaje de error
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'message': errorBody['message'] ?? 'Credenciales inválidas o error desconocido.',
          'token': null,
          'user': null,
        };
      }
    } catch (e) {
      // Errores de conexión de red, timeout, o formato de respuesta inválido
      print('Error de red/petición: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifica la URL de la API y tu red.',
        'token': null,
        'user': null,
      };
    }
  }

  /// Placeholder para el método que validará el token de sesión.
  Future<Usuario?> validateToken(String token) async {
    // Implementación futura que usará un GET o POST con el token en los headers.
    return null;
  }
}}