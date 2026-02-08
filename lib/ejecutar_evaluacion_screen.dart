import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';

class EjecutarEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> rubricaData;
  final String estudiante;
  final String rubricaId;
  final String nombre;

  const EjecutarEvaluacionScreen({
    super.key,
    required this.rubricaData,
    required this.estudiante,
    required this.rubricaId,
    required this.nombre,
  });

  @override
  State<EjecutarEvaluacionScreen> createState() => _EjecutarEvaluacionScreenState();
}

class _EjecutarEvaluacionScreenState extends State<EjecutarEvaluacionScreen> {
  Map<String, double> notasSliders = {};
  final Color primaryDark = const Color(0xFF1A237E);

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
        'nombre': widget.nombre,
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
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        title: Text("Calificando a: ${widget.estudiante}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true, // Centrado también en la pantalla de calificación
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: Column(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: primaryDark,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: criterios.length,
              itemBuilder: (context, i) {
                var crit = criterios[i];
                var descriptores = crit['descriptores'] as List? ?? [];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(crit['nombre'], style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark)),
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
                                  Text(ana['nombre'] ?? "Analítico", style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: _getNota(i, j, k),
                                          activeColor: const Color(0xFF00796B),
                                          onChanged: (v) => setState(() => notasSliders["$i-$j-$k"] = v),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                                        child: Text(_getNota(i, j, k).toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  Text("Grado (Objetivo): ${ana['grado']}", style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "Valor Descriptor: ${_calcularValorDescriptor(desc, i, j)}",
                                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                              ),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("NOTA FINAL: ${_calcularNotaFinal()}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _guardarEvaluacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text("GUARDAR EVALUACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}