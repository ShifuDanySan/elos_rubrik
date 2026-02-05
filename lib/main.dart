// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'profile_edit_screen.dart'; // Tu pantalla de perfil

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // INICIO DE LA SOLUCIÓN RADICAL
  // Este "listener" escucha cambios en el usuario (incluyendo la verificación de email)
  FirebaseAuth.instance.userChanges().listen((User? user) async {
    if (user != null) {
      // Forzamos la recarga para verificar si el link del mail ya hizo efecto
      await user.reload();
      final userActualizado = FirebaseAuth.instance.currentUser;

      if (userActualizado != null && userActualizado.email != null) {
        final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userActualizado.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          final emailEnFirestore = doc.data()?['email'];

          // Si el email de Auth es distinto al de la base de datos, corregimos de inmediato
          if (userActualizado.email != emailEnFirestore) {
            await docRef.update({'email': userActualizado.email});
            debugPrint("SINCRO RADICAL: Base de datos actualizada con el nuevo mail: ${userActualizado.email}");
          }
        }
      }
    }
  });
  // FIN DE LA SOLUCIÓN RADICAL

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elos Rubrik',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // Aquí rediriges a tu pantalla inicial o de login
      home: const ProfileEditScreen(),
    );
  }
}