import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'auth_helper.dart';
import 'ejecutar_evaluacion_screen.dart';

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
  // Colores unificados con tu sistema de evaluación
  final Color accentColor = const Color(0xFF00897B);

  List<String> _estudiantesLista = [];
  String? _estudianteSeleccionado;
  Map<String, dynamic>? _rubricaData;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosEstructura();
  }

  Future<void> _cargarDatosEstructura() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final doc = await FirebaseFirestore.instance
          .collection('artifacts/$__app_id/users/$userId/rubricas')
          .doc(widget.rubricaId)
          .get();

      if (doc.exists) {
        setState(() {
          _rubricaData = doc.data();
          _cargando = false;
        });
      }
    } catch (e) {
      _mostrarMensaje("Error al conectar con la base de datos.");
    }
  }

  Future<void> _importarExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() => _cargando = true);
      try {
        var bytes = result.files.single.bytes ?? File(result.files.single.path!).readAsBytesSync();
        var excel = excel_lib.Excel.decodeBytes(bytes);
        List<String> tempLista = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null || sheet.maxRows < 2) continue;

          int idxNombre = -1, idxApellido = -1, idxDni = -1;
          var headerRow = sheet.rows.first;

          for (int i = 0; i < headerRow.length; i++) {
            String val = headerRow[i]?.value.toString().toLowerCase().trim() ?? "";
            if (val == "nombre") idxNombre = i;
            else if (val == "apellido") idxApellido = i;
            else if (val == "dni" || val == "documento" || val == "nro documento") idxDni = i;

            if (idxNombre == -1 && val.contains("nombre")) idxNombre = i;
            if (idxApellido == -1 && val.contains("apellido")) idxApellido = i;
            if (idxDni == -1 && (val.contains("dni") || val.contains("doc"))) idxDni = i;
          }

          if (idxNombre == -1 || idxApellido == -1 || idxDni == -1) {
            _mostrarMensaje("Asegúrese de que el Excel tenga las columnas: NOMBRE, APELLIDO y DNI.");
            setState(() => _cargando = false);
            return;
          }

          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            String nombre = row[idxNombre]?.value?.toString().toUpperCase().trim() ?? "";
            String apellido = row[idxApellido]?.value?.toString().toUpperCase().trim() ?? "";
            String dni = row[idxDni]?.value?.toString().trim() ?? "S/D";

            if (nombre.isNotEmpty && apellido.isNotEmpty) {
              tempLista.add("$nombre $apellido ($dni)");
            }
          }
        }

        setState(() {
          _estudiantesLista = tempLista;
          _estudianteSeleccionado = _estudiantesLista.isNotEmpty ? _estudiantesLista.first : null;
          _cargando = false;
        });
      } catch (e) {
        _mostrarMensaje("Error al procesar el archivo Excel.");
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarMensaje(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2C2BF), // Fondo gris verdoso para contraste
      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 0,
        title: Text('Evaluar: ${widget.nombreRubrica}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
            ),
            child: ElevatedButton.icon(
              onPressed: _importarExcel,
              icon: const Icon(Icons.upload_file, color: Color(0xFF00897B)),
              label: const Text("IMPORTAR LISTA DESDE EXCEL", style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_estudiantesLista.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Seleccionar Estudiante:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: _estudianteSeleccionado,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                              ),
                              items: _estudiantesLista.map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e, style: const TextStyle(fontSize: 13))
                              )).toList(),
                              onChanged: (val) => setState(() => _estudianteSeleccionado = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: (_estudianteSeleccionado == null || _rubricaData == null)
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EjecutarEvaluacionScreen(
                      rubricaId: widget.rubricaId,
                      nombre: widget.nombreRubrica,
                      estudiante: _estudianteSeleccionado!,
                      rubricaData: _rubricaData!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF283593), // Color Indigo para el botón de acción
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
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: const Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 50),
            SizedBox(height: 15),
            Text("No hay lista cargada.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            SizedBox(height: 5),
            Text("Usa el botón superior para importar un Excel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)
            ),
          ],
        ),
      ),
    );
  }
}