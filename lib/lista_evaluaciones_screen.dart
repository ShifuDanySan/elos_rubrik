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
  static const Color accentColor = Color(0xFF00897B); // Verde Teal

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar Evaluación", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("¿Borrar la evaluación de $estudiante?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/evaluaciones').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SÍ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFB2C2BF), // Fondo gris verdoso oscuro para contraste real
      appBar: AppBar(
        title: const Text("Mis Evaluaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _fechaFiltro ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _fechaFiltro = picked);
              },
              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              label: const Text("Filtrar por Fecha", style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
          if (_fechaFiltro != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fechaFiltro = null)),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: accentColor, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Buscar estudiante...",
                prefixIcon: const Icon(Icons.person_search, color: accentColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _filtroEstudiante = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/evaluaciones').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data?.docs ?? [];
                if (_filtroEstudiante.isNotEmpty) {
                  final busq = _normalizarTexto(_filtroEstudiante);
                  docs = docs.where((d) => _normalizarTexto(d.data()['estudiante'] ?? "").contains(busq)).toList();
                }
                if (_fechaFiltro != null) {
                  docs = docs.where((d) {
                    final ts = d.data()['fecha'] as Timestamp?;
                    if (ts == null) return false;
                    final dt = ts.toDate();
                    return dt.day == _fechaFiltro!.day && dt.month == _fechaFiltro!.month && dt.year == _fechaFiltro!.year;
                  }).toList();
                }
                docs.sort((a, b) => ((b.data()['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000)).compareTo((a.data()['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000)));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final double nota = (data['notaFinal'] ?? 0.0).toDouble();
                    return Card(
                      elevation: 4, // Más elevación para resaltar sobre el fondo oscuro
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: nota >= 7 ? const Color(0xFF43A047) : Colors.orange[600],
                          child: Text(nota.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(data['estudiante'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['nombre']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmarEliminacion(docs[index].id, data['estudiante'] ?? ''),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleEvaluacionScreen(evaluacion: data))),
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