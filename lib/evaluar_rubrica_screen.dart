import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'auth_helper.dart';
import 'ejecutar_evaluacion_screen.dart';
import 'tutorial_helper.dart'; // IMPORTADO

class EvaluarRubricaScreen extends StatefulWidget {
  final String rubricaId;
  final String nombreRubrica;

  const EvaluarRubricaScreen({
    super.key,
    required this.rubricaId,
    required this.nombreRubrica,
  });

  @override
  State<EvaluarRubricaScreen> createState() => _EvaluarRubricaScreenState();
}

class _EvaluarRubricaScreenState extends State<EvaluarRubricaScreen> {
  final String __app_id = 'rubrica_evaluator';
  final Color accentColor = const Color(0xFF00897B);

  List<String> _estudiantesLista = [];
  String? _estudianteSeleccionado;
  Map<String, dynamic>? _rubricaData;
  bool _cargando = true;

  // KEYS TUTORIAL
  final GlobalKey _keyBtnImportar = GlobalKey();
  final GlobalKey _keyInputEstudiante = GlobalKey();
  final GlobalKey _keyBtnComenzar = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarDatosEstructura();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarTutorial();
    });
  }

  void _mostrarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'EVALUAR_RUBRICA_SCREEN',
      keys: {
        'btn_importar': _keyBtnImportar,
        'input_estudiante': _keyInputEstudiante,
        'btn_comenzar': _keyBtnComenzar,
      },
      force: force,
    );
  }

  Future<void> _cargarDatosEstructura() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('rubricas').doc(widget.rubricaId).get();
      if (doc.exists) {
        setState(() {
          _rubricaData = doc.data();
          _cargando = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _importarExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      var bytes = result.files.single.bytes;
      if (bytes == null && result.files.single.path != null) {
        bytes = File(result.files.single.path!).readAsBytesSync();
      }

      if (bytes != null) {
        var excel = excel_lib.Excel.decodeBytes(bytes);
        List<String> tempLista = [];
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            if (row.isNotEmpty) {
              tempLista.add(row.first?.value.toString() ?? "Sin Nombre");
            }
          }
        }
        setState(() {
          _estudiantesLista = tempLista;
          if (_estudiantesLista.isNotEmpty) _estudianteSeleccionado = _estudiantesLista.first;
        });
      }
    }
  }

  void _irAEvaluacion() {
    if (_estudianteSeleccionado == null || _estudianteSeleccionado!.isEmpty) return;
    if (_rubricaData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EjecutarEvaluacionScreen(
          rubricaData: _rubricaData!,
          estudiante: _estudianteSeleccionado!,
          rubricaId: widget.rubricaId,
          nombre: widget.nombreRubrica,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Seleccionar Estudiante"),
        backgroundColor: const Color(0xFF3949AB),
        actions: [
          TutorialHelper.helpButton(context, () => _mostrarTutorial(force: true)),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón Importar
            SizedBox(
              width: double.infinity,
              key: _keyBtnImportar, // KEY AGREGADA
              child: OutlinedButton.icon(
                onPressed: _importarExcel,
                icon: const Icon(Icons.upload_file),
                label: const Text("Importar Excel (Lista de Alumnos)"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFF3949AB)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("O selecciona manualmente:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Selector o Input
            Expanded(
              child: _estudiantesLista.isNotEmpty
                  ? ListView.builder(
                key: _keyInputEstudiante, // KEY AGREGADA
                itemCount: _estudiantesLista.length,
                itemBuilder: (ctx, i) {
                  final est = _estudiantesLista[i];
                  final isSelected = est == _estudianteSeleccionado;
                  return Card(
                    color: isSelected ? const Color(0xFFE8EAF6) : Colors.white,
                    elevation: isSelected ? 4 : 1,
                    child: ListTile(
                      title: Text(est, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      leading: Icon(Icons.person, color: isSelected ? const Color(0xFF3949AB) : Colors.grey),
                      onTap: () => setState(() => _estudianteSeleccionado = est),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    ),
                  );
                },
              )
                  : _buildEmptyState(),
            ),

            const SizedBox(height: 20),

            // Botón Comenzar
            SafeArea(
              child: ElevatedButton(
                key: _keyBtnComenzar, // KEY AGREGADA
                onPressed: (_estudianteSeleccionado != null) ? _irAEvaluacion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283593),
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                child: const Text("COMENZAR EVALUACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      key: _keyInputEstudiante, // Fallback key si no hay lista
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 50),
            const SizedBox(height: 15),
            const Text("No hay lista cargada.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 5),
            const Text("Usa el botón superior para importar un Excel, o escribe un nombre temporal si implementamos un TextField manual.", // Texto ajustado al contexto
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)
            ),
            // Input Manual de emergencia si no hay Excel (opcional pero útil)
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: "Nombre del estudiante (Manual)", border: OutlineInputBorder()),
              onChanged: (val) => setState(() => _estudianteSeleccionado = val),
            )
          ],
        ),
      ),
    );
  }
}