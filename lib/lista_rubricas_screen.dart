import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'evaluar_rubrica_screen.dart';
import 'editar_rubrica_screen.dart';
import 'auth_helper.dart';

const String __app_id = 'rubrica_evaluator';
const Color primaryColor = Color(0xFF1A237E);

class ListaRubricasScreen extends StatefulWidget {
  const ListaRubricasScreen({super.key});

  @override
  State<ListaRubricasScreen> createState() => _ListaRubricasScreenState();
}

class _ListaRubricasScreenState extends State<ListaRubricasScreen> {
  DateTime? _fechaFiltro;
  String _filtroNombre = "";

  String _normalizarTexto(String texto) {
    var conAcentos = 'ÁÉÍÓÚáéíóúàèìòùÀÈÌÒÙâêîôûÂÊÎÔÛäëïöüÄËÏÖÜñÑ';
    var sinAcentos = 'AEIOUaeiouaeiouAEIOUaeiouAEIOUaeiouAEIOUnN';
    String salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase().trim();
  }

  void _mostrarOpcionesCentrales(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(data['nombre'] ?? 'Opciones', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text("Evaluar"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluarRubricaScreen(rubricaId: docId, nombreRubrica: data['nombre'] ?? 'Sin nombre')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Editar"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditarRubricaScreen(rubricaId: docId, nombreInicial: data['nombre'] ?? '')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Eliminar"),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminacion(docId, data['nombre'] ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacion(String docId, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar"),
        content: Text("¿Borrar '$nombre'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SÍ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Rúbricas"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: _fechaFiltro ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
              if (picked != null) setState(() => _fechaFiltro = picked);
            },
          ),
          if (_fechaFiltro != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fechaFiltro = null)),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar rúbrica...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: (val) => setState(() => _filtroNombre = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;

                if (_filtroNombre.isNotEmpty) {
                  final busca = _normalizarTexto(_filtroNombre);
                  docs = docs.where((d) => _normalizarTexto(d.data()['nombre'] ?? "").contains(busca)).toList();
                }

                if (_fechaFiltro != null) {
                  docs = docs.where((d) {
                    final f = (d.data()['fechaCreacion'] as Timestamp?)?.toDate();
                    return f != null && f.day == _fechaFiltro!.day && f.month == _fechaFiltro!.month && f.year == _fechaFiltro!.year;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final f = (data['fechaCreacion'] as Timestamp?)?.toDate();
                    final fechaLabel = f != null ? DateFormat('dd/MM/yyyy').format(f) : "---";
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: primaryColor, child: Icon(Icons.assignment, color: Colors.white)),
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text("Creada: $fechaLabel"),
                        onTap: () => _mostrarOpcionesCentrales(data, docs[index].id),
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