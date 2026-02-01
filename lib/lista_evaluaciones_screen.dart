// lista_evaluaciones_screen.dart (Versión Final Corregida para Firestore)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NECESARIO
import 'package:firebase_auth/firebase_auth.dart'; // NECESARIO
import 'detalle_evaluacion_screen.dart';
import 'auth_helper.dart';

// ===============================================
// CONSTANTES DE ENTORNO Y ESTILO
// ===============================================
const String __app_id = 'rubrica_evaluator'; // Sincronizada

// Colores consistentes
const Color primaryColor = Color(0xFF00796B); // Teal oscuro
const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
const Color errorColor = Color(0xFFEF5350); // Rojo Error
const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia

// ===============================================

// Cambiamos a StatelessWidget ya que la data viene de un Stream
class ListaEvaluacionesScreen extends StatelessWidget {
  const ListaEvaluacionesScreen({super.key});

  // ----------------------------------------------------
  // 1. Lógica de Carga de Evaluaciones (Firestore)
  // ----------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchEvaluacionesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Retorna un stream vacío si no hay usuario
      return const Stream.empty();
    }

    // Ruta de la colección: artifacts/{appId}/users/{userId}/evaluaciones
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(__app_id)
        .collection('users')
        .doc(userId)
        .collection('evaluaciones')
    // Ordenar por fecha, lo más reciente primero
        .orderBy('fechaEvaluacion', descending: true)
        .snapshots();
  }

  // ----------------------------------------------------
  // 2. Navegación al Detalle
  // ----------------------------------------------------
  void _verDetalleEvaluacion(BuildContext context, Map<String, dynamic> evaluacion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEvaluacionScreen(evaluacionData: evaluacion),
      ),
    );
  }

  // ----------------------------------------------------
  // 3. Widget Auxiliar de Estilo
  // ----------------------------------------------------
  Color _getNotaColor(double nota) {
    if (nota >= 0.9) return accentColor;
    if (nota >= 0.7) return primaryColor;
    if (nota >= 0.5) return warningColor;
    return errorColor;
  }

  // ----------------------------------------------------
  // 4. Construcción de la Interfaz con StreamBuilder
  // ----------------------------------------------------
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Evaluaciones'),
        // 2. AGREGAR EL BOTÓN AQUÍ
        actions: [
          AuthHelper.logoutButton(context),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fetchEvaluacionesStream(),
        builder: (context, snapshot) {
          // Manejo de estados de conexión y errores
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar las evaluaciones: ${snapshot.error}',
                style: const TextStyle(color: errorColor),
                textAlign: TextAlign.center,
              ),
            );
          }

          final evaluacionesDocs = snapshot.data?.docs;

          // Manejo de lista vacía
          if (evaluacionesDocs == null || evaluacionesDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Aún no hay evaluaciones guardadas.\n¡Evalúa una rúbrica para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: primaryColor),
                ),
              ),
            );
          }

          // Construcción de la lista
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: evaluacionesDocs.length,
            itemBuilder: (context, index) {
              final evaluacionDoc = evaluacionesDocs[index];
              final evaluacionData = evaluacionDoc.data();

              // Aseguramos que la nota sea un double para el color
              final double notaFinal = evaluacionData['notaFinal'] as double? ?? 0.0;
              final notaColor = _getNotaColor(notaFinal);

              // Formateo de la fecha (Timestamp a String)
              final fecha = (evaluacionData['fechaEvaluacion'] as Timestamp?)?.toDate();
              final fechaStr = fecha != null
                  ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                  : 'Fecha desconocida';

              // Objeto completo para enviar a DetalleEvaluacionScreen
              final Map<String, dynamic> fullEvaluacionData = {
                ...evaluacionData,
                'docId': evaluacionDoc.id,
                'fecha': fechaStr,
              };

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: notaColor,
                    child: Text(
                      notaFinal.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  title: Text(
                    evaluacionData['estudiante'] ?? 'Estudiante desconocido',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Rúbrica: ${evaluacionData['nombreRubrica'] ?? 'Sin nombre'}\nFecha: $fechaStr',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: primaryColor, size: 24),
                  onTap: () => _verDetalleEvaluacion(context, fullEvaluacionData),
                ),
              );
            },
          );
        },
      ),
    );
  }
}