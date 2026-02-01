// lista_rubricas_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'evaluar_rubrica_screen.dart';
import 'crear_rubrica_screen.dart';
import 'auth_helper.dart';

// ===============================================
// CONSTANTES DE ENTORNO (Sincronizadas)
// ===============================================
const String __app_id = 'rubrica_evaluator'; // ✅ VALOR CORREGIDO Y SINCRONIZADO

// Colores consistentes
const Color primaryColor = Color(0xFF00796B); // Teal oscuro
const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
const Color errorColor = Color(0xFFEF5350); // Rojo Error
const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50 (Fondo)


class ListaRubricasScreen extends StatelessWidget {
  const ListaRubricasScreen({super.key});

  // ----------------------------------------------------
  // 1. Lógica de Carga de Rúbricas (Firestore)
  // ----------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchRubricasStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    // Ruta de la colección: artifacts/{appId}/users/{userId}/rubricas
    final collectionPath = 'artifacts/$__app_id/users/$userId/rubricas';

    // Usamos Stream para obtener actualizaciones en tiempo real
    return FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('fechaCreacion', descending: true)
        .snapshots();
  }

  // ----------------------------------------------------
  // 2. Navegación
  // ----------------------------------------------------

  void _navegarACrearRubrica(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CrearRubricaScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mis Rúbricas'),
        // El estilo viene del main.dart, pero añadimos las acciones:
        actions: [
          AuthHelper.logoutButton(context), // <--- 2. AGREGAR EL BOTÓN AQUÍ
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fetchRubricasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error al cargar rúbricas: ${snapshot.error}', style: const TextStyle(color: errorColor)),
            ));
          }

          final rubricaDocs = snapshot.data?.docs ?? [];

          if (rubricaDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 80, color: primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'Aún no has creado ninguna rúbrica.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Usa el botón "+" para empezar a crear la tuya.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Muestra la lista de rúbricas
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0, top: 16.0),
            itemCount: rubricaDocs.length,
            itemBuilder: (context, index) {
              final rubricaData = rubricaDocs[index].data();
              final rubricaId = rubricaDocs[index].id;
              final nombre = rubricaData['nombre'] ?? 'Rúbrica sin nombre';
              final fecha = (rubricaData['fechaCreacion'] as Timestamp?)?.toDate();
              final fechaStr = fecha != null ? 'Creada: ${fecha.day}/${fecha.month}/${fecha.year}' : '';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(fechaStr),
                  trailing: const Icon(Icons.arrow_forward_ios, color: primaryColor),
                  onTap: () {
                    final Map<String, dynamic> fullRubricaData = {
                      ...rubricaData,
                      'docId': rubricaId,
                    };

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EvaluarRubricaScreen(rubrica: fullRubricaData),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}