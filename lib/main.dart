import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'profile_edit_screen.dart'; // Asegúrate de que este archivo existe

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ESCUCHADOR GLOBAL: Detecta el cambio de mail y actualiza la base de datos
  FirebaseAuth.instance.userChanges().listen((User? user) async {
    if (user != null) {
      try {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null && updatedUser.email != null) {
          final docRef = FirebaseFirestore.instance.collection('usuarios').doc(updatedUser.uid);

          // Actualiza Firestore de forma radical
          await docRef.update({'email': updatedUser.email});
          debugPrint("SINCRO EXITOSA: ${updatedUser.email}");
        }
      } catch (e) {
        // Si el token caduca (Error 400), cerramos sesión para limpiar el estado
        debugPrint("Token expirado o error de sesión. Re-login necesario.");
        await FirebaseAuth.instance.signOut();
      }
    }
  });

  runApp(const MyApp());
}

// ESTA ES LA CLASE QUE FALTABA
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elos Rubrik',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3949AB)),
        useMaterial3: true,
      ),
      // Redirige a tu pantalla de perfil o login
      home: const ProfileEditScreen(),
    );
  }
}