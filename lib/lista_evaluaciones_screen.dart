import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'detalle_evaluacion_screen.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

class ListaEvaluacionesScreen extends StatefulWidget {
  const ListaEvaluacionesScreen({super.key});

  @override
  State<ListaEvaluacionesScreen> createState() => _ListaEvaluacionesScreenState();
}

class _ListaEvaluacionesScreenState extends State<ListaEvaluacionesScreen> {
  final String __app_id = 'rubrica_evaluator';
  DateTime? _fechaFiltro;
  String _filtroEstudiante = "";
  int? _tipoRubricaFiltro; // null: sin selección, 1: Tradicional, 2: Difusa

  final GlobalKey _keyBuscadorEstudiante = GlobalKey();
  final GlobalKey _keyFiltroCalendario = GlobalKey();
  final GlobalKey _keyTipoRubrica = GlobalKey();
  final GlobalKey _keyPrimeraEvaluacion = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _abrirManualPdf() async {
    final Uri uri = Uri.parse(_pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el manual de usuario.')),
        );
      }
    }
  }

  void _showTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'LISTA_EVALUACIONES',
      keys: {
        'buscador_estudiante': _keyBuscadorEstudiante,
        'tipo_rubrica': _keyTipoRubrica,
        'filtro_calendario': _keyFiltroCalendario,
        'primera_evaluacion': _keyPrimeraEvaluacion,
      },
      force: force,
    );
  }

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
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        title: const Text("Mis Evaluaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              onPressed: _abrirManualPdf,
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: const Text(
                'MANUAL DE USUARIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          TutorialHelper.helpButton(context, () => _showTutorial(force: true)),
          IconButton(
            key: _keyFiltroCalendario,
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaFiltro ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _fechaFiltro = picked);
            },
          ),
          if (_fechaFiltro != null)
            IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fechaFiltro = null)),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  key: _keyBuscadorEstudiante,
                  decoration: InputDecoration(
                    hintText: "Buscar estudiante...",
                    prefixIcon: const Icon(Icons.person_search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _filtroEstudiante.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _filtroEstudiante = ""),
                    )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _filtroEstudiante = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: _keyTipoRubrica,
                  value: _tipoRubricaFiltro,
                  hint: const Text(
                    "SELECCIONE EL TIPO DE RÚBRICA",
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('RÚBRICA TRADICIONAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('RÚBRICA DIFUSA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tipoRubricaFiltro = val;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _tipoRubricaFiltro == null
                ? const Center(
              child: Text(
                "Por favor, seleccione un tipo de rúbrica para continuar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('artifacts/$__app_id/users/$userId/evaluaciones')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error al cargar evaluaciones"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data?.docs ?? [];

                // Filtrar por tipo de rúbrica (1: Tradicional, 2: Difusa)
                docs = docs.where((d) {
                  final esDifusa = d.data()['esDifusa'] ?? false;
                  if (_tipoRubricaFiltro == 2) {
                    return esDifusa == true;
                  } else {
                    return esDifusa == false;
                  }
                }).toList();

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

                if (docs.isEmpty) return const Center(child: Text("No hay evaluaciones que coincidan.", style: TextStyle(fontSize: 15, color: Colors.blueGrey)));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
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
                      key: index == 0 ? _keyPrimeraEvaluacion : null,
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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