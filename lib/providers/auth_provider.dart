// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:elos_rubrik/models/usuario.dart';
import 'package:elos_rubrik/repositories/mysql_user_repository.dart';

// El AuthProvider usa ChangeNotifier para gestionar el estado de autenticación
class AuthProvider with ChangeNotifier {
  // Repositorio para interactuar con la API
  final MySQLUserRepository _userRepository = MySQLUserRepository();

  // Estado privado: El usuario actualmente autenticado (puede ser null)
  Usuario? _user;

  // Estado privado: El token de sesión proporcionado por la API
  String? _token;

  // Estado privado para manejar la carga (loading) durante la petición
  bool _isLoading = false;

  // --- Getters Públicos ---

  /// Devuelve el usuario autenticado.
  Usuario? get user => _user;

  /// Devuelve el estado de carga.
  bool get isLoading => _isLoading;

  /// Retorna true si hay un usuario y un token, indicando que la sesión está activa.
  bool get isAuthenticated => _user != null && _token != null;

  // --- Lógica de Negocio ---

  /// Intenta iniciar sesión con el email y la contraseña proporcionados.
  ///
  /// Retorna un mensaje de error si el login falla, o null si es exitoso.
  Future<String?> login(String email, String password) async {
    _setLoading(true); // Inicia el estado de carga

    final result = await _userRepository.login(email, password);

    if (result['success'] == true) {
      // Éxito: Guarda el usuario y el token
      _user = result['user'] as Usuario;
      _token = result['token'] as String;

      // NOTA: En una app real, aquí guardaríamos el token en un
      // almacenamiento seguro (como SharedPreferences o FlutterSecureStorage)

      _setLoading(false);
      return null; // Retorna null si no hay error
    } else {
      // Error: Limpia cualquier estado de usuario residual
      _user = null;
      _token = null;

      _setLoading(false);
      // Retorna el mensaje de error para mostrar en la UI
      return result['message'] as String;
    }
  }

  /// Cierra la sesión, eliminando los datos del usuario y el token.
  void logout() {
    _user = null;
    _token = null;
    // NOTA: En una app real, aquí también eliminaríamos el token del almacenamiento seguro.
    notifyListeners();
  }

  /// Método privado para manejar el estado de carga y notificar a los listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- Inicialización (Validación de token al inicio) ---

  /// Método para verificar si hay un token guardado al iniciar la app
  /// y validarlo con el servidor.
  Future<void> initializeSession() async {
    _setLoading(true);

    // 1. Obtener el token guardado (simulado, en realidad se leería del storage)
    // String? savedToken = await _readTokenFromStorage();
    String? savedToken = null; // Simulamos que no hay token al inicio

    if (savedToken != null) {
      // 2. Si hay un token, intenta validarlo con el servidor
      final validatedUser = await _userRepository.validateToken(savedToken);

      if (validatedUser != null) {
        // Token válido: el usuario se autentica automáticamente
        _user = validatedUser;
        _token = savedToken;
      } else {
        // Token inválido/expirado: forzar logout
        // _deleteTokenFromStorage();
        _user = null;
        _token = null;
      }
    }

    _setLoading(false);
  }
}