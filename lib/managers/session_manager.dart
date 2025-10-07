import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../repositories/mysql_user_repository.dart';

/// Clave para guardar el token de sesión en SharedPreferences
const String _sessionTokenKey = 'sessionToken';

/// Clase que gestiona el estado de la sesión de usuario y la autenticación.
/// Implementa ChangeNotifier para notificar a los widgets (Provider).
class SessionManager extends ChangeNotifier {
  final MySqlUserRepository _userRepository;

  // Estado interno
  Usuario? _currentUser;
  bool _isInitialized = false;

  SessionManager({required MySqlUserRepository userRepository})
      : _userRepository = userRepository {
    // Inicia el proceso de carga de la sesión al construir el manager
    _initializeSession();
  }

  // --- Getters Públicos para el estado ---

  /// Retorna el usuario actualmente autenticado (puede ser null).
  Usuario? get currentUser => _currentUser;

  /// Retorna si hay un usuario autenticado.
  bool get isAuthenticated => _currentUser != null;

  /// Retorna si el SessionManager ha terminado de verificar el estado inicial.
  bool get isInitialized => _isInitialized;


  // --- Ciclo de Vida de la Sesión ---

  /// 1. Inicializa la sesión: verifica si existe un token guardado.
  Future<void> _initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionTokenKey);

      if (token != null && token.isNotEmpty) {
        // Si hay un token, intenta validarlo y obtener los datos del usuario.
        await _validateTokenAndLoadUser(token);
      }
    } catch (e) {
      // Manejar cualquier error durante la inicialización (ej. error de I/O)
      print('Error during session initialization: $e');
      _clearSessionState();
    } finally {
      // Siempre establecer a true para terminar el estado de 'LoadingScreen'
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Intenta validar un token con la API y cargar el usuario.
  Future<void> _validateTokenAndLoadUser(String token) async {
    try {
      final user = await _userRepository.getUserByToken(token);
      if (user != null) {
        _currentUser = user;
        // Importante: Asegurar que el token se mantiene en el repositorio para futuras llamadas
        _userRepository.setCurrentToken(token);
        print('Sesión reanudada para el usuario: ${user.dni}');
      } else {
        // Token inválido o expirado, limpiar la sesión
        await _clearSavedToken();
      }
    } catch (e) {
      print('Token validation failed: $e');
      await _clearSavedToken();
    }
  }

  // --- Métodos de Autenticación (Login/Logout) ---

  /// 2. Inicia sesión con DNI y contraseña.
  /// Retorna true si el login fue exitoso y false si falló por credenciales inválidas.
  Future<bool> login(String dni, String password) async {
    try {
      final authResult = await _userRepository.login(dni, password);

      if (authResult != null) {
        final token = authResult.token;
        final user = authResult.user;

        // 1. Guardar el token de forma persistente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionTokenKey, token);

        // 2. Actualizar el estado del Manager
        _currentUser = user;
        _userRepository.setCurrentToken(token); // Establecer el token para futuras llamadas
        notifyListeners();

        print('Inicio de sesión exitoso para ${user.dni}');
        return true;
      }

      // Si authResult es null, las credenciales son inválidas
      return false;

    } catch (e) {
      // Propagar el error para que la UI lo maneje (ej. error de red)
      rethrow;
    }
  }

  /// 3. Cierra la sesión del usuario.
  Future<void> logout() async {
    try {
      // Opcional: Notificar al servidor del logout
      // await _userRepository.logout();

      // 1. Limpiar el token guardado
      await _clearSavedToken();

      // 2. Limpiar el estado del Manager
      _clearSessionState();

      print('Sesión cerrada.');
    } catch (e) {
      print('Error during logout: $e');
      _clearSessionState(); // Asegurarse de limpiar el estado local
    }
  }

  // --- Métodos Privados de Limpieza ---

  /// Limpia el estado local del Manager.
  void _clearSessionState() {
    _currentUser = null;
    _userRepository.clearToken();
    notifyListeners();
  }

  /// Elimina el token de SharedPreferences.
  Future<void> _clearSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
  }
}