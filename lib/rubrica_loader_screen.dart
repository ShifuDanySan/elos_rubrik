import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'evaluar_rubrica_screen.dart'; // Importa tu archivo de evaluación

// ==========================================================
// FUNCIÓN PARA FETCH DE DATOS DESDE FIRESTORE
// ==========================================================
Future<Map<String, dynamic>> fetchRubricaDesdeFirestore(String rubricaId) async {
  // Asegúrate de que Firebase ha sido inicializado antes de esta llamada
  final docSnapshot = await FirebaseFirestore.instance
      .collection('rubricas')
      .doc(rubricaId)
      .get();

  if (docSnapshot.exists && docSnapshot.data() != null) {
    // Devolvemos los datos del documento y su ID, ya que el ID será
    // crucial para guardar la evaluación y hacer referencia a la rúbrica.
    return {
      ...docSnapshot.data()!,
      'docId': docSnapshot.id
    };
  } else {
    throw Exception('La rúbrica con ID $rubricaId no fue encontrada en Firestore.');
  }
}

class RubricaLoaderScreen extends StatelessWidget {
  // Reemplace 'id_de_ejemplo' con la forma en que obtienes el ID
  // (e.g., si lo pasas desde una pantalla de lista).
  final String rubricaId = 'ID_DEL_DOCUMENTO_DE_LA_RUBRICA';

  const RubricaLoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargando Rúbrica...')),
      body: FutureBuilder<Map<String, dynamic>>(
        // Llama a la función de Firebase para obtener la rúbrica
        future: fetchRubricaDesdeFirestore(rubricaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar la rúbrica: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            // ¡Éxito! La rúbrica está lista, la pasamos a la pantalla de evaluación.
            return EvaluarRubricaScreen(rubrica: snapshot.data!);
          } else {
            return const Center(child: Text('Rúbrica no encontrada.'));
          }
        },
      ),
    );
  }
}