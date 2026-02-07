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

class _EditarRubricaScreenState extends State<EditarRubricaScreen> {
  final String __app_id = 'rubrica_evaluator';
  final Color headerColor = const Color(0xFF1A237E);

  final GlobalKey _keySumaText = GlobalKey();
  final GlobalKey _keyBotonFisico = GlobalKey();
  final GlobalKey _keyPrimerCriterio = GlobalKey();
  final GlobalKey _keyPrimerAddDescriptor = GlobalKey();
  final GlobalKey _keyPrimerEditCriterio = GlobalKey();
  final GlobalKey _keyEditDescriptorTutorial = GlobalKey();
  final GlobalKey _keyBotonFinalizar = GlobalKey();

  List<dynamic> listaCriteriosLocal = [];
  bool cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _lanzarTutorial());
    }
  }

  Future<void> _lanzarTutorial({bool force = false}) async {
    if (force) {
      await TutorialHelper().resetTutorials(['EDITAR_RUBRICA', 'EDITAR_DESCRIPTOR']);
    }
    Map<String, GlobalKey> tutorialKeys = {
      'suma': _keySumaText,
      'boton_add': _keyBotonFisico,
      'boton_volver': _keyBotonFinalizar,
    };
    if (listaCriteriosLocal.isNotEmpty) {
      tutorialKeys['primer_criterio'] = _keyPrimerCriterio;
      tutorialKeys['editar_criterio'] = _keyPrimerEditCriterio;
      tutorialKeys['primer_add_descriptor'] = _keyPrimerAddDescriptor;

      final descs = listaCriteriosLocal[0]['descriptores'] as List;
      if (descs.isNotEmpty) {
        tutorialKeys['editar_descriptor'] = _keyEditDescriptorTutorial;
      }
    }
    if (mounted) {
      TutorialHelper().showTutorial(context: context, pageId: 'EDITAR_RUBRICA', keys: tutorialKeys, force: force);
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
    for (var crit in listaCriteriosLocal) {
      List descs = crit['descriptores'] ?? [];
      if (descs.isEmpty) return false;
      double suma = _calcularSumaPesos(descs);
      if (suma < 0.99 || suma > 1.01) return false;
    }
    return true;
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
        } else {
          double sumaDescs = _calcularSumaPesos(descs);
          if (sumaDescs < 0.99 || sumaDescs > 1.01) {
            errores.add("- Los descriptores de '$nombre' deben sumar 1.00 (actual: $sumaDescs).");
          }
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
    double peso = double.tryParse(existente?['peso']?.toString() ?? '0.0') ?? 0.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existente == null ? 'Nuevo Criterio' : 'Editar Criterio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre del criterio')),
              const SizedBox(height: 20),
              Text("Peso: ${peso.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  inactiveTrackColor: Colors.grey[400],
                  activeTrackColor: Colors.blue[700],
                  thumbColor: Colors.blue[900],
                ),
                child: Slider(value: peso, min: 0.0, max: 1.0, divisions: 100, onChanged: (v) => setDialogState(() => peso = v)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(onPressed: () {
              setState(() {
                final nuevo = {'nombre': nombreCtrl.text, 'peso': peso, 'descriptores': index != null ? listaCriteriosLocal[index]['descriptores'] : []};
                if (index == null) listaCriteriosLocal.add(nuevo); else listaCriteriosLocal[index] = nuevo;
              });
              Navigator.pop(ctx);
            }, child: const Text('ACEPTAR')),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoDescriptor(int critIdx, {Map<String, dynamic>? existente, int? descIdx}) {
    final contextoCtrl = TextEditingController(text: existente?['contexto'] ?? '');
    double peso = double.tryParse(existente?['peso']?.toString() ?? '0.0') ?? 0.0;
    final a1NCtrl = TextEditingController(text: existente?['analitico1']?['nombre'] ?? '');
    double grado1 = double.tryParse(existente?['analitico1']?['grado']?.toString() ?? '0.0') ?? 0.0;
    String? operador = existente?['operador'];
    final a2NCtrl = TextEditingController(text: existente?['analitico2']?['nombre'] ?? '');
    double grado2 = double.tryParse(existente?['analitico2']?['grado']?.toString() ?? '0.0') ?? 0.0;

    final GlobalKey keyContexto = GlobalKey();
    final GlobalKey keyPesoDesc = GlobalKey();
    final GlobalKey keyBotonAceptar = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TutorialHelper().showTutorial(
              context: ctx,
              pageId: 'EDITAR_DESCRIPTOR',
              keys: {'contexto': keyContexto, 'peso_desc': keyPesoDesc, 'boton_aceptar': keyBotonAceptar},
              force: false
          );
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Nivel / Descriptor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(key: keyContexto, controller: contextoCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Contexto / Descripción')),
                  const SizedBox(height: 10),
                  Text("Peso del nivel: ${peso.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    key: keyPesoDesc,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        inactiveTrackColor: Colors.grey[400],
                        activeTrackColor: Colors.teal[700],
                        thumbColor: Colors.teal[900],
                      ),
                      child: Slider(value: peso, min: 0, max: 1, divisions: 100, onChanged: (v) => setDialogState(() => peso = v)),
                    ),
                  ),
                  TextField(controller: a1NCtrl, decoration: const InputDecoration(labelText: 'Analítico 1')),
                  Text("Grado 1: ${grado1.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      inactiveTrackColor: Colors.grey[400],
                      activeTrackColor: Colors.teal[700],
                    ),
                    child: Slider(value: grado1, min: 0, max: 1, divisions: 100, onChanged: (v) => setDialogState(() => grado1 = v)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Operador Lógico'),
                      value: operador,
                      items: [null, 'AND', 'OR'].map((op) => DropdownMenuItem(value: op, child: Text(op ?? 'Ninguno'))).toList(),
                      onChanged: (val) => setDialogState(() => operador = val)
                  ),
                  if (operador != null) ...[
                    TextField(controller: a2NCtrl, decoration: const InputDecoration(labelText: 'Analítico 2')),
                    Text("Grado 2: ${grado2.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        inactiveTrackColor: Colors.grey[400],
                        activeTrackColor: Colors.teal[700],
                      ),
                      child: Slider(value: grado2, min: 0, max: 1, divisions: 100, onChanged: (v) => setDialogState(() => grado2 = v)),
                    )
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
              ElevatedButton(
                  key: keyBotonAceptar,
                  onPressed: () {
                    setState(() {
                      List descs = List.from(listaCriteriosLocal[critIdx]['descriptores'] ?? []);
                      final nuevo = {'contexto': contextoCtrl.text, 'peso': peso, 'analitico1': {'nombre': a1NCtrl.text, 'grado': grado1}, 'operador': operador, 'analitico2': operador != null ? {'nombre': a2NCtrl.text, 'grado': grado2} : null};
                      if (descIdx == null) descs.add(nuevo); else descs[descIdx] = nuevo;
                      listaCriteriosLocal[critIdx]['descriptores'] = descs;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('ACEPTAR')
              ),
            ],
          ),
        );
      },
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
                final double sumaDescs = _calcularSumaPesos(descs);
                final double pesoCrit = double.tryParse(c['peso'].toString()) ?? 0.0;
                final bool critError = (pesoCrit == 0 || sumaDescs < 0.99 || sumaDescs > 1.01 || descs.isEmpty);

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
                        "Peso: ${pesoCrit.toStringAsFixed(2)} | Suma Descs: ${sumaDescs.toStringAsFixed(2)}",
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