import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

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

  // Keys para tutorial
  final GlobalKey _keyPrimerAnalitico = GlobalKey();
  final GlobalKey _keyValorDescriptor = GlobalKey();
  final GlobalKey _keyNotaFinal = GlobalKey();
  final GlobalKey _keyBtnGuardarEval = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inicializarNotas();
    // Iniciar tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) => _lanzarTutorial());
  }

  void _lanzarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'EJECUTAR_EVALUACION',
      keys: {
        'primer_analitico': _keyPrimerAnalitico,
        'valor_descriptor': _keyValorDescriptor,
        'nota_final': _keyNotaFinal,
        'btn_guardar_eval': _keyBtnGuardarEval,
      },
      force: force,
    );
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
    double finalResult = total.clamp(0.0, 1.0);
    return double.parse(finalResult.toStringAsFixed(2));
  }

  /// Muestra un diálogo de confirmación antes de guardar
  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.save_as, color: Color(0xFF1A237E)),
              SizedBox(width: 10),
              Text("Confirmar Envío"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("¿Estás seguro de que deseas guardar esta evaluación?"),
              const SizedBox(height: 15),
              Text("Estudiante: ${widget.estudiante.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Calificación Final: ${_calcularNotaFinal()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("REVISAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                _guardarEvaluacion();   // Ejecuta el guardado real
              },
              child: const Text("CONFIRMAR Y GUARDAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
        'estudiante': widget.estudiante.toUpperCase(),
        'nombre': widget.nombre.toUpperCase(),
        'notaFinal': _calcularNotaFinal(),
        'fecha': FieldValue.serverTimestamp(),
        'criterios': estructuraAEnviar,
        'rubricaId': widget.rubricaId,
      });

      if (mounted) {
        // Mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Datos guardados con éxito"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al guardar: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        toolbarHeight: 120,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.nombre.toUpperCase(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              "ESTUDIANTE: ${widget.estudiante.toUpperCase()}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          TutorialHelper.helpButton(context, () => _lanzarTutorial(force: true)),
          AuthHelper.logoutButton(context)
        ],
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
                              bool esElPrimero = (i == 0 && j == 0 && k == 0);
                              return Column(
                                key: esElPrimero ? _keyPrimerAnalitico : null,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ana['nombre'] ?? "Analítico", style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            inactiveTrackColor: Colors.black38,
                                            activeTrackColor: const Color(0xFF00796B),
                                            thumbColor: const Color(0xFF00796B),
                                          ),
                                          child: Slider(
                                            value: _getNota(i, j, k),
                                            onChanged: (v) => setState(() => notasSliders["$i-$j-$k"] = v),
                                          ),
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
                              key: (i == 0 && j == 0) ? _keyValorDescriptor : null,
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
                Text(
                    "NOTA FINAL: ${_calcularNotaFinal()}",
                    key: _keyNotaFinal,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  key: _keyBtnGuardarEval,
                  onPressed: _mostrarDialogoConfirmacion, // Activa el proceso de confirmación
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