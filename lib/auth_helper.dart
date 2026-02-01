import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthHelper {
  /// Lógica para cerrar sesión en Firebase y navegar al inicio
  static Future<void> logout(BuildContext context) async {
    try {
      // 1. Cerramos sesión en Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Verificamos que el widget siga montado para evitar errores de contexto
      if (context.mounted) {
        // Mostramos el mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada correctamente'),
            duration: Duration(seconds: 2),
          ),
        );

        // 3. ¡SOLUCIÓN CLAVE!: Forzamos el regreso a la pantalla de Auth inicial.
        // Esto limpia todas las pantallas anteriores (stack) y vuelve a la raíz.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  static Widget logoutButton(BuildContext context, {Color color = Colors.white}) {
    return IconButton(
      icon: Icon(Icons.logout, color: color),
      tooltip: 'Cerrar Sesión',
      onPressed: () => logout(context),
    );
  }
}