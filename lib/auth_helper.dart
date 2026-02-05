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

  /// Botón con círculo blanco resaltado para evitar errores de Overflow y mejorar visibilidad
  static Widget logoutButton(BuildContext context, {Color color = Colors.redAccent}) {
    return Container(
      margin: const EdgeInsets.all(8), // Espacio para que no toque los bordes
      decoration: BoxDecoration(
        color: Colors.white, // Círculo blanco de fondo
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.logout, color: color, size: 20), // Icono ligeramente más pequeño para el círculo
        tooltip: 'Cerrar Sesión',
        onPressed: () => logout(context),
      ),
    );
  }
}