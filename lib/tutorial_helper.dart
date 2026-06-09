import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'formato_tutorial.dart';

class TutorialHelper {
  static final TutorialHelper _instance = TutorialHelper._internal();
  factory TutorialHelper() => _instance;
  TutorialHelper._internal();

  TutorialCoachMark? tutorialCoachMark;
  String? _lastPageId;
  Map<String, GlobalKey>? _lastKeys;

  bool get isShowing => tutorialCoachMark != null;

  void forceClose() {
    if (tutorialCoachMark != null) {
      tutorialCoachMark!.finish();
      tutorialCoachMark = null;
    }
  }

  void reShowLastTutorial(BuildContext context) {
    if (_lastPageId != null && _lastKeys != null) {
      showTutorial(
        context: context,
        pageId: _lastPageId!,
        keys: _lastKeys!,
        force: true,
      );
    }
  }

  Future<void> resetTutorials(List<String> pageIds) async {
    final prefs = await SharedPreferences.getInstance();
    for (String id in pageIds) {
      await prefs.remove('seen_tutorial_$id');
    }
  }

  static Widget helpButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.help_outline, color: Colors.white),
      onPressed: onPressed,
      tooltip: 'Ver tutorial',
    );
  }

  Future<void> showTutorial({
    required BuildContext context,
    required String pageId,
    required Map<String, GlobalKey> keys,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_tutorial_$pageId') ?? false;

    if (seen && !force) return;

    _lastPageId = pageId;
    _lastKeys = keys;

    List<TargetFocus> targets = [];

    switch (pageId) {
      case 'HOME':
        targets = [
          if (keys.containsKey('banner'))
            _crearTarget(id: "h_ban", key: keys['banner']!, paso: "1", titulo: "Bienvenido", mensaje: "Aquí verás tu saludo personalizado y acceso rápido a tu perfil personal.", esCirculo: true),
          if (keys.containsKey('opciones'))
            _crearTarget(id: "h_opc", key: keys['opciones']!, paso: "2", titulo: "Menú Principal", mensaje: "Desde aquí puedes crear nuevas rúbricas, realizar evaluaciones o revisar el historial de actividades.", esCirculo: false, alineacion: ContentAlign.top),
          if (keys.containsKey('perfil'))
            _crearTarget(id: "h_perf", key: keys['perfil']!, paso: "3", titulo: "Tu Perfil", mensaje: "Gestiona tus datos de usuario, cambia tu fotografía o cierra la sesión desde aquí.", esCirculo: true),
        ];
        break;

      case 'CREAR_RUBRICA':
        targets = [
          if (keys.containsKey('nombre_rubrica'))
            _crearTarget(id: "cr_nom", key: keys['nombre_rubrica']!, paso: "1", titulo: "Título", mensaje: "Asigna un nombre descriptivo para identificar y localizar tu rúbrica fácilmente.", esCirculo: false),
          if (keys.containsKey('add_criterio'))
            _crearTarget(id: "cr_add", key: keys['add_criterio']!, paso: "2", titulo: "Criterios", mensaje: "Agrega las categorías generales. Luego configurarás los detalles técnicos de cada una.", esCirculo: true),
          if (keys.containsKey('btn_guardar'))
            _crearTarget(id: "cr_save", key: keys['btn_guardar']!, paso: "3", titulo: "Finalizar", mensaje: "Guarda la estructura inicial para habilitar la edición avanzada de descriptores y analíticos.", esCirculo: false),
        ];
        break;

      case 'EDITAR_RUBRICA_SCREEN':
        targets = [
          if (keys.containsKey('nombre_rubrica'))
            _crearTarget(id: "ed_nom", key: keys['nombre_rubrica']!, paso: "1", titulo: "Nombre Principal", mensaje: "Modifica el título global de la rúbrica si necesitas una versión diferente.", esCirculo: false),
          if (keys.containsKey('icon_lapiz'))
            _crearTarget(id: "ed_lap", key: keys['icon_lapiz']!, paso: "2", titulo: "Editar Criterio", mensaje: "Toca el LÁPIZ para definir el nombre del aspecto y qué porcentaje de la nota final representa.", esCirculo: true),
          if (keys.containsKey('icon_lista'))
            _crearTarget(id: "ed_lis", key: keys['icon_lista']!, paso: "3", titulo: "Detalles Técnicos", mensaje: "Toca la LISTA para editar niveles de logro, indicadores analíticos, sus pesos y operadores lógicos.", esCirculo: true),
          if (keys.containsKey('btn_add_criterio'))
            _crearTarget(id: "ed_add", key: keys['btn_add_criterio']!, paso: "4", titulo: "Nuevo Elemento", mensaje: "Añade un criterio adicional a la estructura de evaluación actual.", esCirculo: true),
          if (keys.containsKey('btn_actualizar'))
            _crearTarget(id: "ed_upd", key: keys['btn_actualizar']!, paso: "5", titulo: "Sincronizar", mensaje: "Presiona para procesar los cálculos técnicos y guardar todos los cambios en el servidor.", esCirculo: false),
        ];
        break;

      case 'EDITOR_NOMBRE_PESO_CRITERIO':
        targets = [
          if (keys.containsKey('input_nombre_criterio'))
            _crearTarget(id: "enc_nom", key: keys['input_nombre_criterio']!, paso: "1", titulo: "Identificación", mensaje: "Escribe el nombre del área de evaluación (ej: Puntualidad, Coherencia, Uso de recursos).", esCirculo: false),
          if (keys.containsKey('slider_peso_criterio'))
            _crearTarget(id: "enc_peso", key: keys['slider_peso_criterio']!, paso: "2", titulo: "Peso Porcentual", mensaje: "Define qué porcentaje del total de la calificación (0-100%) aporta este criterio específico.", esCirculo: false),
          if (keys.containsKey('btn_aceptar_nombre_peso'))
            _crearTarget(id: "enc_ok", key: keys['btn_aceptar_nombre_peso']!, paso: "3", titulo: "Confirmar", mensaje: "Guarda estos cambios básicos para continuar con la configuración detallada.", esCirculo: false),
        ];
        break;

      case 'EDITOR_DETALLE_CRITERIO':
        targets = [
          if (keys.containsKey('input_descriptor'))
            _crearTarget(id: "det_desc", key: keys['input_descriptor']!, paso: "1", titulo: "Descriptor de Nivel", mensaje: "Define el nombre del nivel de logro (ej: Excelente, Muy Bueno, Regular, Insuficiente).", esCirculo: false),
          if (keys.containsKey('slider_peso_nivel'))
            _crearTarget(id: "det_p_niv", key: keys['slider_peso_nivel']!, paso: "2", titulo: "Peso del Nivel", mensaje: "Establece el puntaje máximo que se puede alcanzar en este nivel de logro específico.", esCirculo: false),
          if (keys.containsKey('input_analitico'))
            _crearTarget(id: "det_ana", key: keys['input_analitico']!, paso: "3", titulo: "Indicador Analítico", mensaje: "Describe la conducta o evidencia observable que el estudiante debe demostrar.", esCirculo: false),
          if (keys.containsKey('slider_peso_analitico'))
            _crearTarget(id: "det_p_ana", key: keys['slider_peso_analitico']!, paso: "4", titulo: "Peso del Analítico", mensaje: "Define el valor o importancia de este indicador dentro del puntaje de este nivel.", esCirculo: false),
          if (keys.containsKey('selector_operador'))
            _crearTarget(id: "det_op", key: keys['selector_operador']!, paso: "5", titulo: "Lógica de Cálculo", mensaje: "Elige cómo se relacionan los indicadores: 'Y' (todos), 'O' (al menos uno) o 'Ninguno'.", esCirculo: false),
          if (keys.containsKey('btn_aceptar_detalle'))
            _crearTarget(id: "det_ok", key: keys['btn_aceptar_detalle']!, paso: "6", titulo: "Finalizar Detalle", mensaje: "Guarda la configuración técnica del descriptor y los parámetros de cálculo asociados.", esCirculo: false),
        ];
        break;

      case 'LISTA_RUBRICAS':
        targets = [
          if (keys.containsKey('buscador'))
            _crearTarget(id: "lr_busc", key: keys['buscador']!, paso: "1", titulo: "Filtrar", mensaje: "Busca rúbricas por su nombre para encontrarlas rápidamente en tu biblioteca.", esCirculo: false),
          if (keys.containsKey('filtro_fecha'))
            _crearTarget(id: "lr_fecha", key: keys['filtro_fecha']!, paso: "2", titulo: "Cronología", mensaje: "Ordena o busca tus diseños según el momento en que fueron creados.", esCirculo: false),
          if (keys.containsKey('primera_card'))
            _crearTarget(id: "lr_card", key: keys['primera_card']!, paso: "3", titulo: "Opciones de Item", mensaje: "Accede a las funciones para evaluar, editar o eliminar el diseño seleccionado.", esCirculo: false),
        ];
        break;

      case 'OPCIONES_RUBRICA':
        targets = [
          if (keys.containsKey('opcion_evaluar'))
            _crearTarget(id: "or_eval", key: keys['opcion_evaluar']!, paso: "1", titulo: "Ir a Evaluar", mensaje: "Inicia una nueva sesión de calificación con esta rúbrica específica.", esCirculo: false),
          if (keys.containsKey('opcion_editar'))
            _crearTarget(id: "or_edit", key: keys['opcion_editar']!, paso: "2", titulo: "Modificar", mensaje: "Entra al editor completo para cambiar nombres, pesos o analíticos.", esCirculo: false),
          if (keys.containsKey('opcion_eliminar'))
            _crearTarget(id: "or_elim", key: keys['opcion_eliminar']!, paso: "3", titulo: "Borrar", mensaje: "Elimina la rúbrica definitivamente. Ten en cuenta que esta acción es irreversible.", esCirculo: false),
        ];
        break;

      case 'LISTA_EVALUACIONES':
        targets = [
          if (keys.containsKey('buscador_estudiante'))
            _crearTarget(id: "le_busc", key: keys['buscador_estudiante']!, paso: "1", titulo: "Estudiante", mensaje: "Busca las calificaciones realizadas filtrando por el nombre del alumno.", esCirculo: false),
          if (keys.containsKey('filtro_calendario'))
            _crearTarget(id: "le_cal", key: keys['filtro_calendario']!, paso: "2", titulo: "Fecha", mensaje: "Encuentra evaluaciones realizadas en un día o periodo específico.", esCirculo: true),
          if (keys.containsKey('primera_evaluacion'))
            _crearTarget(id: "le_card", key: keys['primera_evaluacion']!, paso: "3", titulo: "Resultados", mensaje: "Accede para ver el detalle desglosado o generar el informe oficial en PDF.", esCirculo: false),
        ];
        break;

      case 'DETALLE_EVALUACION':
        targets = [
          if (keys.containsKey('puntaje_total'))
            _crearTarget(id: "de_score", key: keys['puntaje_total']!, paso: "1", titulo: "Nota Final", mensaje: "Muestra la calificación total calculada tras procesar todos los criterios.", esCirculo: false),
          if (keys.containsKey('tabla_resumen'))
            _crearTarget(id: "de_table", key: keys['tabla_resumen']!, paso: "2", titulo: "Resumen", mensaje: "Visualiza la distribución de puntajes obtenidos en cada categoría evaluada.", esCirculo: false),
          if (keys.containsKey('btn_pdf'))
            _crearTarget(id: "de_pdf", key: keys['btn_pdf']!, paso: "3", titulo: "PDF", mensaje: "Exporta un reporte profesional con los resultados para entregar al estudiante.", esCirculo: true),
        ];
        break;

      case 'EVALUAR_RUBRICA':
        targets = [
          if (keys.containsKey('importar'))
            _crearTarget(id: "er_imp", key: keys['importar']!, paso: "1", titulo: "Importar Excel", mensaje: "Carga tu lista de alumnos masivamente usando nuestra plantilla de Excel.", esCirculo: false),
          if (keys.containsKey('selector'))
            _crearTarget(id: "er_sel", key: keys['selector']!, paso: "2", titulo: "Elegir Alumno", mensaje: "Selecciona al estudiante que vas a calificar de la lista cargada.", esCirculo: false),
          if (keys.containsKey('tab_manual'))
            _crearTarget(id: "er_man", key: keys['tab_manual']!, paso: "3", titulo: "Manual", mensaje: "Si lo prefieres, puedes ingresar los datos del alumno directamente aquí.", esCirculo: false),
          if (keys.containsKey('btn_comenzar'))
            _crearTarget(id: "er_btn", key: keys['btn_comenzar']!, paso: "4", titulo: "Comenzar", mensaje: "Entra a la interfaz de calificación interactiva para empezar el proceso.", esCirculo: false),
        ];
        break;

      case 'EJECUTAR_EVALUACION':
        targets = [
          if (keys.containsKey('primer_analitico'))
            _crearTarget(id: "ee_ana", key: keys['primer_analitico']!, paso: "1", titulo: "Calificar", mensaje: "Utiliza los controles para marcar el nivel de desempeño en cada indicador.", esCirculo: false),
          if (keys.containsKey('valor_descriptor'))
            _crearTarget(id: "ee_desc", key: keys['valor_descriptor']!, paso: "2", titulo: "Subtotal", mensaje: "Muestra el puntaje parcial obtenido en este nivel según los analíticos marcados.", esCirculo: false),
          if (keys.containsKey('nota_final'))
            _crearTarget(id: "ee_nota", key: keys['nota_final']!, paso: "3", titulo: "Total Real", mensaje: "Observa en tiempo real cómo se actualiza la calificación total a medida que evalúas.", esCirculo: false),
          if (keys.containsKey('btn_guardar_eval'))
            _crearTarget(id: "ee_save", key: keys['btn_guardar_eval']!, paso: "4", titulo: "Finalizar", mensaje: "Guarda la evaluación completa y sincroniza el resultado con el historial.", esCirculo: false),
        ];
        break;

      case 'PERFIL':
        targets = [
          if (keys.containsKey('foto_perfil'))
            _crearTarget(id: "p_foto", key: keys['foto_perfil']!, paso: "1", titulo: "Avatar", mensaje: "Toca tu imagen para subir una nueva fotografía desde tu galería.", esCirculo: true),
          if (keys.containsKey('campos_datos'))
            _crearTarget(id: "p_datos", key: keys['campos_datos']!, paso: "2", titulo: "Información", mensaje: "Actualiza tus nombres o revisa tus datos de identificación registrados.", esCirculo: false),
          if (keys.containsKey('boton_guardar'))
            _crearTarget(id: "p_save", key: keys['boton_guardar']!, paso: "3", titulo: "Guardar", mensaje: "Aplica y confirma todos los cambios realizados en tu perfil.", esCirculo: false),
        ];
        break;
    }

    if (targets.isEmpty) return;

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF1A237E),
      opacityShadow: 0.8,
      paddingFocus: 10,
      textSkip: "SALTAR",
      onFinish: () {
        prefs.setBool('seen_tutorial_$pageId', true);
        tutorialCoachMark = null;
      },
      onSkip: () {
        prefs.setBool('seen_tutorial_$pageId', true);
        tutorialCoachMark = null;
        return true;
      },
    )..show(context: context);
  }

  static TargetFocus _crearTarget({
    required String id,
    required GlobalKey key,
    required String titulo,
    required String mensaje,
    required String paso,
    required bool esCirculo,
    ContentAlign alineacion = ContentAlign.bottom,
  }) {
    return TargetFocus(
      identify: id,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      shape: esCirculo ? ShapeLightFocus.Circle : ShapeLightFocus.RRect,
      radius: esCirculo ? null : 15,
      contents: [
        TargetContent(
          align: alineacion,
          builder: (context, controller) {
            return FormatoTutorial.contenidoAjustado(
              paso: paso,
              titulo: titulo,
              mensaje: mensaje,
              onSkip: () => controller.next(),
            );
          },
        ),
      ],
    );
  }
}