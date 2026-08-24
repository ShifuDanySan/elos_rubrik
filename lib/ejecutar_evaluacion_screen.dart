import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

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
  // Guarda el índice del nivel seleccionado para cada criterio (clave: índice del criterio)
  Map<int, int> nivelesSeleccionados = {};
  final Color primaryDark = const Color(0xFF1A237E);

  final GlobalKey _keyPrimerNivel = GlobalKey();
  final GlobalKey _keyNotaFinal = GlobalKey();
  final GlobalKey _keyBtnGuardarEval = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inicializarSeleccion();
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

  void _lanzarTutorial({bool force = true}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'EJECUTAR_EVALUACION_TRADICIONAL',
      keys: {
        'primer_nivel': _keyPrimerNivel,
        'nota_final': _keyNotaFinal,
        'btn_guardar_eval': _keyBtnGuardarEval,
      },
      force: force,
    );
  }

  void _inicializarSeleccion() {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      nivelesSeleccionados[i] = -1;
    }
  }

  double _obtenerPuntosNivel(Map<String, dynamic> desc) {
    if (desc.containsKey('puntos')) {
      return double.tryParse(desc['puntos'].toString()) ?? 0.0;
    }
    if (desc.containsKey('peso')) {
      return double.tryParse(desc['peso'].toString()) ?? 0.0;
    }
    if (desc.containsKey('valor')) {
      return double.tryParse(desc['valor'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  double _obtenerPorcentajeCriterio(Map<String, dynamic> crit) {
    if (crit.containsKey('porcentaje')) {
      return double.tryParse(crit['porcentaje'].toString()) ?? 0.0;
    }
    if (crit.containsKey('peso')) {
      return double.tryParse(crit['peso'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  // Obtiene el texto descriptivo del nivel
  String _obtenerTextoDescriptor(Map<String, dynamic> desc) {
    return desc['texto'] ?? desc['descripcion'] ?? desc['descriptor'] ?? '';
  }

  double _calcularValorDescriptor(int i) {
    int? nivelIndex = nivelesSeleccionados[i];
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    if (nivelIndex == null || nivelIndex < 0 || i >= criterios.length) return 0.0;

    var crit = criterios[i];
    var descriptores = crit['descriptores'] as List? ?? [];
    if (nivelIndex >= descriptores.length) return 0.0;

    double puntos = _obtenerPuntosNivel(descriptores[nivelIndex]);
    double porcentaje = _obtenerPorcentajeCriterio(crit);

    double factor = porcentaje > 1.0 ? (porcentaje / 100.0) : porcentaje;
    if (factor == 0.0) factor = 1.0;

    double resultado = puntos * factor;
    return double.parse(resultado.toStringAsFixed(2));
  }

  double _calcularNotaFinal() {
    double sumaTotalValores = 0.0;
    var criterios = widget.rubricaData['criterios'] as List? ?? [];

    for (int i = 0; i < criterios.length; i++) {
      sumaTotalValores += _calcularValorDescriptor(i);
    }

    return double.parse(sumaTotalValores.toStringAsFixed(2));
  }

  bool _todasLasPreguntasRespondidas() {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      if ((nivelesSeleccionados[i] ?? -1) < 0) {
        return false;
      }
    }
    return true;
  }

  void _mostrarDialogoConfirmacion() {
    if (!_todasLasPreguntasRespondidas()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor selecciona un nivel para cada criterio antes de guardar."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
              Text("CONFIRMAR ENVÍO"),
            ],
          ),
          content: Text("CALIFICACIÓN FINAL: ${_calcularNotaFinal()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("REVISAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
              onPressed: () {
                Navigator.pop(context);
                _guardarEvaluacion();
              },
              child: const Text("CONFIRMAR Y GUARDAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarEvaluacion() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    var criteriosRaw = widget.rubricaData['criterios'] as List? ?? [];
    List<Map<String, dynamic>> estructuraAEnviar = [];

    for (int i = 0; i < criteriosRaw.length; i++) {
      var crit = criteriosRaw[i];
      int nivelIndex = nivelesSeleccionados[i] ?? -1;
      var descriptoresRaw = crit['descriptores'] as List? ?? [];

      Map<String, dynamic>? nivelElegido;
      if (nivelIndex >= 0 && nivelIndex < descriptoresRaw.length) {
        var desc = descriptoresRaw[nivelIndex];
        nivelElegido = {
          'nivel_nombre': desc['contexto'] ?? desc['nombre'] ?? "NIVEL ${nivelIndex + 1}",
          'puntos': _obtenerPuntosNivel(desc),
          'texto': _obtenerTextoDescriptor(desc),
          'valor_descriptor': _calcularValorDescriptor(i),
        };
      }

      estructuraAEnviar.add({
        'nombre': crit['nombre'],
        'porcentaje': _obtenerPorcentajeCriterio(crit),
        'nivel_seleccionado': nivelElegido,
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

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        toolbarHeight: 120,
        title: Column(
          children: [
            Text(widget.nombre.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text("ESTUDIANTE: ${widget.estudiante.toUpperCase()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
              tooltip: 'Manual de usuario',
              onPressed: _abrirManualPdf,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryDark,
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
          TutorialHelper.helpButton(context, () => _lanzarTutorial(force: true)),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: criterios.length,
              itemBuilder: (context, i) {
                var crit = criterios[i];
                var descriptores = crit['descriptores'] as List? ?? [];
                int seleccionActual = nivelesSeleccionados[i] ?? -1;
                double porcentajeCriterio = _obtenerPorcentajeCriterio(crit);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CRITERIO ${i + 1}: ${crit['nombre']}".toUpperCase(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDark),
                        ),
                        if (porcentajeCriterio > 0)
                          Text(
                            "Ponderación: $porcentajeCriterio%",
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        const Divider(height: 20),

                        // Lista de niveles disponibles para seleccionar
                        Column(
                          children: descriptores.asMap().entries.map((entry) {
                            int j = entry.key;
                            var desc = entry.value;
                            double puntosNivel = _obtenerPuntosNivel(desc);
                            String nombreNivel = desc['contexto'] ?? desc['nombre'] ?? "Nivel ${j + 1}";
                            String textoDescriptor = _obtenerTextoDescriptor(desc);

                            return Container(
                              key: (i == 0 && j == 0) ? _keyPrimerNivel : null,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: seleccionActual == j
                                    ? const Color(0xFF00796B).withOpacity(0.12)
                                    : Colors.grey.withOpacity(0.05),
                                border: Border.all(
                                  color: seleccionActual == j ? const Color(0xFF00796B) : Colors.grey.shade300,
                                  width: seleccionActual == j ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: RadioListTile<int>(
                                activeColor: const Color(0xFF00796B),
                                value: j,
                                groupValue: seleccionActual,
                                onChanged: (int? nuevoValor) {
                                  setState(() {
                                    nivelesSeleccionados[i] = nuevoValor ?? -1;
                                  });
                                },
                                title: Text(
                                  "NIVEL ${j + 1} (${nombreNivel.toUpperCase()})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Puntos: $puntosNivel"),
                                    if (textoDescriptor.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        textoDescriptor,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Muestra el Valor del Descriptor resultante para este criterio
                        if (seleccionActual >= 0 && seleccionActual < descriptores.length) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "VALOR DESCRIPTOR: ${_calcularValorDescriptor(i)}",
                              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "NOTA TOTAL: ${_calcularNotaFinal()}",
                  key: _keyNotaFinal,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryDark),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  key: _keyBtnGuardarEval,
                  onPressed: _mostrarDialogoConfirmacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "GUARDAR EVALUACIÓN",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}