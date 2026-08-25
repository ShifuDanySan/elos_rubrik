import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

enum ModoEntrada { manual, slider }

class EjecutarEvaluacionDifusaScreen extends StatefulWidget {
  final Map<String, dynamic> rubricaData;
  final String estudiante;
  final String rubricaId;
  final String nombre;

  const EjecutarEvaluacionDifusaScreen({
    super.key,
    required this.rubricaData,
    required this.estudiante,
    required this.rubricaId,
    required this.nombre,
  });

  @override
  State<EjecutarEvaluacionDifusaScreen> createState() => _EjecutarEvaluacionDifusaScreenState();
}

class _EjecutarEvaluacionDifusaScreenState extends State<EjecutarEvaluacionDifusaScreen> {
  // Guarda el controlador de texto para cada criterio
  final Map<int, TextEditingController> _puntosControllers = {};
  // Guarda el modo de ingreso seleccionado para cada criterio
  final Map<int, ModoEntrada> _modosEntrada = {};
  // Guarda el valor numérico actual del Slider para cada criterio
  final Map<int, double> _valoresSlider = {};

  final Color primaryDark = const Color(0xFF1A237E);

  final GlobalKey _keyPrimerNivel = GlobalKey();
  final GlobalKey _keyNotaFinal = GlobalKey();
  final GlobalKey _keyBtnGuardarEval = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inicializarEstado();
  }

  @override
  void dispose() {
    for (var controller in _puntosControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
      pageId: 'EJECUTAR_EVALUACION_DIFUSA',
      keys: {
        'primer_nivel': _keyPrimerNivel,
        'nota_final': _keyNotaFinal,
        'btn_guardar_eval': _keyBtnGuardarEval,
      },
      force: force,
    );
  }

  void _inicializarEstado() {
    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    for (int i = 0; i < criterios.length; i++) {
      _puntosControllers[i] = TextEditingController();
      _modosEntrada[i] = ModoEntrada.manual;
      _valoresSlider[i] = 5.00;
    }
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

  String _obtenerTextoDescriptor(Map<String, dynamic> desc) {
    return desc['texto'] ?? desc['descripcion'] ?? desc['descriptor'] ?? '';
  }

  double _obtenerPuntosIngresados(int i) {
    if (_modosEntrada[i] == ModoEntrada.slider) {
      return _valoresSlider[i] ?? 0.0;
    } else {
      String texto = _puntosControllers[i]?.text.replaceAll(',', '.').trim() ?? '';
      double? puntos = double.tryParse(texto);
      if (puntos == null) return -1.0;
      if (puntos < 0.0 || puntos > 10.0) return -1.0;
      return puntos;
    }
  }

  double _calcularValorDescriptor(int i) {
    double puntos = _obtenerPuntosIngresados(i);
    if (puntos < 0.0) return 0.0;

    var criterios = widget.rubricaData['criterios'] as List? ?? [];
    if (i >= criterios.length) return 0.0;

    var crit = criterios[i];
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
      if (_obtenerPuntosIngresados(i) < 0.0) {
        return false;
      }
    }
    return true;
  }

  void _mostrarDialogoConfirmacion() {
    if (!_todasLasPreguntasRespondidas()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingrese un puntaje válido (0 a 10) para cada criterio antes de guardar."),
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
      var descriptoresRaw = crit['descriptores'] as List? ?? [];
      var desc = descriptoresRaw.isNotEmpty ? descriptoresRaw[0] : {};
      double puntosIngresados = _obtenerPuntosIngresados(i);

      Map<String, dynamic> nivelElegido = {
        'nivel_nombre': desc['contexto'] ?? desc['nombre'] ?? "NIVEL DEDICADO",
        'puntos': puntosIngresados,
        'texto': _obtenerTextoDescriptor(desc),
        'valor_descriptor': _calcularValorDescriptor(i),
      };

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
      'esDifusa': true,
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
        toolbarHeight: isMobile ? kToolbarHeight : 120,
        title: isMobile
            ? null
            : Column(
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
          if (isMobile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.nombre.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "ESTUDIANTE: ${widget.estudiante.toUpperCase()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
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
                var desc = descriptores.isNotEmpty ? descriptores[0] : {};
                double porcentajeCriterio = _obtenerPorcentajeCriterio(crit);
                String nombreNivel = desc['contexto'] ?? desc['nombre'] ?? "NIVEL";
                String textoDescriptor = _obtenerTextoDescriptor(desc);
                double puntosIngresados = _obtenerPuntosIngresados(i);
                ModoEntrada modoActual = _modosEntrada[i] ?? ModoEntrada.manual;

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

                        // Contenedor principal del criterio
                        Container(
                          key: i == 0 ? _keyPrimerNivel : null,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00796B).withOpacity(0.05),
                            border: Border.all(
                              color: puntosIngresados >= 0.0 ? const Color(0xFF00796B) : Colors.grey.shade300,
                              width: puntosIngresados >= 0.0 ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "NIVEL (${nombreNivel.toUpperCase()})",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B), fontSize: 16),
                              ),
                              if (textoDescriptor.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  textoDescriptor,
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Seleccionador de Modo (Manual / Slider)
                              Center(
                                child: SegmentedButton<ModoEntrada>(
                                  segments: const [
                                    ButtonSegment<ModoEntrada>(
                                      value: ModoEntrada.manual,
                                      label: Text("Manual"),
                                      icon: Icon(Icons.edit_note),
                                    ),
                                    ButtonSegment<ModoEntrada>(
                                      value: ModoEntrada.slider,
                                      label: Text("Slider"),
                                      icon: Icon(Icons.tune),
                                    ),
                                  ],
                                  selected: {modoActual},
                                  onSelectionChanged: (Set<ModoEntrada> newSelection) {
                                    setState(() {
                                      _modosEntrada[i] = newSelection.first;
                                      // Sincronizar el valor al cambiar de modo
                                      if (newSelection.first == ModoEntrada.slider) {
                                        double parsed = double.tryParse(_puntosControllers[i]?.text.replaceAll(',', '.') ?? '') ?? 5.0;
                                        _valoresSlider[i] = parsed.clamp(0.0, 10.0);
                                      } else {
                                        _puntosControllers[i]?.text = (_valoresSlider[i] ?? 0.0).toStringAsFixed(2);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Renderizado condicional según el modo
                              if (modoActual == ModoEntrada.manual) ...[
                                TextField(
                                  controller: _puntosControllers[i],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
                                  ],
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Puntos alcanzados (0.00 a 10.00)",
                                    hintText: "Ej. 8.50",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    suffixIcon: const Icon(Icons.edit, color: Color(0xFF00796B)),
                                  ),
                                ),
                              ] else ...[
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Puntaje asignado:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00796B),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            (_valoresSlider[i] ?? 0.0).toStringAsFixed(2),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _valoresSlider[i] ?? 0.0,
                                      min: 0.0,
                                      max: 10.0,
                                      divisions: 1000,
                                      activeColor: const Color(0xFF00796B),
                                      inactiveColor: Colors.grey.shade300,
                                      label: (_valoresSlider[i] ?? 0.0).toStringAsFixed(2),
                                      onChanged: (double val) {
                                        setState(() {
                                          _valoresSlider[i] = double.parse(val.toStringAsFixed(2));
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Muestra el Valor del Descriptor resultante para este criterio
                        if (puntosIngresados >= 0.0) ...[
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