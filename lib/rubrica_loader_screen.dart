// rubrica_loader_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'evaluar_rubrica_screen.dart';
import 'auth_helper.dart'; // <--- 1. IMPORTAR HELPER

Future<Map<String, dynamic>> fetchRubricaDesdeFirestore(String rubricaId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('rubricas')
      .doc(rubricaId)
      .get();

  if (docSnapshot.exists && docSnapshot.data() != null) {
    return {
      ...docSnapshot.data()!,
      'docId': docSnapshot.id
    };
  } else {
    throw Exception('La rúbrica no fue encontrada.');
  }
}

class RubricaLoaderScreen extends StatelessWidget {
  final String rubricaId = 'ID_DEL_DOCUMENTO_DE_LA_RUBRICA';

  const RubricaLoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargando Rúbrica...'),
        // 2. AÑADIR ACTIONS AQUÍ (Dentro del AppBar)
        actions: [
          AuthHelper.logoutButton(context),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchRubricaDesdeFirestore(rubricaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return EvaluarRubricaScreen(rubrica: snapshot.data!);
          } else {
            return const Center(child: Text('No hay datos'));
          }
        },
      ),
    );
  }
}