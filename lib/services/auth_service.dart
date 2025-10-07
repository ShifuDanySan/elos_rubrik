// lib/services/auth_service.dart
import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/usuario.dart';
import 'db_connector.dart';

/// Clase de servicio para gestionar la autenticación mediante conexión directa a MySQL.
///
/// ASUMPCIÓN DE ESQUEMA DE BASE DE DATOS (tabla 'usuarios'):
/// id_usuario, nombres, apellidos, dni, email, password_hash, tipo_usuario.
class AuthService {

  // Función de utilidad para hashear la contraseña
  // NOTA: Usa el mismo algoritmo de hashing (ej. SHA256) que usas en tu base de datos MySQL.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Inicia sesión verificando las credenciales directamente en MySQL usando DNI y Contraseña.
  /// Lanza una excepción si las credenciales son inválidas o hay un error de DB.
  Future<Usuario> login(String dni, String password) async {
    final conn = await DbConnector.getConnection();
    final hashedPassword = _hashPassword(password);

    // CONSULTA ACTUALIZADA: Verifica las credenciales usando DNI y password_hash.
    final results = await conn.query(
      'SELECT id_usuario, nombres, apellidos, dni, email, tipo_usuario FROM usuarios WHERE dni = ? AND password_hash = ?',
      [dni, hashedPassword],
    );

    if (results.isEmpty) {
      throw Exception('Credenciales inválidas. Verifique su DNI y contraseña.');
    }

    final row = results.first;
    // Token simulado: se mantendrá hasta que se implemente el API REST con JWT.
    const String simulatedToken = 'mysql_direct_access_token';

    return Usuario.fromMySQLRow(row, simulatedToken);
  }

  /// Registra un nuevo usuario en la base de datos MySQL.
  /// Lanza una excepción si el correo/DNI ya existen o hay otro error.
  Future<Usuario> register({
    required String nombres,
    required String apellidos,
    required String dni,
    required String email,
    required String password,
  }) async {
    final conn = await DbConnector.getConnection();
    final hashedPassword = _hashPassword(password);

    try {
      // 1. Insertar el nuevo usuario en la tabla
      final result = await conn.query(
        'INSERT INTO usuarios (nombres, apellidos, dni, email, password_hash, tipo_usuario) VALUES (?, ?, ?, ?, ?, ?)',
        [nombres, apellidos, dni, email, hashedPassword, 2], // 2: Tipo de usuario Estándar
      );

      final newId = result.insertId.toString();
      if (newId == '0') {
        throw Exception('Error al obtener el ID del nuevo usuario registrado.');
      }

      const String simulatedToken = 'mysql_direct_access_token';

      // 2. Retornar el objeto Usuario creado
      return Usuario(
        id: newId,
        nombres: nombres,
        apellidos: apellidos,
        dni: dni,
        email: email,
        tipoUsuario: 2,
        token: simulatedToken,
      );

    } on MySqlException catch (e) {
      // Manejo de error de clave duplicada (Duplicate entry)
      if (e.message.contains('Duplicate entry')) {
        throw Exception('El correo o DNI ya están registrados. Intente iniciar sesión.');
      }
      print('Error de MySQL en registro: $e');
      throw Exception('Error de base de datos al registrar: ${e.message}');
    } catch (e) {
      print('Error desconocido en registro: $e');
      rethrow;
    }
  }

  /// Simulación de restablecimiento de contraseña.
  Future<void> requestPasswordReset(String email) async {
    final conn = await DbConnector.getConnection();
    final results = await conn.query(
      'SELECT id_usuario FROM usuarios WHERE email = ?',
      [email],
    );

    if (results.isEmpty) {
      // Mensaje de seguridad genérico
      throw Exception('Si la cuenta existe, recibirá instrucciones para el restablecimiento.');
    }
    // Simulación de proceso exitoso
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
}