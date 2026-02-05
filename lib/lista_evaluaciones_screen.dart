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
  String _filtroEstudiante = "";

  String _normalizarTexto(String texto) {
    var conAcentos = 'ÁÉÍÓÚáéíóúàèìòùÀÈÌÒÙâêîôûÂÊÎÔÛäëïöüÄËÏÖÜñÑ';
    var sinAcentos = 'AEIOUaeiouaeiouAEIOUaeiouAEIOUaeiouAEIOUnN';
    String salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase().trim();
  }

  void _confirmarEliminacion(String docId, String estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Evaluación"),
        content: Text("¿Estás seguro de que deseas eliminar la evaluación de $estudiante?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance
                  .collection('artifacts/$__app_id/users/$userId/evaluaciones')
                  .doc(docId)
                  .delete();
              if (mounted) Navigator.pop(context);
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
    const Color primaryColor = Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Evaluaciones"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Cambio aplicado: Botón con leyenda 'Filtrar por Fecha'
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaFiltro ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _fechaFiltro = picked);
            },
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            label: const Text("Filtrar por Fecha", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          if (_fechaFiltro != null)
            IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fechaFiltro = null)),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Buscar estudiante...",
                prefixIcon: const Icon(Icons.person_search, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _filtroEstudiante.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _filtroEstudiante = ""))
                    : null,
              ),
              onChanged: (val) => setState(() => _filtroEstudiante = val),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('artifacts/$__app_id/users/$userId/evaluaciones')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error al cargar evaluaciones"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data?.docs ?? [];

                if (_filtroEstudiante.isNotEmpty) {
                  final busqueda = _normalizarTexto(_filtroEstudiante);
                  docs = docs.where((d) {
                    final nombreEstudiante = _normalizarTexto(d.data()['estudiante'] ?? "");
                    return nombreEstudiante.contains(busqueda);
                  }).toList();
                }

                if (_fechaFiltro != null) {
                  docs = docs.where((d) {
                    final timestamp = d.data()['fecha'] as Timestamp?;
                    if (timestamp == null) return false;
                    final date = timestamp.toDate();
                    return date.day == _fechaFiltro!.day && date.month == _fechaFiltro!.month && date.year == _fechaFiltro!.year;
                  }).toList();
                }

                docs.sort((a, b) {
                  final dateA = (a.data()['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final dateB = (b.data()['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return dateB.compareTo(dateA);
                });

                if (docs.isEmpty) return const Center(child: Text("No hay evaluaciones que coincidan."));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final double nota = (data['notaFinal'] ?? 0.0).toDouble();
                    final String estudiante = data['estudiante'] ?? 'N/A';
                    final String id = docs[index].id;
                    final timestamp = data['fecha'] as Timestamp?;

                    final String fechaLabel = timestamp != null
                        ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
                        : "S/F";

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: nota >= 7 ? const Color(0xFF00796B) : Colors.orange,
                          child: Text(nota.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(estudiante, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['nombre']}\n$fechaLabel"),
                        isThreeLine: true,
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
          ),
        ],
      ),
    );
  }
}