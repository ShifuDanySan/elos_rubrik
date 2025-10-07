// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/session_manager.dart'; // Importa el manejador de sesión
import '../models/usuario.dart'; // Importa el modelo de usuario

/// Pantalla principal que se muestra al usuario autenticado.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el SessionManager para obtener el usuario actual.
    final sessionManager = Provider.of<SessionManager>(context);
    final Usuario? user = sessionManager.currentUser;

    // Si por alguna razón el usuario es nulo (no debería pasar aquí si el AuthWrapper funciona),
    // muestra un mensaje de error o un spinner.
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: No se encontró la sesión del usuario.'),
        ),
      );
    }

    // Retorna la interfaz de usuario de la pantalla de inicio.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido al Sistema'),
        backgroundColor: Colors.indigo,
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Llama al método logout() del SessionManager
              sessionManager.logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.person_pin,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),

            // Muestra el nombre completo usando el getter del modelo Usuario
            Text(
              'Hola, ${user.nombreCompleto}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Has iniciado sesión con éxito!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),

            const Divider(height: 32, thickness: 1),

            // Detalles de la sesión del usuario
            _buildDetailRow(
              icon: Icons.badge,
              title: 'DNI/ID:',
              value: user.dni,
            ),
            _buildDetailRow(
              icon: Icons.email,
              title: 'Correo Electrónico:',
              value: user.email,
            ),
            _buildDetailRow(
              icon: Icons.groups,
              title: 'Tipo de Usuario:',
              // Muestra el tipo de usuario con un texto descriptivo
              value: _getTipoUsuarioText(user.tipoUsuario),
            ),
            // Muestra el token de forma opcional (útil para debug)
            if (user.token != null && user.token!.isNotEmpty)
              _buildDetailRow(
                icon: Icons.vpn_key,
                title: 'Token de Sesión:',
                value: user.token!,
              ),
          ],
        ),
      ),
    );
  }

  /// Helper para construir una fila de detalles de usuario.
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Convierte el entero tipoUsuario a una cadena legible.
  String _getTipoUsuarioText(int tipo) {
    switch (tipo) {
      case 1:
        return 'Administrador';
      case 2:
        return 'Usuario Estándar';
      case 3:
        return 'Invitado';
      default:
        return 'Desconocido ($tipo)';
    }
  }
}