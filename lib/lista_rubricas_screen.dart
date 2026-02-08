import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'evaluar_rubrica_screen.dart';
import 'editar_rubrica_screen.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String __app_id = 'rubrica_evaluator';
const Color blueCrear = Colors.blue;

class ListaRubricasScreen extends StatefulWidget {
  const ListaRubricasScreen({super.key});

  @override
  State<ListaRubricasScreen> createState() => _ListaRubricasScreenState();
}

class _ListaRubricasScreenState extends State<ListaRubricasScreen> {
  DateTime? _fechaFiltro;
  String _filtroNombre = "";
  bool _tutorialPresentado = false; // Bandera para evitar doble ejecución

  final GlobalKey _keyBuscador = GlobalKey();
  final GlobalKey _keyFiltroFecha = GlobalKey();
  final GlobalKey _keyPrimeraCard = GlobalKey();

  String _normalizarTexto(String texto) {
    var conAcentos = 'ÁÉÍÓÚáéíóúàèìòùÀÈÌÒÙâêîôûÂÊÎÔÛäëïöüÄËÏÖÜñÑ';
    var sinAcentos = 'AEIOUaeiouaeiouAEIOUaeiouAEIOUaeiouAEIOUnN';
    String salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase().trim();
  }

  void _lanzarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'LISTA_RUBRICAS',
      keys: {
        'buscador': _keyBuscador,
        'filtro_fecha': _keyFiltroFecha,
        'primera_card': _keyPrimeraCard,
      },
      force: force,
    );
  }

  void _mostrarOpcionesCentrales(Map<String, dynamic> data, String docId) {
    final GlobalKey keyEvaluar = GlobalKey();
    final GlobalKey keyEditar = GlobalKey();
    final GlobalKey keyEliminar = GlobalKey();

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TutorialHelper().showTutorial(
            context: context,
            pageId: 'OPCIONES_RUBRICA',
            keys: {
              'opcion_evaluar': keyEvaluar,
              'opcion_editar': keyEditar,
              'opcion_eliminar': keyEliminar,
            },
            force: false,
          );
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(data['nombre'] ?? 'Opciones',
              textAlign: TextAlign.center,
              style: const TextStyle(color: blueCrear, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: keyEvaluar,
                leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.play_arrow, color: Colors.green)),
                title: const Text("Evaluar"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluarRubricaScreen(rubricaId: docId, nombreRubrica: data['nombre'] ?? 'Sin nombre')));
                },
              ),
              ListTile(
                key: keyEditar,
                leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.edit, color: Colors.blue)),
                title: const Text("Editar"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditarRubricaScreen(rubricaId: docId, nombreInicial: data['nombre'] ?? '')));
                },
              ),
              ListTile(
                key: keyEliminar,
                leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: const Icon(Icons.delete, color: Colors.red)),
                title: const Text("Eliminar"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminacion(docId, data['nombre'] ?? '');
                },
              ),
            ],
          ),
        );
      },
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
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        title: const Text("Mis Rúbricas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: blueCrear,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            key: _keyFiltroFecha,
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
          TutorialHelper.helpButton(context, () async {
            await TutorialHelper().resetTutorials(['LISTA_RUBRICAS', 'OPCIONES_RUBRICA']);
            _lanzarTutorial(force: true);
          }),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: blueCrear,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))
            ),
            child: TextField(
              key: _keyBuscador,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Buscar rúbrica...",
                prefixIcon: const Icon(Icons.search, color: blueCrear),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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

                // CORRECCIÓN: Solo lanzar si hay datos y no se ha presentado en este ciclo de vida
                if (docs.isNotEmpty && !_tutorialPresentado) {
                  _tutorialPresentado = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _lanzarTutorial());
                }

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
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final f = (data['fechaCreacion'] as Timestamp?)?.toDate();
                    final fechaLabel = f != null ? DateFormat('dd/MM/yyyy').format(f) : "---";
                    return Card(
                      key: index == 0 ? _keyPrimeraCard : null,
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: blueCrear.withOpacity(0.1), child: const Icon(Icons.assignment, color: blueCrear)),
                        title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Creada: $fechaLabel"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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