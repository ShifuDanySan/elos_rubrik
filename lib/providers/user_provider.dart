// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository;

  UserProvider({required this.repository});

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga todos los usuarios desde el repositorio.
  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await repository.fetchAllUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: $e';
      debugPrint(_errorMessage);
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega un nuevo usuario y actualiza la lista localmente y desde la DB.
  Future<void> addUser({
    required String dni,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    try {
      // Usamos el tipoUsuario 2 por defecto, como se indicó en el flujo del proyecto.
      await repository.addUser(
        dni: dni,
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        tipoUsuario: 2,
      );
      // Tras una inserción exitosa, recargamos la lista para obtener los datos actualizados.
      await fetchAllUsers();
    } catch (e) {
      _errorMessage = 'Error al agregar usuario: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      rethrow; // Relanzamos para que la UI pueda manejar el error del formulario
    }
  }

  /// Elimina un usuario por DNI y recarga la lista.
  Future<void> deleteUser(String dni) async {
    try {
      await repository.deleteUser(dni);
      // Recarga la lista para reflejar el cambio en la UI.
      await fetchAllUsers();
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario con DNI $dni: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      // En este caso, simplemente notificamos y el error se mostrará en la UI principal.
    }
  }
}