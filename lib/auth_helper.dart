import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthHelper {
  /// Lógica para cerrar sesión con limpieza profunda de caché y estado
  static Future<void> logout(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada correctamente'),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );

        // LIMPIEZA TOTAL (Shift + F5): Reinicia la app desde la raíz
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Botón minimalista para evitar errores de Overflow
  static Widget logoutButton(BuildContext context, {Color color = Colors.redAccent}) {
    return IconButton(
      icon: Icon(Icons.logout, color: color),
      tooltip: 'Cerrar Sesión',
      onPressed: () => logout(context),
    );
  }
}