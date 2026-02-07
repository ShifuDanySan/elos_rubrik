import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart'; // IMPORTADO

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

  // KEYS TUTORIAL
  final GlobalKey _keyAreaSliders = GlobalKey(); // Apunta al primer elemento o al contenedor
  final GlobalKey _keyPanelNota = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inicializarNotas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarTutorial();
    });
  }

  void _mostrarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'EJECUTAR_EVALUACION_SCREEN',
      keys: {
        'area_sliders': _keyAreaSliders,
        'panel_nota': _keyPanelNota,
      },
      force: force,
    );
  }

  void _inicializarNotas() {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      var descriptores = criterios[i]['descriptores'] as List? ?? [];
      for (int j = 0; j < descriptores.length; j++) {
        var analiticos = descriptores[j]['analiticos'] as List? ?? [];
        for (int k = 0; k < analiticos.length; k++) {
          String key = "c${i}_d${j}_a${k}";
          notasSliders[key] = 0.0; // Valor inicial del grado de pertenencia
        }
      }
    }
  }

  // --- LÓGICA DIFUSA (Cálculo de Nota) ---
  String _calcularNotaFinal() {
    double sumaTotal = 0.0;
    var criterios = widget.rubricaData['criterios'] as List? ?? [];

    for (int i = 0; i < criterios.length; i++) {
      var crit = criterios[i];
      double pesoCriterio = (crit['peso'] ?? 0.0).toDouble();
      var descriptores = crit['descriptores'] as List? ?? [];

      double sumaDescriptores = 0.0;
      int countDescriptores = descriptores.length;

      for (int j = 0; j < descriptores.length; j++) {
        var desc = descriptores[j];
        var analiticos = desc['analiticos'] as List? ?? [];
        String operador = desc['operador'] ?? 'AND';

        List<double> valoresAnaliticos = [];
        for (int k = 0; k < analiticos.length; k++) {
          String key = "c${i}_d${j}_a${k}";
          valoresAnaliticos.add(notasSliders[key] ?? 0.0);
        }

        double valorDescriptor = 0.0;
        if (valoresAnaliticos.isNotEmpty) {
          // APLICACIÓN DE OPERADORES DIFUSOS
          if (operador == 'AND') {
            // T-norm (Min) para AND estricto, o promedio ponderado si así se diseñó.
            // Asumiendo promedio simple de analiticos para simplificar visualización
            // o lógica personalizada definida en tu tesis. Usaremos promedio aquí como ejemplo visual.
            double sumaA = valoresAnaliticos.reduce((a, b) => a + b);
            valorDescriptor = sumaA / valoresAnaliticos.length;
          } else {
            // OR (Max)
            valorDescriptor = valoresAnaliticos.reduce((a, b) => a > b ? a : b);
          }
        }
        sumaDescriptores += valorDescriptor;
      }

      double valorCriterioPromedio = countDescriptores > 0 ? sumaDescriptores / countDescriptores : 0.0;
      sumaTotal += (valorCriterioPromedio * pesoCriterio); // Ponderación
    }

    // Escalar a nota 1-10
    double notaFinal = sumaTotal * 10;
    return notaFinal.toStringAsFixed(2);
  }

  Future<void> _guardarEvaluacion() async {
    // Implementación de guardado (mantenemos lógica original)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('evaluaciones').add({
        'rubricaId': widget.rubricaId,
        'rubricaNombre': widget.nombre,
        'estudiante': widget.estudiante,
        'uidEvaluador': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'notaFinal': double.parse(_calcularNotaFinal()),
        'detalles': notasSliders, // Guardamos los valores crudos
        'criteriosSnapshot': widget.rubricaData['criterios'] // Foto de la estructura al momento
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evaluación Guardada Correctamente")));
        Navigator.pop(context); // Vuelve a selección estudiante
        Navigator.pop(context); // Vuelve a lista rubricas
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Evaluando a:", style: TextStyle(fontSize: 12)),
            Text(widget.estudiante, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: primaryDark,
        actions: [
          TutorialHelper.helpButton(context, () => _mostrarTutorial(force: true)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              key: _keyAreaSliders, // KEY AGREGADA AL LISTVIEW PRINCIPAL
              padding: const EdgeInsets.all(15),
              itemCount: criterios.length,
              itemBuilder: (context, i) {
                var crit = criterios[i];
                var descriptores = crit['descriptores'] as List? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(crit['nombre'], style: TextStyle(color: primaryDark, fontWeight: FontWeight.bold)),
                    subtitle: Text("Peso: ${crit['peso']}"),
                    children: descriptores.asMap().entries.map((entryDesc) {
                      int j = entryDesc.key;
                      var desc = entryDesc.value;
                      var analiticos = desc['analiticos'] as List? ?? [];

                      return Container(
                        decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: Colors.blue.withOpacity(0.3), width: 4))
                        ),
                        margin: const EdgeInsets.only(left: 10, bottom: 10, top: 5),
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(desc['contexto'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ...analiticos.asMap().entries.map((entryAna) {
                              int k = entryAna.key;
                              var ana = entryAna.value;
                              String key = "c${i}_d${j}_a${k}";
                              double val = notasSliders[key] ?? 0.0;

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(ana['descripcion'], style: const TextStyle(fontSize: 13, color: Colors.grey))),
                                      Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  Slider(
                                    value: val,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 100, // Precisión fina para lógica difusa
                                    label: val.toStringAsFixed(2),
                                    activeColor: val > 0.6 ? Colors.green : (val > 0.3 ? Colors.orange : Colors.red),
                                    onChanged: (newVal) {
                                      setState(() {
                                        notasSliders[key] = newVal;
                                      });
                                    },
                                  )
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          // Panel de Nota Final Estético
          Container(
            key: _keyPanelNota, // KEY AGREGADA
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