// lib/main.dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elos_rubrik/providers/auth_provider.dart';

// Importaremos una pantalla temporal para el Home y el Login (que crearemos luego)
import 'package:elos_rubrik/screens/home_screen.dart';
import 'package:elos_rubrik/screens/login_screen.dart';
import 'package:elos_rubrik/config/app_config.dart';


void main() {
  // Inicializamos la configuración de la aplicación (URL de la API, etc.)
  // Aunque en este caso es una clase estática, es buena práctica llamarla.
  AppConfig.initialize();

  runApp(
    // 1. Usamos MultiProvider para inyectar nuestro AuthProvider
    MultiProvider(
      providers: [
        // Creamos una instancia de AuthProvider que estará disponible
        // en todo el árbol de widgets.
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeSession()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MySQL Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 2. Usamos el Widget de Consumo para determinar qué pantalla mostrar.
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Si el proveedor está cargando (ej. validando token), muestra un spinner.
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Iniciando sesión...'),
                  ],
                ),
              ),
            );
          }

          // Si el usuario está autenticado, muestra la pantalla principal.
          if (auth.isAuthenticated) {
            return const HomeScreen();
          }

          // Si no está autenticado, muestra la pantalla de login.
          return const LoginScreen();
        },
      ),
    );
  }
}