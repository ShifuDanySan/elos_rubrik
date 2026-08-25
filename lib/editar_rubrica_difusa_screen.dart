import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

class EditarRubricaDifusaScreen extends StatefulWidget {
  final String rubricaId;
  final String nombreInicial;

  const EditarRubricaDifusaScreen({
    super.key,
    required this.rubricaId,
    required this.nombreInicial,
  });

  @override
  State<EditarRubricaDifusaScreen> createState() => _EditarRubricaDifusaScreenState();
}

class _EditarRubricaDifusaScreenState extends State<EditarRubricaDifusaScreen> with WidgetsBindingObserver {
  final String __app_id = 'rubrica_evaluator';
  final Color headerColor = const Color(0xFF1A237E);

  final GlobalKey _keySumaText = GlobalKey();
  final GlobalKey _keyNivelesGlobales = GlobalKey();
  final GlobalKey _keyPrimerCriterio = GlobalKey();
  final GlobalKey _keyPrimerEditCriterio = GlobalKey();
  final GlobalKey _keyEditDescriptorTutorial = GlobalKey();
  final GlobalKey _keyBotonFinalizar = GlobalKey();
  final GlobalKey _keyBotonFisico = GlobalKey();

  final GlobalKey _kCtx = GlobalKey();
  final GlobalKey _kPesoDesc = GlobalKey();
  final GlobalKey _kBtnAceptar = GlobalKey();

  List<dynamic> listaCriteriosLocal = [];
  List<Map<String, dynamic>> nivelesGlobales = [];
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

  void _mostrarAviso(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ACEPTAR"))
        ],
      ),
    );
  }

  void _mostrarInfoConceptos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cómo organizar la rúbrica difusa?"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DEFINICIONES:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("1. CRITERIOS DE EVALUACIÓN: son las categorías principales (competencias). El 'Porcentaje' define su importancia total (debe sumar 100%)."),
              Text("2. NIVELES GLOBALES: definen la escala de calificación y sus puntos (fijos en 10), comunes para todos los criterios."),
              Text("3. DESCRIPTORES: texto explicativo para cada nivel dentro de un criterio específico."),
              Divider(height: 30),
              Text("EJEMPLO (Rúbrica Difusa):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("• Criterio de Evaluación: 'Calidad de Código' (Porcentaje 15%)."),
              Text("• Nivel: 'Excelente' (Puntos 10) -> Valor Descriptor: 1.5."),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("¡ENTENDIDO!"))],
      ),
    );
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
      final criteriosData = List.from(doc.data()?['criterios'] ?? []);

      List<Map<String, dynamic>> tempNiveles = [];
      if (criteriosData.isNotEmpty) {
        final List primerDescs = criteriosData.first['descriptores'] ?? [];
        for (var d in primerDescs) {
          tempNiveles.add({
            'contexto': d['contexto'] ?? '',
            'peso': 10.0,
          });
        }
      }

      for (var crit in criteriosData) {
        List descs = crit['descriptores'] ?? [];
        for (var d in descs) {
          d['peso'] = 10.0;
          d['puntos'] = 10.0;
        }
      }

      setState(() {
        listaCriteriosLocal = criteriosData;
        nivelesGlobales = tempNiveles;
        cargandoInicial = false;
      });
    }
  }

  Future<void> _lanzarTutorial({bool force = false}) async {
    if (force) {
      await TutorialHelper().resetTutorials(['EDITAR_RUBRICA_DIFUSA', 'EDITAR_DESCRIPTOR']);
    }

    Map<String, GlobalKey> tutorialKeys = {
      'barra_estado': _keySumaText,
      'niveles_globales': _keyNivelesGlobales,
      'lista_criterios': _keyPrimerCriterio,
      'edit_descriptor': _keyEditDescriptorTutorial,
      'btn_actualizar': _keyBotonFinalizar,
    };

    if (mounted) {
      TutorialHelper().showTutorial(
          context: context,
          pageId: 'EDITAR_RUBRICA_DIFUSA',
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
    bool sumaOk = suma >= 99.0 && suma <= 100.1;
    bool todosTienenPeso = listaCriteriosLocal.every((c) => (double.tryParse(c['peso'].toString()) ?? 0.0) > 0);
    return sumaOk && todosTienenPeso;
  }

  bool _estanDescriptoresCorrectos() {
    if (listaCriteriosLocal.isEmpty) return false;
    if (nivelesGlobales.isEmpty) return false;
    return listaCriteriosLocal.every((c) {
      List descs = c['descriptores'] as List? ?? [];
      if (descs.isEmpty) return false;
      return descs.every((d) {
        String txt = (d['descriptor']?.toString().trim().isNotEmpty == true)
            ? d['descriptor'].toString().trim()
            : (d['texto']?.toString().trim() ?? '');
        return txt.isNotEmpty;
      });
    });
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
          _buildHalfBar(text: criteriosOk ? "CRITERIOS DE EVALUACIÓN - OK" : "CRITERIOS DE EVALUACIÓN - REVISAR PORCENTAJES", isOk: criteriosOk),
          const SizedBox(width: 1),
          _buildHalfBar(text: descriptoresOk ? "NIVELES DE EVALUACIÓN - OK" : "NIVELES DE EVALUACIÓN - REVISAR DESCRIPTORES", isOk: descriptoresOk),
        ],
      ),
    );
  }

  void _sincronizarNivelesConCriterios() {
    for (var c in listaCriteriosLocal) {
      List descsExistentes = List.from(c['descriptores'] ?? []);
      List nuevosDescs = [];

      for (int i = 0; i < nivelesGlobales.length; i++) {
        final ng = nivelesGlobales[i];
        String descTexto = '';

        if (i < descsExistentes.length) {
          descTexto = descsExistentes[i]['descriptor'] ?? descsExistentes[i]['texto'] ?? '';
        }

        nuevosDescs.add({
          'contexto': ng['contexto'],
          'peso': 10.0,
          'puntos': 10.0,
          'descriptor': descTexto,
          'texto': descTexto,
        });
      }

      c['descriptores'] = nuevosDescs;
    }
  }

  void _mostrarDialogoNivelGlobal({Map<String, dynamic>? existente, int? index}) {
    final nivelCtrl = TextEditingController(text: existente?['contexto'] ?? '');
    final pesoCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existente == null ? 'Añadir Nivel Global' : 'Editar Nivel Global'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nivelCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre del Nivel (Ej: Excelente)')),
            const SizedBox(height: 10),
            TextField(
              controller: pesoCtrl,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Puntos (Por defecto 10)',
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nivelCtrl.text.trim().isEmpty) {
                _mostrarAviso("Error", "El nombre del nivel es obligatorio.");
                return;
              }

              setState(() {
                final nuevoNivel = {
                  'contexto': nivelCtrl.text.trim(),
                  'peso': 10.0,
                  'puntos': 10.0,
                };

                if (index == null) {
                  nivelesGlobales.add(nuevoNivel);
                } else {
                  nivelesGlobales[index] = nuevoNivel;
                }

                _sincronizarNivelesConCriterios();
              });

              Navigator.pop(ctx);
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  void _eliminarNivelGlobal(int index) {
    if (nivelesGlobales.length <= 1) {
      _mostrarAviso("Aviso", "El nivel no puede ser eliminado (debe existir al menos un nivel).");
      return;
    }
    setState(() {
      nivelesGlobales.removeAt(index);
      _sincronizarNivelesConCriterios();
    });
  }

  Widget _buildSeccionNivelesGlobales() {
    return Container(
      key: _keyNivelesGlobales,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NIVELES DE EVALUACIÓN (GLOBALES)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)),
          ),
          const SizedBox(height: 8),
          if (nivelesGlobales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No hay niveles definidos.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: nivelesGlobales.asMap().entries.map((e) {
                final idx = e.key;
                final ng = e.value;

                return InkWell(
                  onTap: () => _mostrarDialogoNivelGlobal(existente: ng, index: idx),
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    backgroundColor: Colors.blue.shade50,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${ng['contexto'].toString().toUpperCase()} (10 pts)"),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ],
                    ),
                    onDeleted: nivelesGlobales.length > 1 ? () => _eliminarNivelGlobal(idx) : null,
                    deleteIcon: nivelesGlobales.length > 1 ? const Icon(Icons.close, size: 18) : null,
                    avatar: CircleAvatar(
                      backgroundColor: headerColor,
                      child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                );
              }).toList(),
            ),
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
      if (sumaCriterios < 99.0 || sumaCriterios > 100.1) {
        errores.add("- La suma de porcentajes de los criterios debe ser 100% (actual: ${sumaCriterios}%).");
      }
      if (nivelesGlobales.isEmpty) {
        errores.add("- Debes añadir al menos un nivel global.");
      }
      for (var i = 0; i < listaCriteriosLocal.length; i++) {
        var crit = listaCriteriosLocal[i];
        String nombre = crit['nombre'].toString().isEmpty ? "Criterio ${i + 1}" : crit['nombre'];
        if ((double.tryParse(crit['peso'].toString()) ?? 0.0) <= 0) {
          errores.add("- '$nombre' no tiene un porcentaje asignado.");
        }
        List descs = crit['descriptores'] ?? [];
        if (descs.isEmpty) {
          errores.add("- '$nombre' no tiene ningún descriptor/nivel.");
        } else {
          for (var j = 0; j < descs.length; j++) {
            var desc = descs[j];
            String txt = (desc['descriptor']?.toString().trim().isNotEmpty == true)
                ? desc['descriptor'].toString().trim()
                : (desc['texto']?.toString().trim() ?? '');
            if (txt.isEmpty) {
              String nivelNom = desc['contexto']?.toString() ?? 'Nivel ${j + 1}';
              errores.add("- '$nombre': Falta completar el texto del descriptor para '$nivelNom'.");
            }
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
          .update({
        'criterios': listaCriteriosLocal,
        'fechaModificacion': FieldValue.serverTimestamp(),
      });
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
          "La sumatoria de los porcentajes de los Criterios de Evaluación no puede ser mayor a 100%. Por favor, modifique el porcentaje asignado al criterio.",
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
        content: const Text("Rúbrica difusa guardada exitosamente en la nube.", textAlign: TextAlign.center),
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
    final pesoCtrl = TextEditingController(text: existente?['peso']?.toString() ?? existente?['porcentaje']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existente == null ? 'Nuevo Criterio' : 'Editar Criterio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre del criterio')),
            const SizedBox(height: 10),
            TextField(
              controller: pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'Porcentaje (1 a 100%)', suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () {
            if (nombreCtrl.text.trim().isEmpty) {
              _mostrarAviso("Error", "El nombre es obligatorio.");
              return;
            }

            String textoPorcentaje = pesoCtrl.text.trim().replaceAll(',', '.');
            double? peso = double.tryParse(textoPorcentaje);

            if (peso == null || peso <= 0 || peso > 100.0) {
              _mostrarAviso("Error", "El porcentaje debe ser un número entre 1 y 100.");
              return;
            }

            peso = double.parse(peso.toStringAsFixed(2));

            List<dynamic> listaTemp = List.from(listaCriteriosLocal);

            List nuevosDescriptores = nivelesGlobales.map((ng) {
              return {
                'contexto': ng['contexto'],
                'peso': 10.0,
                'puntos': 10.0,
                'descriptor': '',
                'texto': '',
              };
            }).toList();

            if (index == null) {
              listaTemp.add({
                'nombre': nombreCtrl.text.trim(),
                'peso': peso,
                'porcentaje': peso,
                'descriptores': nuevosDescriptores,
              });
            } else {
              listaTemp[index] = {
                'nombre': nombreCtrl.text.trim(),
                'peso': peso,
                'porcentaje': peso,
                'descriptores': listaCriteriosLocal[index]['descriptores'] ?? nuevosDescriptores,
              };
            }

            double sumaActual = _calcularSumaPesos(listaTemp);
            if (sumaActual > 100.0) {
              Navigator.pop(ctx);
              _mostrarAlertaLimitePeso();
              return;
            }

            setState(() {
              if (index == null) {
                listaCriteriosLocal.add(listaTemp.last);
              } else {
                listaCriteriosLocal[index] = listaTemp[index];
              }
            });
            Navigator.pop(ctx);
          }, child: const Text('ACEPTAR')),
        ],
      ),
    );
  }

  void _mostrarDialogoDescriptor(int critIdx, int descIdx, Map<String, dynamic> existente) {
    final descriptorCtrl = TextEditingController(text: existente['descriptor'] ?? existente['texto'] ?? '');
    final String nombreNivel = existente['contexto'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Descriptor: $nombreNivel (10 pts)', style: const TextStyle(fontSize: 16))),
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
                TextField(
                  key: _kCtx,
                  controller: descriptorCtrl,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Texto del Descriptor',
                    hintText: 'Describa el nivel de logro para este criterio...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
                key: _kBtnAceptar,
                onPressed: () {
                  if (descriptorCtrl.text.trim().isEmpty) {
                    _mostrarAviso("Error", "El texto del descriptor es obligatorio.");
                    return;
                  }

                  setState(() {
                    List descs = List.from(listaCriteriosLocal[critIdx]['descriptores'] ?? []);
                    descs[descIdx] = {
                      'contexto': nombreNivel,
                      'peso': 10.0,
                      'puntos': 10.0,
                      'descriptor': descriptorCtrl.text.trim(),
                      'texto': descriptorCtrl.text.trim(),
                    };
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

  void _eliminarElemento(int cIdx) {
    if (listaCriteriosLocal.length <= 1) {
      _mostrarAviso("Aviso", "La rúbrica debe tener al menos un criterio.");
      return;
    }
    setState(() {
      listaCriteriosLocal.removeAt(cIdx);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargandoInicial) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        backgroundColor: headerColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () async { if (await _advertirSalida()) Navigator.pop(context); }),
        title: isMobile ? null : Text(widget.nombreInicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'Manual de usuario',
              onPressed: _abrirManualPdf,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: headerColor,
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
          Tooltip(
            message: "Ver conceptos y ejemplos",
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _mostrarInfoConceptos,
            ),
          ),
          TutorialHelper.helpButton(context, () => _lanzarTutorial(force: true)),
          AuthHelper.logoutButton(context)
        ],
      ),
      body: Column(
        children: [
          if (isMobile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Text(
                widget.nombreInicial,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _buildStatusBar(),
          _buildSeccionNivelesGlobales(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: listaCriteriosLocal.length,
              itemBuilder: (context, cIdx) {
                final c = listaCriteriosLocal[cIdx];
                final List descs = c['descriptores'] ?? [];
                final double pesoCrit = double.tryParse(c['peso']?.toString() ?? c['porcentaje']?.toString() ?? '0') ?? 0.0;

                List<String> erroresCrit = [];
                if (pesoCrit == 0) erroresCrit.add("Porcentaje en 0%");
                if (descs.isEmpty) erroresCrit.add("Sin descriptores");
                if (descs.any((d) => ((d['descriptor']?.toString().trim().isNotEmpty == true) ? d['descriptor'].toString().trim() : (d['texto']?.toString().trim() ?? '')).isEmpty)) {
                  erroresCrit.add("Descriptores incompletos");
                }
                final bool critError = erroresCrit.isNotEmpty;

                return Card(
                  key: cIdx == 0 ? _keyPrimerCriterio : null,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      side: critError ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: [
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: Text("CRITERIO DE EVALUACIÓN ${cIdx + 1} (${c['nombre'].toUpperCase()} - PESO: $pesoCrit%)", style: TextStyle(color: headerColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "NIVELES: ${descs.length}",
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
                            final String descTexto = (d['descriptor']?.toString().trim().isNotEmpty == true)
                                ? d['descriptor'].toString().trim()
                                : (d['texto']?.toString().trim() ?? '');

                            final double valorDescriptor = (pesoCrit / 100.0) * 10.0;
                            final String valorDescriptorFormatted = (valorDescriptor % 1 == 0)
                                ? valorDescriptor.toInt().toString()
                                : valorDescriptor.toStringAsFixed(1);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    color: descTexto.isEmpty ? Colors.red : Colors.blue,
                                    width: 5,
                                  ),
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "NIVEL ${e.key + 1} (${d['contexto'].toUpperCase()} - PUNTOS: 10 - VALOR DESCRIPTOR: $valorDescriptorFormatted)",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      IconButton(
                                        key: (cIdx == 0 && e.key == 0) ? _keyEditDescriptorTutorial : null,
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () => _mostrarDialogoDescriptor(cIdx, e.key, d),
                                      ),
                                    ],
                                  ),
                                  if (descTexto.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(descTexto, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    const Text("Sin texto de descriptor (Toca el lápiz para agregar)", style: TextStyle(fontSize: 11, color: Colors.red, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      if (critError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.withOpacity(0.1),
                          child: Text("FALTA: ${erroresCrit.join(', ').toUpperCase()}", style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoCriterio(),
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text("AGREGAR CRITERIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    key: _keyBotonFinalizar,
                    onPressed: _intentarFinalizar,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("GUARDAR Y SALIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: headerColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}