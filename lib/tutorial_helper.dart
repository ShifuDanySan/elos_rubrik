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
    if (_tutorial != null) return;

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
      onFinish: () {
        _marcarComoVisto(pageId);
        _tutorial = null;
      },
      onSkip: () {
        _marcarComoVisto(pageId);
        _tutorial = null;
        return true;
      },
    );

    _tutorial!.show(context: context);
  }

  List<TargetFocus> _configurarTargetsPorPagina(String pageId, Map<String, GlobalKey> keys) {
    List<TargetFocus> targets = [];
    switch (pageId) {
      case 'EVALUAR_RUBRICA':
        if (keys.containsKey('importar')) {
          _addStep(targets, keys['importar']!, "Importar listado de estudiantes", "Puedes descargar una plantilla Excel o importar directamente tu lista de estudiantes.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('selector')) {
          _addStep(targets, keys['selector']!, "Seleccionar Estudiante", "Una vez importado el archivo, elige aquí al estudiante que vas a evaluar.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('tab_manual')) {
          _addStep(targets, keys['tab_manual']!, "Carga Manual", "Si no tienes un Excel, puedes ingresar los datos del estudiante manualmente aquí.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('btn_comenzar')) {
          _addStep(targets, keys['btn_comenzar']!, "Iniciar", "Cuando el formulario esté completo, presiona este botón para abrir la matriz de evaluación.", ContentAlign.top, pageId);
        }
        break;

      case 'LISTA_RUBRICAS':
        if (keys.containsKey('buscador')) {
          _addStep(targets, keys['buscador']!, "Buscador", "Encuentra tus rúbricas rápidamente escribiendo su nombre.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('filtro_fecha')) {
          _addStep(targets, keys['filtro_fecha']!, "Filtro por Fecha", "Localiza tus rúbricas por el día en que fueron creadas.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('primera_card')) {
          _addStep(targets, keys['primera_card']!, "Tus Rúbricas", "Toca cualquier rúbrica de la lista para ver las opciones de evaluar, editar o eliminar.", ContentAlign.bottom, pageId);
        }
        break;

      case 'LISTA_EVALUACIONES':
        if (keys.containsKey('buscador_estudiante')) {
          _addStep(targets, keys['buscador_estudiante']!, "Buscador de Estudiantes", "Filtra el historial escribiendo el nombre del estudiante evaluado.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('filtro_calendario')) {
          _addStep(targets, keys['filtro_calendario']!, "Calendario", "Busca evaluaciones realizadas en una fecha específica.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('primera_evaluacion')) {
          _addStep(targets, keys['primera_evaluacion']!, "Detalle del Resultado", "Presiona una tarjeta para ver el desglose completo de la nota, criterios y comentarios.", ContentAlign.bottom, pageId);
        }
        break;

      case 'OPCIONES_RUBRICA':
        if (keys.containsKey('opcion_evaluar')) {
          _addStep(targets, keys['opcion_evaluar']!, "Comenzar Evaluación", "Usa esta opción para calificar a tus estudiantes usando esta rúbrica.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('opcion_editar')) {
          _addStep(targets, keys['opcion_editar']!, "Modificar", "Cambia criterios, pesos o descriptores de la rúbrica.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('opcion_eliminar')) {
          _addStep(targets, keys['opcion_eliminar']!, "Eliminar Rúbrica", "Borra permanentemente esta rúbrica si ya no la necesitas.", ContentAlign.top, pageId);
        }
        break;

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
        if (keys.containsKey('clase_peso')) {
          _addStep(targets, keys['clase_peso']!, "Peso", "Influencia de este descriptor.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('boton_aceptar')) {
          _addStep(targets, keys['boton_aceptar']!, "Guardar", "Finaliza el descriptor.", ContentAlign.top, pageId);
        }
        break;

      case 'DETALLE_EVALUACION':
        if (keys.containsKey('card_nota')) {
          _addStep(targets, keys['card_nota']!, "Resumen de Nota", "Aquí puedes ver los datos básicos del estudiante y la rúbrica, así como la calificación obtenida durante la aplicación de la misma.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('btn_pdf')) {
          _addStep(targets, keys['btn_pdf']!, "Exportar Reporte", "Genera un documento PDF detallado con todos los resultados obtenidos.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('desglose_criterio')) {
          _addStep(targets, keys['desglose_criterio']!, "Análisis Detallado", "Explora cómo se compone el puntaje de cada criterio revisando los analíticos y evidencias evaluadas.", ContentAlign.top, pageId);
        }
        if (keys.containsKey('btn_info')) {
          _addStep(targets, keys['btn_info']!, "Lógica de Evaluación", "Toca aquí para entender el modelo matemático de Lógica Compensatoria Difusa utilizado para calcular esta nota.", ContentAlign.bottom, pageId);
        }
        break;

      case 'EDITAR_PERFIL':
        if (keys.containsKey('avatar')) {
          _addStep(targets, keys['avatar']!, "Foto de Perfil", "Toca tu imagen para subir una nueva fotografía desde tu galería.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('campos_fijos')) {
          _addStep(targets, keys['campos_fijos']!, "Información de Registro", "El DNI y el Email no se pueden modificar por seguridad, ya que están vinculados a tu cuenta.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('boton_guardar')) {
          _addStep(targets, keys['boton_guardar']!, "Guardar Cambios", "Una vez que termines de actualizar tu nombre o contraseña, presiona este botón para aplicar los cambios.", ContentAlign.top, pageId);
        }
        break;

      case 'EJECUTAR_EVALUACION':
        if (keys.containsKey('primer_analitico')) {
          _addStep(targets, keys['primer_analitico']!, "Escala de Calificación", "Desliza para asignar un valor entre 0 y 1. Este representa el cumplimiento de este indicador específico.", ContentAlign.bottom, pageId);
        }
        if (keys.containsKey('valor_descriptor')) {
          _addStep(targets, keys['valor_descriptor']!, "Resultado del Descriptor", "Este valor se calcula automáticamente multiplicando tus entradas por el grado objetivo del analítico.", ContentAlign.top, pageId);
        }
        if (keys.containsKey('nota_final')) {
          _addStep(targets, keys['nota_final']!, "Calificación Final", "Aquí verás el resultado global basado en los pesos de cada criterio de tu rúbrica.", ContentAlign.top, pageId);
        }
        if (keys.containsKey('btn_guardar_eval')) {
          _addStep(targets, keys['btn_guardar_eval']!, "Registrar Evaluación", "Al presionar aquí, la nota se guardará en el historial del estudiante permanentemente.", ContentAlign.top, pageId);
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
    return Tooltip(
      message: "Repetir Tutorial",
      child: IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}