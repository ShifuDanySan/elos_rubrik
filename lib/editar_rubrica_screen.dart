import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

class EditarRubricaScreen extends StatefulWidget {
  final String rubricaId;
  final String nombreInicial;

  const EditarRubricaScreen({super.key, required this.rubricaId, required this.nombreInicial});

  @override
  State<EditarRubricaScreen> createState() => _EditarRubricaScreenState();
}

class _EditarRubricaScreenState extends State<EditarRubricaScreen> with WidgetsBindingObserver {
  final String __app_id = 'rubrica_evaluator';
  final Color headerColor = const Color(0xFF1A237E);

  // Llaves de pantalla principal
  final GlobalKey _keySumaText = GlobalKey();
  final GlobalKey _keyPrimerCriterio = GlobalKey();
  final GlobalKey _keyPrimerAddDescriptor = GlobalKey();
  final GlobalKey _keyPrimerEditCriterio = GlobalKey();
  final GlobalKey _keyEditDescriptorTutorial = GlobalKey();
  final GlobalKey _keyBotonFinalizar = GlobalKey();
  final GlobalKey _keyBotonFisico = GlobalKey();

  // Llaves persistentes para el diálogo
  final GlobalKey _kCtx = GlobalKey();
  final GlobalKey _kPesoDesc = GlobalKey();
  final GlobalKey _kBtnAceptar = GlobalKey();

  List<dynamic> listaCriteriosLocal = [];
  bool cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    TutorialHelper().forceClose();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) TutorialHelper().reShowLastTutorial(context);
    });
  }

  Future<void> _cargarDatosIniciales() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('artifacts/$__app_id/users/$userId/rubricas')
        .doc(widget.rubricaId)
        .get();

    if (mounted && doc.exists) {
      setState(() {
        listaCriteriosLocal = List.from(doc.data()?['criterios'] ?? []);
        cargandoInicial = false;
      });
    }
  }

  Future<void> _lanzarTutorial({bool force = false}) async {
    if (force) {
      await TutorialHelper().resetTutorials(['EDITAR_RUBRICA_SCREEN', 'EDITAR_DESCRIPTOR']);
    }

    Map<String, GlobalKey> tutorialKeys = {
      'nombre_rubrica': _keySumaText,
      'lista_criterios': _keyPrimerCriterio,
      'btn_actualizar': _keyBotonFinalizar,
    };

    if (mounted) {
      TutorialHelper().showTutorial(
          context: context,
          pageId: 'EDITAR_RUBRICA_SCREEN',
          keys: tutorialKeys,
          force: force
      );
    }
  }

  double _calcularSumaPesos(List elementos) {
    double sumaTotal = elementos.fold(0.0, (sum, item) => sum + (double.tryParse(item['peso'].toString()) ?? 0.0));
    return double.parse(sumaTotal.toStringAsFixed(2));
  }

  bool _estanCriteriosCorrectos() {
    if (listaCriteriosLocal.isEmpty) return false;
    double suma = _calcularSumaPesos(listaCriteriosLocal);
    bool sumaOk = suma >= 0.99 && suma <= 1.01;
    bool todosTienenPeso = listaCriteriosLocal.every((c) => (double.tryParse(c['peso'].toString()) ?? 0.0) > 0);
    return sumaOk && todosTienenPeso;
  }

  bool _estanDescriptoresCorrectos() {
    if (listaCriteriosLocal.isEmpty) return false;
    return listaCriteriosLocal.every((c) => (c['descriptores'] as List? ?? []).isNotEmpty);
  }

  Widget _buildHalfBar({required String text, required bool isOk}) {
    return Expanded(
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(color: isOk ? Colors.green : Colors.orange),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0)),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    bool criteriosOk = _estanCriteriosCorrectos();
    bool descriptoresOk = _estanDescriptoresCorrectos();
    return Container(
      key: _keySumaText,
      color: Colors.white,
      child: Row(
        children: [
          _buildHalfBar(text: criteriosOk ? "CRITERIOS: OK" : "CRITERIOS: REVISAR PESOS", isOk: criteriosOk),
          const SizedBox(width: 1),
          _buildHalfBar(text: descriptoresOk ? "DESCRIPTORES: OK" : "DESCRIPTORES: REVISAR", isOk: descriptoresOk),
        ],
      ),
    );
  }

  Future<void> _intentarFinalizar() async {
    List<String> errores = [];
    if (listaCriteriosLocal.isEmpty) {
      errores.add("- Debes añadir al menos un criterio.");
    } else {
      double sumaCriterios = _calcularSumaPesos(listaCriteriosLocal);
      if (sumaCriterios < 0.99 || sumaCriterios > 1.01) {
        errores.add("- La suma de pesos de los criterios debe ser 1.00 (actual: $sumaCriterios).");
      }
      for (var i = 0; i < listaCriteriosLocal.length; i++) {
        var crit = listaCriteriosLocal[i];
        String nombre = crit['nombre'].toString().isEmpty ? "Criterio ${i + 1}" : crit['nombre'];
        if ((double.tryParse(crit['peso'].toString()) ?? 0.0) <= 0) {
          errores.add("- '$nombre' no tiene un peso asignado.");
        }
        List descs = crit['descriptores'] ?? [];
        if (descs.isEmpty) {
          errores.add("- '$nombre' no tiene ningún descriptor/nivel.");
        }
      }
    }

    if (errores.isNotEmpty) {
      _mostrarAlertaErrores(errores);
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('artifacts/$__app_id/users/$userId/rubricas')
          .doc(widget.rubricaId)
          .update({'criterios': listaCriteriosLocal});
      _mostrarConfirmacionFinal();
    } catch (e) {
      _mostrarAlertaErrores(["Error de conexión: $e"]);
    }
  }

  void _mostrarAlertaErrores(List<String> errores) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Condiciones faltantes"),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: errores.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e, style: const TextStyle(fontSize: 14)),
            )).toList(),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: headerColor),
              child: const Text("VOLVER A CORREGIR", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _mostrarAlertaLimitePeso() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.error_outline, color: Colors.red, size: 50),
        content: const Text(
          "La sumatoria de los pesos de los Criterios de Evaluación no puede ser mayor a 1. Por favor, modifique el peso asignado al nuevo criterio de evaluación.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: headerColor),
              child: const Text("ACEPTAR", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _mostrarConfirmacionFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Rúbrica guardada exitosamente en la nube.", textAlign: TextAlign.center),
        actions: [Center(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("FINALIZAR")))],
      ),
    );
  }

  Future<bool> _advertirSalida() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cerrar sin guardar?"),
        content: const Text("Los cambios realizados se perderán si no presionas 'Finalizar y Guardar'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("SALIR", style: TextStyle(color: Colors.white))),
        ],
      ),
    ) ?? false;
  }

  void _mostrarDialogoCriterio({Map<String, dynamic>? existente, int? index}) {
    final nombreCtrl = TextEditingController(text: existente?['nombre'] ?? '');
    final pesoCtrl = TextEditingController(text: existente?['peso']?.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existente == null ? 'Nuevo Criterio' : 'Editar Criterio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre del criterio')),
            const SizedBox(height: 10),
            TextField(controller: pesoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso (0.0 a 1.0)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () {
            if (nombreCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un nombre"), backgroundColor: Colors.red));
              return;
            }
            double nuevoPeso = double.tryParse(pesoCtrl.text) ?? 0.0;
            if (nuevoPeso > 1.0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El peso no puede ser mayor a 1.0"), backgroundColor: Colors.red));
              return;
            }

            List<dynamic> listaTemp = List.from(listaCriteriosLocal);
            if (index == null) {
              listaTemp.add({'nombre': nombreCtrl.text.trim(), 'peso': nuevoPeso, 'descriptores': []});
            } else {
              listaTemp[index] = {'nombre': nombreCtrl.text.trim(), 'peso': nuevoPeso, 'descriptores': listaCriteriosLocal[index]['descriptores']};
            }

            double sumaActual = _calcularSumaPesos(listaTemp);
            if (sumaActual > 1.0) {
              Navigator.pop(ctx);
              _mostrarAlertaLimitePeso();
              return;
            }

            setState(() {
              if (index == null) listaCriteriosLocal.add(listaTemp.last); else listaCriteriosLocal[index] = listaTemp[index];
            });
            Navigator.pop(ctx);
          }, child: const Text('ACEPTAR')),
        ],
      ),
    );
  }

  void _mostrarDialogoDescriptor(int critIdx, {Map<String, dynamic>? existente, int? descIdx}) {
    final contextoCtrl = TextEditingController(text: existente?['contexto'] ?? '');
    final pesoCtrl = TextEditingController(text: existente?['peso']?.toString() ?? '0.0');
    final a1NCtrl = TextEditingController(text: existente?['analitico1']?['nombre'] ?? '');
    final g1Ctrl = TextEditingController(text: existente?['analitico1']?['grado']?.toString() ?? '0.0');
    String? operador = existente?['operador'];
    final a2NCtrl = TextEditingController(text: existente?['analitico2']?['nombre'] ?? '');
    final g2Ctrl = TextEditingController(text: existente?['analitico2']?['grado']?.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nivel / Descriptor'),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.blue),
                onPressed: () {
                  TutorialHelper().showTutorial(
                    context: ctx,
                    pageId: 'EDITAR_DESCRIPTOR',
                    keys: {'contexto': _kCtx, 'peso_desc': _kPesoDesc, 'boton_aceptar': _kBtnAceptar},
                    force: true,
                  );
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(key: _kCtx, controller: contextoCtrl, decoration: const InputDecoration(labelText: 'Contexto')),
                TextField(key: _kPesoDesc, controller: pesoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso del Nivel (max 1.0)')),
                const Divider(),
                TextField(controller: a1NCtrl, decoration: const InputDecoration(labelText: 'Analítico 1')),
                TextField(controller: g1Ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Grado Analítico 1 (max 1.0)')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Operador Lógico'),
                    value: operador,
                    items: [null, 'AND', 'OR'].map((op) => DropdownMenuItem(value: op, child: Text(op ?? 'Ninguno'))).toList(),
                    onChanged: (val) => setDialogState(() => operador = val)
                ),
                if (operador != null) ...[
                  TextField(controller: a2NCtrl, decoration: const InputDecoration(labelText: 'Analítico 2')),
                  TextField(controller: g2Ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Grado Analítico 2 (max 1.0)')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
                key: _kBtnAceptar,
                onPressed: () {
                  // Validación: Debe tener Analítico 1
                  if (a1NCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes cargar al menos el Analítico 1"), backgroundColor: Colors.red));
                    return;
                  }

                  double p = double.tryParse(pesoCtrl.text) ?? 0.0;
                  double gr1 = double.tryParse(g1Ctrl.text) ?? 0.0;
                  double gr2 = double.tryParse(g2Ctrl.text) ?? 0.0;
                  if (p > 1.0 || gr1 > 1.0 || gr2 > 1.0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ningún valor puede ser mayor a 1.0"), backgroundColor: Colors.red));
                    return;
                  }
                  setState(() {
                    List descs = List.from(listaCriteriosLocal[critIdx]['descriptores'] ?? []);
                    final nuevo = {
                      'contexto': contextoCtrl.text,
                      'peso': p,
                      'analitico1': {'nombre': a1NCtrl.text, 'grado': gr1},
                      'operador': operador,
                      'analitico2': operador != null ? {'nombre': a2NCtrl.text, 'grado': gr2} : null
                    };
                    if (descIdx == null) descs.add(nuevo); else descs[descIdx] = nuevo;
                    listaCriteriosLocal[critIdx]['descriptores'] = descs;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('ACEPTAR')
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarElemento(int cIdx, {int? dIdx}) {
    setState(() {
      if (dIdx == null) {
        listaCriteriosLocal.removeAt(cIdx);
      } else {
        List descs = List.from(listaCriteriosLocal[cIdx]['descriptores'] ?? []);
        descs.removeAt(dIdx);
        listaCriteriosLocal[cIdx]['descriptores'] = descs;
      }
    });
  }

  Widget _buildAnaliticoChip(String nombre, double grado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.3))),
      child: Text("$nombre: ${grado.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargandoInicial) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        backgroundColor: headerColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () async { if (await _advertirSalida()) Navigator.pop(context); }),
        title: Text(widget.nombreInicial, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TutorialHelper.helpButton(context, () => _lanzarTutorial(force: true)),
          AuthHelper.logoutButton(context)
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: listaCriteriosLocal.length,
              itemBuilder: (context, cIdx) {
                final c = listaCriteriosLocal[cIdx];
                final List descs = c['descriptores'] ?? [];
                final double pesoCrit = double.tryParse(c['peso'].toString()) ?? 0.0;
                final bool critError = (pesoCrit == 0 || descs.isEmpty);

                return Card(
                  key: cIdx == 0 ? _keyPrimerCriterio : null,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      side: critError ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(c['nombre'], style: TextStyle(color: headerColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Peso: ${pesoCrit.toStringAsFixed(2)} | Descriptores: ${descs.length}",
                        style: TextStyle(color: critError ? Colors.red : Colors.grey[700])
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(key: cIdx == 0 ? _keyPrimerEditCriterio : null, icon: const Icon(Icons.edit_note, color: Colors.blue), onPressed: () => _mostrarDialogoCriterio(existente: c, index: cIdx)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _eliminarElemento(cIdx)),
                      ],
                    ),
                    children: [
                      ...descs.asMap().entries.map((e) {
                        final d = e.value;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: const Border(left: BorderSide(color: Colors.blue, width: 5)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text("${d['contexto']} (Peso: ${d['peso']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          key: (cIdx == 0 && e.key == 0) ? _keyEditDescriptorTutorial : null,
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          onPressed: () => _mostrarDialogoDescriptor(cIdx, existente: d, descIdx: e.key)
                                      ),
                                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => _eliminarElemento(cIdx, dIdx: e.key)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildAnaliticoChip(d['analitico1']?['nombre'] ?? 'A1', double.tryParse(d['analitico1']?['grado']?.toString() ?? '0.0') ?? 0.0),
                                  if (d['operador'] != null) ...[
                                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(d['operador'], style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                                    _buildAnaliticoChip(d['analitico2']?['nombre'] ?? 'A2', double.tryParse(d['analitico2']?['grado']?.toString() ?? '0.0') ?? 0.0),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      ListTile(key: cIdx == 0 ? _keyPrimerAddDescriptor : null, leading: const Icon(Icons.add_circle_outline, color: Colors.green), title: const Text("Añadir Nivel", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), onTap: () => _mostrarDialogoDescriptor(cIdx))
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(key: _keyBotonFisico, onPressed: () => _mostrarDialogoCriterio(), icon: const Icon(Icons.add, color: Colors.white), label: const Text("AÑADIR CRITERIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800])),
                ElevatedButton.icon(key: _keyBotonFinalizar, onPressed: _intentarFinalizar, icon: const Icon(Icons.cloud_upload, color: Colors.white), label: const Text("FINALIZAR Y GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700])),
              ],
            ),
          )
        ],
      ),
    );
  }
}