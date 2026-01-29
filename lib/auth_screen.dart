import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; // Importa la pantalla principal
import 'login_register_screen.dart'; // Importa la pantalla de login/registro

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // Estilo consistente de colores
  final Color primaryColor = const Color(0xFF3949AB); // Índigo oscuro
  final Color accentColor = const Color(0xFF7986CB); // Índigo claro

  // Widget para el estado de carga
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador de carga estilizado
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 5.0,
            ),
            const SizedBox(height: 20),
            Text(
              'Verificando sesión...',
              style: TextStyle(
                fontSize: 18,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el estado de error
  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error de Sistema'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ha ocurrido un error al intentar verificar el estado de autenticación.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                'Detalle: ${error.toString()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Text(
                'Por favor, reinicie la aplicación o contacte a soporte.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha los cambios en el estado de autenticación de Firebase.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 1. Manejo de Errores
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error!);
        }

        // 2. Estado de carga: Muestra un indicador mientras Firebase verifica la sesión.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // 3. Usuario autenticado: Si snapshot.hasData (y el valor NO es null)
        final user = snapshot.data;
        if (user != null) {
          // Si el usuario está logueado, muestra la pantalla de inicio (Home).
          return const HomeScreen();
        }

        // 4. Usuario NO autenticado: Si el valor es null (sesión cerrada o nunca iniciada)
        else {
          // Si no hay usuario logueado, muestra la pantalla de Login/Registro.
          return const LoginRegisterScreen();
        }
      },
    );
  }
}