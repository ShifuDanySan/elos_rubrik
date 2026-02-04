import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';

class EjecutarEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> rubricaData;
  final String estudiante;
  final String rubricaId;
  final String nombre; // <-- Nuevo parámetro para recibir el nombre como String

  const EjecutarEvaluacionScreen({
    super.key,
    required this.rubricaData,
    required this.estudiante,
    required this.rubricaId,
    required this.nombre, // <-- Requerido
  });

  @override
  State<EjecutarEvaluacionScreen> createState() => _EjecutarEvaluacionScreenState();
}

class _EjecutarEvaluacionScreenState extends State<EjecutarEvaluacionScreen> {
  Map<String, double> notasSliders = {};

  @override
  void initState() {
    super.initState();
    _inicializarNotas();
  }

  void _inicializarNotas() {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      var descriptores = criterios[i]['descriptores'] as List? ?? [];
      for (int j = 0; j < descriptores.length; j++) {
        var analiticos = _extraerAnaliticos(descriptores[j]);
        for (int k = 0; k < analiticos.length; k++) {
          notasSliders["$i-$j-$k"] = 0.0;
        }
      }
    }
  }

  List<Map<String, dynamic>> _extraerAnaliticos(Map<String, dynamic> descriptor) {
    List<Map<String, dynamic>> analiticos = [];
    var keys = descriptor.keys.where((k) => k.contains('analitico')).toList();
    keys.sort();
    for (var key in keys) {
      if (descriptor[key] is Map) {
        analiticos.add(Map<String, dynamic>.from(descriptor[key]));
      }
    }
    return analiticos;
  }

  double _getNota(int i, int j, int k) => notasSliders["$i-$j-$k"] ?? 0.0;

  double _calcularValorDescriptor(Map<String, dynamic> desc, int i, int j) {
    var analiticos = _extraerAnaliticos(desc);
    double sumaPonderada = 0;
    for (int k = 0; k < analiticos.length; k++) {
      double gradoObjetivo = double.tryParse(analiticos[k]['grado'].toString()) ?? 1.0;
      sumaPonderada += _getNota(i, j, k) * gradoObjetivo;
    }
    return double.parse(sumaPonderada.toStringAsFixed(2));
  }

  double _calcularNotaFinal() {
    double total = 0;
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      double sumaCriterio = 0;
      var descriptores = criterios[i]['descriptores'] as List? ?? [];
      for (int j = 0; j < descriptores.length; j++) {
        sumaCriterio += _calcularValorDescriptor(descriptores[j], i, j);
      }
      double peso = double.tryParse(criterios[i]['peso'].toString()) ?? 1.0;
      total += (sumaCriterio * peso);
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Future<void> _guardarEvaluacion() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      var criteriosRaw = widget.rubricaData['criterios'] as List? ?? [];
      List<Map<String, dynamic>> estructuraAEnviar = [];

      for (int i = 0; i < criteriosRaw.length; i++) {
        var crit = criteriosRaw[i];
        List<Map<String, dynamic>> listaDesc = [];
        var descriptoresRaw = crit['descriptores'] as List? ?? [];

        for (int j = 0; j < descriptoresRaw.length; j++) {
          var desc = descriptoresRaw[j];
          var analiticosRaw = _extraerAnaliticos(desc);
          List<Map<String, dynamic>> listaAna = [];

          for (int k = 0; k < analiticosRaw.length; k++) {
            listaAna.add({
              'nombre': analiticosRaw[k]['nombre'],
              'grado': analiticosRaw[k]['grado'],
              'valor_asignado': _getNota(i, j, k),
            });
          }

          listaDesc.add({
            'contexto': desc['contexto'],
            'operador': desc['operador'],
            'resultado_descriptor': _calcularValorDescriptor(desc, i, j),
            'analiticos': listaAna,
          });
        }
        estructuraAEnviar.add({
          'nombre': crit['nombre'],
          'peso': crit['peso'],
          'descriptores': listaDesc,
        });
      }

      await FirebaseFirestore.instance
          .collection('artifacts/rubrica_evaluator/users/$userId/evaluaciones')
          .add({
        'estudiante': widget.estudiante,
        'nombre': widget.nombre, // <-- Cambio clave: Guardamos el nombre pasado como String
        'notaFinal': _calcularNotaFinal(),
        'fecha': FieldValue.serverTimestamp(),
        'criterios': estructuraAEnviar,
        'rubricaId': widget.rubricaId,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Calificando a: ${widget.estudiante}"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: criterios.length,
              itemBuilder: (context, i) {
                var crit = criterios[i];
                var descriptores = crit['descriptores'] as List? ?? [];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(crit['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    subtitle: Text("Peso Criterio: ${crit['peso']}"),
                    children: descriptores.asMap().entries.map((entry) {
                      int j = entry.key;
                      var desc = entry.value;
                      var analiticos = _extraerAnaliticos(desc);
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("DESCRIPTOR: ${desc['contexto']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                            const Divider(),
                            ...analiticos.asMap().entries.map((aEntry) {
                              int k = aEntry.key;
                              var ana = aEntry.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ana['nombre'] ?? "Analítico"),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: _getNota(i, j, k),
                                          activeColor: const Color(0xFF00796B),
                                          onChanged: (v) => setState(() => notasSliders["$i-$j-$k"] = v),
                                        ),
                                      ),
                                      Text(_getNota(i, j, k).toStringAsFixed(2)),
                                    ],
                                  ),
                                  Text("Grado (Objetivo): ${ana['grado']}", style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
                            if (desc['operador'] != null)
                              Text("Operador: ${desc['operador']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              "Valor Descriptor (Suma Ponderada): ${_calcularValorDescriptor(desc, i, j)}",
                              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(
              children: [
                Text("NOTA FINAL: ${_calcularNotaFinal()}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _guardarEvaluacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("GUARDAR EVALUACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}