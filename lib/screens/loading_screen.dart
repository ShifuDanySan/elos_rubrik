//lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importamos el gestor de sesión. Asegúrate que esta ruta es correcta.
import '../managers/session_manager.dart';
// Importamos las pantallas a las que navegaremos.
import 'auth_wrapper.dart'; // La pantalla que decide si mostrar Login o Home
import 'user_management_screen.dart'; // Si necesitas una ruta directa a gestión

/// Pantalla de carga inicial que verifica la sesión y el estado de la aplicación.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Llamamos a la lógica de verificación de sesión al iniciar la pantalla.
    _checkSessionAndNavigate();
  }

  /// Lógica para verificar el estado de la sesión y redirigir al usuario.
  Future<void> _checkSessionAndNavigate() async {
    // Retraso simulado para ver la pantalla de carga, eliminar en producción si es muy rápido.
    await Future.delayed(const Duration(milliseconds: 1500));

    // Obtenemos el SessionManager usando `read` para no escuchar cambios aquí.
    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    // Intentamos cargar cualquier usuario guardado.
    await sessionManager.getUser();

    // Después de verificar, navegamos a la pantalla principal de autenticación.
    // Usamos `pushReplacement` para que el usuario no pueda volver a esta pantalla
    // presionando el botón de retroceso.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Indicador de carga visual
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}