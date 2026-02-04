import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'detalle_evaluacion_screen.dart';
import 'auth_helper.dart';

class ListaEvaluacionesScreen extends StatefulWidget {
  const ListaEvaluacionesScreen({super.key});

  @override
  State<ListaEvaluacionesScreen> createState() => _ListaEvaluacionesScreenState();
}

class _ListaEvaluacionesScreenState extends State<ListaEvaluacionesScreen> {
  final String __app_id = 'rubrica_evaluator';
  DateTime? _fechaFiltro;

  void _confirmarEliminacion(String docId, String estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar evaluación?"),
        content: Text("¿Deseas eliminar permanentemente la evaluación de $estudiante?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance
                  .collection('artifacts/$__app_id/users/$userId/evaluaciones')
                  .doc(docId)
                  .delete();
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('artifacts/$__app_id/users/$userId/evaluaciones')
        .orderBy('fecha', descending: true);

    if (_fechaFiltro != null) {
      DateTime inicio = DateTime(_fechaFiltro!.year, _fechaFiltro!.month, _fechaFiltro!.day);
      DateTime fin = inicio.add(const Duration(days: 1));
      query = query.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fecha', isLessThan: Timestamp.fromDate(fin));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Evaluaciones'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (_fechaFiltro != null)
            IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () => setState(() => _fechaFiltro = null)
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaFiltro ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _fechaFiltro = picked);
            },
          ),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No se encontraron evaluaciones."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final double nota = (data['notaFinal'] ?? 0.0).toDouble();
              final String estudiante = data['estudiante'] ?? 'N/A';
              final String id = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: nota >= 7 ? const Color(0xFF00796B) : Colors.orange,
                    child: Text(nota.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(estudiante, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rúbrica: ${data['nombre']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmarEliminacion(id, estudiante),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetalleEvaluacionScreen(evaluacion: data)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}