import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Importa las localizaciones de Flutter
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth_screen.dart'; // Mantiene la pantalla de autenticación como inicio
// Importa tus opciones de Firebase. Asegúrate de que 'firebase_options.dart' exista.
import 'firebase_options.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de usar await
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa Firebase con las opciones de la plataforma actual
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Manejo de errores de inicialización de Firebase (puedes añadir logging aquí)
    print('Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elos-Rubrik App',

      // Elimina la cinta roja 'DEBUG'
      debugShowCheckedModeBanner: false,

      // --- CONFIGURACIÓN DE TEMA VISTOSA (MD3) ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Color base para el esquema
          brightness: Brightness.light,
          primary: Colors.indigo.shade700,
          secondary: Colors.pinkAccent.shade100,
          background: Colors.grey.shade50,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // CORRECCIÓN AQUÍ: Usar CardThemeData en lugar de CardTheme
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        // Estilo de botones elevado (elevated button)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
          ),
        ),
      ),

      // --- CONFIGURACIÓN DE LOCALIZACIÓN (Para el DatePicker) ---
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'ES'),
      // -------------------------------------------------------------

      home: const AuthScreen(),
    );
  }
}