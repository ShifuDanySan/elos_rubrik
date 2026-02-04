import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (seleccionado != null) setState(() => _fechaFiltro = seleccionado);
  }

  void _mostrarOpcionesCentrales(Map<String, dynamic> rubrica, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          rubrica['nombre'] ?? 'Opciones de Rúbrica',
          textAlign: TextAlign.center,
          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.green),
              title: const Text("Evaluar Estudiante"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EvaluarRubricaScreen(
                      rubricaId: docId,
                      nombreRubrica: rubrica['nombre'] ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Editar Estructura"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarRubricaScreen(
                      rubricaId: docId,
                      nombreInicial: rubrica['nombre'] ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Eliminar Rúbrica"),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminacion(docId, rubrica['nombre']);
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
        title: const Text("¿Eliminar rúbrica?"),
        content: Text("Esta acción borrará '$nombre' permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance
                  .collection('artifacts').doc(__app_id)
                  .collection('users').doc(userId)
                  .collection('rubricas').doc(docId).delete();
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
        .collection('artifacts').doc(__app_id)
        .collection('users').doc(userId)
        .collection('rubricas');

    if (_fechaFiltro != null) {
      DateTime inicio = DateTime(_fechaFiltro!.year, _fechaFiltro!.month, _fechaFiltro!.day);
      DateTime fin = inicio.add(const Duration(days: 1));
      query = query.where('fechaCreacion', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fechaCreacion', isLessThan: Timestamp.fromDate(fin));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Rúbrica"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_fechaFiltro != null)
            IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () => setState(() => _fechaFiltro = null)
            ),
          IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _seleccionarFecha(context)
          ),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("No se encontraron rúbricas."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.assignment, color: Colors.white, size: 20),
                  ),
                  title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Peso Total: ${data['peso_total'] ?? '100%'}"),
                  onTap: () => _mostrarOpcionesCentrales(data, docs[index].id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}