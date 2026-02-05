import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; // Importa la pantalla principal
import 'login_register_screen.dart'; // Importa la pantalla de login/registro

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // Estilo consistente de colores
  final Color primaryColor = const Color(0xFF3949AB); // Índigo oscuro
  final Color accentColor = const Color(0xFF7986CB); // Índigo claro

  // Widget para el estado de carga con el círculo resaltado
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Un gris muy tenue para que el blanco resalte
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo blanco contenedor para resaltar el indicador
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 5.0,
              ),
            ),
            const SizedBox(height: 30),
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error!);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final user = snapshot.data;
        if (user != null) {
          return const HomeScreen();
        } else {
          return const LoginRegisterScreen();
        }
      },
    );
  }
}