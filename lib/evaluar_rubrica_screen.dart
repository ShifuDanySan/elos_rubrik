// evaluar_rubrica_screen.dart (Versión con Captura de Columnas Dinámicas)
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/foundation.dart' show kIsWeb;

class EvaluarRubricaScreen extends StatefulWidget {
  final Map<String, dynamic> rubrica;

  const EvaluarRubricaScreen({super.key, required this.rubrica});

  @override
  State<EvaluarRubricaScreen> createState() => _EvaluarRubricaScreenState();
}

class _EvaluarRubricaScreenState extends State<EvaluarRubricaScreen> {
  List<String> _estudiantes = [''];
  String? _estudianteSeleccionado;
  final Map<String, double> _evaluacionValores = {};
  double _notaCalculada = 0.0;
  bool _isSaving = false;
  bool _isLoadingExcel = false;

  @override
  void initState() {
    super.initState();
    _estudianteSeleccionado = _estudiantes.first;
    _inicializarEvaluacion();
    _calcularNotaFinal();
  }

  // ==========================================================
  // LÓGICA DE CARGA DE EXCEL CON CAPTURA DE COLUMNAS DINÁMICAS
  // ==========================================================
  Future<void> _cargarExcelAlumnos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() => _isLoadingExcel = true);

        var bytes;
        if (kIsWeb) {
          bytes = result.files.first.bytes;
        } else {
          bytes = File(result.files.first.path!).readAsBytesSync();
        }

        var excel = excel_lib.Excel.decodeBytes(bytes!);
        List<String> listaTemporal = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          if (rows.isEmpty) continue;

          // 1. Identificar índices clave y mapear el resto
          int idxNombre = -1, idxApellido = -1, idxDni = -1;
          Map<int, String> otrasColumnas = {}; // Índice -> Nombre de columna

          var firstRow = rows[0];

          for (int i = 0; i < firstRow.length; i++) {
            String header = firstRow[i]?.value.toString().trim() ?? "";
            String headerLower = header.toLowerCase();

            if (headerLower.contains("nombre")) {
              idxNombre = i;
            } else if (headerLower.contains("apellido")) {
              idxApellido = i;
            } else if (headerLower.contains("dni") || headerLower.contains("documento")) {
              idxDni = i;
            } else if (header.isNotEmpty) {
              // Guardamos cualquier otra columna que tenga nombre
              otrasColumnas[i] = header.toUpperCase();
            }
          }

          // Fallback si no hay encabezados claros
          if (idxNombre == -1) idxNombre = 0;
          if (idxApellido == -1) idxApellido = 1;
          if (idxDni == -1) idxDni = 2;

          // 2. Procesar datos
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;

            String nombre = idxNombre < row.length ? (row[idxNombre]?.value.toString().trim() ?? "") : "";
            String apellido = idxApellido < row.length ? (row[idxApellido]?.value.toString().trim() ?? "") : "";
            String dni = idxDni < row.length ? (row[idxDni]?.value.toString().trim() ?? "") : "";

            if (nombre.isNotEmpty) {
              // Construir base: NOMBRE APELLIDO (DNI)
              String infoEstudiante = "${nombre.toUpperCase()} ${apellido.toUpperCase()} ($dni)";

              // Añadir dinámicamente el resto de las columnas encontradas
              otrasColumnas.forEach((index, nombreColumna) {
                if (index < row.length && row[index] != null) {
                  String valorExtra = row[index]!.value.toString().trim();
                  if (valorExtra.isNotEmpty && valorExtra != "null") {
                    infoEstudiante += " | $nombreColumna: $valorExtra";
                  }
                }
              });

              listaTemporal.add(infoEstudiante);
            }
          }
          if (listaTemporal.isNotEmpty) break;
        }

        setState(() {
          // Ordenamos alfabéticamente para que sea profesional
          listaTemporal.sort();
          _estudiantes = listaTemporal;
          _estudianteSeleccionado = _estudiantes.isNotEmpty ? _estudiantes.first : null;
          _isLoadingExcel = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DATOS CARGADOS CON COLUMNAS DINÁMICAS')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingExcel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _inicializarEvaluacion() {
    _evaluacionValores.clear();
    for (var criterio in (widget.rubrica['criterios'] as List? ?? [])) {
      for (var descriptor in (criterio['descriptores'] as List? ?? [])) {
        for (var analitico in (descriptor['analiticos'] as List? ?? [])) {
          final String key = '${criterio['nombre']}_${descriptor['contexto']}_${analitico['descripcion']}';
          _evaluacionValores[key] = 0.0;
        }
      }
    }
  }

  void _onGradoPertenenciaChanged(String key, double newValue) {
    setState(() {
      _evaluacionValores[key] = newValue;
      _calcularNotaFinal();
    });
  }

  void _onEstudianteChanged(String? newValue) {
    setState(() {
      _estudianteSeleccionado = newValue;
      _inicializarEvaluacion();
      _calcularNotaFinal();
    });
  }

  double _calcularValorDescriptorCompensatorio(List<double> gradosAsignados, Map<String, dynamic>? operador) {
    if (gradosAsignados.isEmpty) return 0.0;
    if (gradosAsignados.length == 1) return gradosAsignados.first;

    if (operador != null && operador['nombre'] == 'Media Aritmética') {
      final double suma = gradosAsignados.reduce((a, b) => a + b);
      return suma / gradosAsignados.length;
    }

    return gradosAsignados.first;
  }

  void _calcularNotaFinal() {
    double notaFinal = 0.0;
    final List criterios = widget.rubrica['criterios'] as List? ?? [];

    for (var criterio in criterios) {
      final double pesoCriterio = criterio['peso'] as double? ?? 0.0;
      final List descriptores = criterio['descriptores'] as List? ?? [];
      double valorCriterio = 0.0;

      for (var descriptor in descriptores) {
        final double pesoDescriptor = descriptor['pesoDescriptor'] as double? ?? 0.0;
        final List analiticos = descriptor['analiticos'] as List? ?? [];
        final Map<String, dynamic>? operador = descriptor['operador'] as Map<String, dynamic>?;

        List<double> gradosAsignados = [];
        for (var analitico in analiticos) {
          final String analiticoDesc = analitico['descripcion'];
          final String analiticoKey = '${criterio['nombre']}_${descriptor['contexto']}_$analiticoDesc';
          gradosAsignados.add(_evaluacionValores[analiticoKey] ?? 0.0);
        }

        final double valorDescriptor = _calcularValorDescriptorCompensatorio(gradosAsignados, operador);
        valorCriterio += (pesoDescriptor * valorDescriptor);
      }
      notaFinal += (pesoCriterio * valorCriterio);
    }

    setState(() {
      _notaCalculada = notaFinal;
    });
  }

  void _guardarEvaluacion() async {
    if (_estudianteSeleccionado == null || _isSaving || _estudianteSeleccionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, cargue y seleccione un estudiante.')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final Map<String, double> valoresAnaliticosPonderados = _evaluacionValores.map(
          (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
    );

    final Map<String, dynamic> evaluacionData = {
      'rubricaId': widget.rubrica['docId'],
      'nombreRubrica': widget.rubrica['nombre'],
      'estudiante': _estudianteSeleccionado,
      'evaluadorId': userId,
      'notaFinal': double.parse(_notaCalculada.toStringAsFixed(2)),
      'fechaEvaluacion': FieldValue.serverTimestamp(),
      'valoresAnaliticos': valoresAnaliticosPonderados,
    };

    try {
      const String appId = 'rubrica_evaluator';
      final String collectionPath = 'artifacts/$appId/users/$userId/evaluaciones';
      await FirebaseFirestore.instance.collection(collectionPath).add(evaluacionData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado: ${_notaCalculada.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List criterios = widget.rubrica['criterios'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar: ${widget.rubrica['nombre']}'),
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoadingExcel ? null : _cargarExcelAlumnos,
                icon: _isLoadingExcel
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: const Text('CARGAR ALUMNOS DESDE EXCEL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _estudianteSeleccionado,
                isExpanded: true, // Importante para textos largos de columnas extras
                decoration: const InputDecoration(
                  labelText: 'Evaluar a',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.person),
                ),
                items: _estudiantes.map((String est) {
                  return DropdownMenuItem<String>(
                    value: est,
                    child: Text(est, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _onEstudianteChanged,
              ),
              const SizedBox(height: 16),

              Text(
                'NOTA FINAL CALCULADA: ${_notaCalculada.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: criterios.length,
                  itemBuilder: (context, criterioIndex) {
                    final criterio = criterios[criterioIndex];
                    final List descriptores = criterio['descriptores'] as List? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                            'Criterio ${criterioIndex + 1}: ${criterio['nombre']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)
                        ),
                        subtitle: Text('Peso Criterio: ${(criterio['peso'] as double? ?? 0.0).toStringAsFixed(2)}'),
                        children: descriptores.map((descriptor) {
                          final List analiticos = descriptor['analiticos'] as List? ?? [];
                          final operador = descriptor['operador'];

                          List<double> gradosAsignados = analiticos.map((a) {
                            final String key = '${criterio['nombre']}_${descriptor['contexto']}_${a['descripcion']}';
                            return _evaluacionValores[key] ?? 0.0;
                          }).toList();
                          final double valorDescriptorCalculado = _calcularValorDescriptorCompensatorio(gradosAsignados, operador);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Descriptor:', style: const TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                                Text('Peso: ${(descriptor['pesoDescriptor'] as double? ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                Text('Contexto: ${descriptor['contexto']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                const Divider(height: 10),

                                ...analiticos.asMap().entries.map((entry) {
                                  final int analiticoIndex = entry.key;
                                  final analitico = entry.value;
                                  final String analiticoDesc = analitico['descripcion'];
                                  final double objetivo = analitico['gradoPertenencia'] as double? ?? 0.0;
                                  final String analiticoKey = '${criterio['nombre']}_${descriptor['contexto']}_$analiticoDesc';
                                  final double currentValue = _evaluacionValores[analiticoKey] ?? 0.0;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Analítico ${analiticoIndex + 1}: $analiticoDesc', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('Objetivo: ${objetivo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.indigo)),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              value: currentValue,
                                              min: 0.0, max: 1.0, divisions: 10,
                                              label: currentValue.toStringAsFixed(1),
                                              onChanged: (double value) => _onGradoPertenenciaChanged(analiticoKey, double.parse(value.toStringAsFixed(1))),
                                            ),
                                          ),
                                          Text(currentValue.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  );
                                }).toList(),
                                Text('Valor Descriptor: ${valorDescriptorCalculado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarEvaluacion,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Evaluación y Finalizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}