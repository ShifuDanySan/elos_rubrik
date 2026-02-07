import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static final TutorialHelper _instance = TutorialHelper._internal();
  factory TutorialHelper() => _instance;
  TutorialHelper._internal();

  TutorialCoachMark? _tutorial;
  static const String _prefKeyPrefix = 'tutorial_seen_';

  void showTutorial({
    required BuildContext context,
    required String pageId,
    required Map<String, GlobalKey> keys,
    bool force = false,
  }) async {
    if (!force) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('$_prefKeyPrefix$pageId') ?? false) return;
    }

    List<TargetFocus> targets = _configurarTargetsPorPagina(pageId, keys);
    if (targets.isEmpty) return;

    _tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF1A237E),
      hideSkip: true,
      opacityShadow: 0.8,
      onFinish: () => _marcarComoVisto(pageId),
    );

    _tutorial!.show(context: context);
  }

  List<TargetFocus> _configurarTargetsPorPagina(String pageId, Map<String, GlobalKey> keys) {
    List<TargetFocus> targets = [];
    switch (pageId) {
      case 'EDITAR_RUBRICA':
        if (keys.containsKey('suma')) {
          _addStep(targets, keys['suma']!, "Suma de Pesos", "La suma total debe ser siempre 1.00 para que la rúbrica sea válida.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('primer_criterio')) {
          _addStep(targets, keys['primer_criterio']!, "Criterio", "Bloque que agrupa descriptores. Puedes desplegarlo para ver los niveles de desempeño.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('editar_criterio')) {
          _addStep(targets, keys['editar_criterio']!, "Editar Criterio", "Modifica el nombre o el peso del criterio seleccionado.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('editar_descriptor')) {
          _addStep(targets, keys['editar_descriptor']!, "Editar Descriptor", "Presiona este icono para modificar el contexto, pesos, analíticos y operadores de este descriptor.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('primer_add_descriptor')) {
          _addStep(targets, keys['primer_add_descriptor']!, "Añadir Descriptor", "Define un nuevo nivel de desempeño para este criterio.", ContentAlign.top, pageId);
        }
        if (keys.containsKey('boton_add')) {
          _addStep(targets, keys['boton_add']!, "Nuevo Criterio", "Añade una dimensión adicional a tu evaluación.", ContentAlign.top, pageId);
        }
        if (keys.containsKey('boton_volver')) {
          _addStep(targets, keys['boton_volver']!, "¡Finalizar edición!", "Presiona aquí para guardar y volver cuando:\n\n1) La suma de los pesos de los criterios sea igual a 1.\n2) La suma de los pesos de los descriptores (para cada criterio) sea igual a 1.", ContentAlign.top, pageId);
        }
        break;

      case 'EDITAR_DESCRIPTOR':
        if (keys.containsKey('contexto')) {
          _addStep(targets, keys['contexto']!, "Contexto", "Nivel de desempeño a evaluar.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('peso_desc')) {
          _addStep(targets, keys['peso_desc']!, "Peso", "Influencia de este descriptor.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('boton_aceptar')) {
          _addStep(targets, keys['boton_aceptar']!, "Guardar", "Finaliza el descriptor.", ContentAlign.top, pageId);
        }
        break;
    }
    return targets;
  }

  void _addStep(List<TargetFocus> list, GlobalKey key, String title, String text, ContentAlign align, String pageId) {
    if (key.currentContext == null) return;
    list.add(
      TargetFocus(
        identify: title,
        keyTarget: key,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: align,
            builder: (context, controller) => Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 20, 10, 5),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          _marcarComoVisto(pageId);
                          controller.skip();
                        },
                        child: const Text("SALTAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarComoVisto(String pageId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeyPrefix$pageId', true);
  }

  Future<void> resetTutorials(List<String> pageIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (String id in pageIds) {
      await prefs.remove('$_prefKeyPrefix$id');
    }
  }

  static Widget helpButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(icon: const Icon(Icons.help_outline, color: Colors.white), onPressed: onPressed);
  }
}