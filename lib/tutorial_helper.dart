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
    if (isShowing) return;

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
            _crearTarget(
              id: "h_ban",
              key: keys['banner']!,
              paso: "1",
              titulo: "Bienvenido",
              mensaje: "Aquí verás tu saludo personalizado, el logo de ELOS y la foto/imagen de perfil que cargues.",
              esCirculo: true,
            ),
          if (keys.containsKey('opciones'))
            _crearTarget(
              id: "h_opc",
              key: keys['opciones']!,
              paso: "2",
              titulo: "Menú Principal",
              mensaje: "Desde aquí puedes crear nuevas rúbricas, evaluarlas o consultar el historial de calificaciones.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('perfil'))
            _crearTarget(
              id: "h_perf",
              key: keys['perfil']!,
              paso: "3",
              titulo: "Tu Perfil",
              mensaje: "Gestiona tu información personal y/o actualiza tu foto/imagen de perfil.",
              esCirculo: true,
            ),
        ];
        break;

      case 'CREAR_RUBRICA':
        targets = [
          if (keys.containsKey('nombre_rubrica'))
            _crearTarget(
              id: "cr_nom",
              key: keys['nombre_rubrica']!,
              paso: "1",
              titulo: "Título de la Rúbrica",
              mensaje: "Asigna un nombre descriptivo para identificar tu rúbrica en la biblioteca.",
              esCirculo: false,
            ),
          if (keys.containsKey('tipo_rubrica'))
            _crearTarget(
              id: "cr_tipo",
              key: keys['tipo_rubrica']!,
              paso: "2",
              titulo: "Tipo de Rúbrica",
              mensaje: "Selecciona el modelo de evaluación: 'Tradicional' para asignar puntajes fijos según el nivel de logro, o 'Difusa' para medir de forma flexible el grado de adquisición de competencias.",
              esCirculo: false,
            ),
          if (keys.containsKey('btn_guardar'))
            _crearTarget(
              id: "cr_save",
              key: keys['btn_guardar']!,
              paso: "3",
              titulo: "Guardar y Continuar",
              mensaje: "Presiona para crear la estructura e ir a la configuración detallada de los criterios.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'EDITAR_RUBRICA_SCREEN':
        targets = [
          if (keys.containsKey('barra_estado') || keys.containsKey('nombre_rubrica'))
            _crearTarget(
              id: "ed_bar",
              key: (keys['barra_estado'] ?? keys['nombre_rubrica'])!,
              paso: "1",
              titulo: "Barra de Estado y Validación",
              mensaje: "Indica en verde cuando los porcentajes de los criterios suman 100% y cuando todos los descriptores tienen su texto completado.",
              esCirculo: false,
            ),
          if (keys.containsKey('niveles_globales'))
            _crearTarget(
              id: "ed_niv",
              key: keys['niveles_globales']!,
              paso: "2",
              titulo: "Niveles Globales de Evaluación",
              mensaje: "Define los niveles de logro (ej. Excelente, Bueno) y el puntaje asignado que se aplicarán automáticamente a todos los criterios.",
              esCirculo: false,
            ),
          if (keys.containsKey('lista_criterios'))
            _crearTarget(
              id: "ed_crit",
              key: keys['lista_criterios']!,
              paso: "3",
              titulo: "Criterios de Evaluación",
              mensaje: "Aquí se listan los criterios. Puedes editar su nombre y asignar el porcentaje correspondiente a cada competencia.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('edit_descriptor'))
            _crearTarget(
              id: "ed_desc",
              key: keys['edit_descriptor']!,
              paso: "4",
              titulo: "Texto del Descriptor (Obligatorio)",
              mensaje: "Es necesario presionar el icono de lápiz para redactar el texto explicativo de cada nivel de logro. No podrás guardar hasta completar todos los descriptores.",
              esCirculo: true,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('btn_actualizar'))
            _crearTarget(
              id: "ed_upd",
              key: keys['btn_actualizar']!,
              paso: "5",
              titulo: "Guardar Rúbrica",
              mensaje: "Al presionar este botón se validarán los porcentajes y descriptores completos antes de almacenar los datos en la nube.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'EDITAR_RUBRICA_DIFUSA':
        targets = [
          if (keys.containsKey('barra_estado') || keys.containsKey('nombre_rubrica'))
            _crearTarget(
              id: "ed_bar",
              key: (keys['barra_estado'] ?? keys['nombre_rubrica'])!,
              paso: "1",
              titulo: "Barra de Estado y Validación",
              mensaje: "Indica en verde cuando los porcentajes de los criterios suman 100% y cuando todos los descriptores tienen su texto completado.",
              esCirculo: false,
            ),
          if (keys.containsKey('niveles_globales'))
            _crearTarget(
              id: "ed_niv",
              key: keys['niveles_globales']!,
              paso: "2",
              titulo: "Niveles Globales de Evaluación",
              mensaje: "Configurar una rúbrica difusa será más simple que una rúbrica tradicional, ya que se establece por defecto un solo nivel con el máximo de puntos cargados: 10 puntos por defecto (que no podrán ser modificados).",
              esCirculo: false,
            ),
          if (keys.containsKey('lista_criterios'))
            _crearTarget(
              id: "ed_crit",
              key: keys['lista_criterios']!,
              paso: "3",
              titulo: "Criterios de Evaluación",
              mensaje: "Aquí se listan los criterios. Puedes editar su nombre y asignar el porcentaje correspondiente a cada competencia.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('edit_descriptor'))
            _crearTarget(
              id: "ed_desc",
              key: keys['edit_descriptor']!,
              paso: "4",
              titulo: "Texto del Descriptor (Obligatorio)",
              mensaje: "Es necesario presionar el icono de lápiz para redactar el texto explicativo de cada nivel de logro. No podrás guardar hasta completar todos los descriptores.",
              esCirculo: true,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('btn_actualizar'))
            _crearTarget(
              id: "ed_upd",
              key: keys['btn_actualizar']!,
              paso: "5",
              titulo: "Guardar Rúbrica",
              mensaje: "Al presionar este botón se validarán los porcentajes y descriptores completos antes de almacenar los datos en la nube.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'EDITAR_DESCRIPTOR':
        targets = [
          if (keys.containsKey('contexto'))
            _crearTarget(
              id: "desc_ctx",
              key: keys['contexto']!,
              paso: "1",
              titulo: "Redacción del Descriptor",
              mensaje: "Ingresa la explicación detallada sobre qué evidencia o desempeño debe mostrar el estudiante para alcanzar este nivel.",
              esCirculo: false,
            ),
          if (keys.containsKey('boton_aceptar'))
            _crearTarget(
              id: "desc_btn",
              key: keys['boton_aceptar']!,
              paso: "2",
              titulo: "Confirmar Descriptor",
              mensaje: "Guarda el texto ingresado para actualizar el indicador de la rúbrica.",
              esCirculo: false,
            ),
        ];
        break;

      case 'LISTA_RUBRICAS':
        targets = [
          if (keys.containsKey('buscador'))
            _crearTarget(
              id: "lr_busc",
              key: keys['buscador']!,
              paso: "1",
              titulo: "Buscador de Rúbricas",
              mensaje: "Encuentra rúbricas rápidamente ingresando palabras clave de su título.",
              esCirculo: false,
            ),
          if (keys.containsKey('tipo_rubrica'))
            _crearTarget(
              id: "lr_tipo",
              key: keys['tipo_rubrica']!,
              paso: "2",
              titulo: "Tipo de Rúbrica",
              mensaje: "Selecciona si deseas visualizar Rúbricas Tradicionales o Rúbricas Difusas para cargar la lista.",
              esCirculo: false,
            ),
          if (keys.containsKey('filtro_fecha'))
            _crearTarget(
              id: "lr_fecha",
              key: keys['filtro_fecha']!,
              paso: "3",
              titulo: "Orden y Filtros",
              mensaje: "Organiza la lista de rúbricas por fecha de creación o modificación.",
              esCirculo: false,
            ),
          if (keys.containsKey('primera_card'))
            _crearTarget(
              id: "lr_card",
              key: keys['primera_card']!,
              paso: "4",
              titulo: "Gestión de la Rúbrica",
              mensaje: "Selecciona una tarjeta para iniciar una evaluación, editar su contenido o eliminarla.",
              esCirculo: false,
            ),
        ];
        break;

      case 'LISTA_EVALUACIONES':
        targets = [
          if (keys.containsKey('buscador_estudiante'))
            _crearTarget(
              id: "le_busc",
              key: keys['buscador_estudiante']!,
              paso: "1",
              titulo: "Buscar Estudiante",
              mensaje: "Filtra la lista de evaluaciones históricas escribiendo el nombre o apellido del alumno.",
              esCirculo: false,
            ),
          if (keys.containsKey('tipo_rubrica'))
            _crearTarget(
              id: "le_tipo",
              key: keys['tipo_rubrica']!,
              paso: "2",
              titulo: "Tipo de Rúbrica",
              mensaje: "Selecciona si deseas visualizar evaluaciones de Rúbrica Tradicional o Rúbrica Difusa.",
              esCirculo: false,
            ),
          if (keys.containsKey('filtro_calendario'))
            _crearTarget(
              id: "le_cal",
              key: keys['filtro_calendario']!,
              paso: "3",
              titulo: "Filtrar por Fecha",
              mensaje: "Consulta las calificaciones registradas en una fecha o período específico.",
              esCirculo: true,
            ),
          if (keys.containsKey('primera_evaluacion'))
            _crearTarget(
              id: "le_card",
              key: keys['primera_evaluacion']!,
              paso: "4",
              titulo: "Ver Resultados",
              mensaje: "Accede al detalle completo de la calificación o genera el reporte en formato PDF.",
              esCirculo: false,
            ),
        ];
        break;

      case 'DETALLE_EVALUACION':
        targets = [
          if (keys.containsKey('puntaje_total'))
            _crearTarget(
              id: "de_score",
              key: keys['puntaje_total']!,
              paso: "1",
              titulo: "Calificación Final",
              mensaje: "Muestra la nota total calculada según los niveles seleccionados en cada criterio.",
              esCirculo: false,
            ),
          if (keys.containsKey('tabla_resumen'))
            _crearTarget(
              id: "de_table",
              key: keys['tabla_resumen']!,
              paso: "2",
              titulo: "Desglose por Criterio",
              mensaje: "Revisa la puntuación y el nivel alcanzado en cada categoría evaluada.",
              esCirculo: false,
            ),
          if (keys.containsKey('btn_pdf'))
            _crearTarget(
              id: "de_pdf",
              key: keys['btn_pdf']!,
              paso: "3",
              titulo: "Exportar PDF",
              mensaje: "Genera un documento PDF oficial con el informe de la evaluación listo para compartir.",
              esCirculo: true,
            ),
        ];
        break;

      case 'EVALUAR_RUBRICA':
        targets = [
          if (keys.containsKey('importar'))
            _crearTarget(
              id: "er_imp",
              key: keys['importar']!,
              paso: "1",
              titulo: "Importación Masiva",
              mensaje: "Carga una lista de estudiantes automáticamente subiendo un archivo Excel; puedes descargar una plantilla para facilitar tu trabajo.",
              esCirculo: false,
            ),
          if (keys.containsKey('selector'))
            _crearTarget(
              id: "er_sel",
              key: keys['selector']!,
              paso: "2",
              titulo: "Selección de Estudiante",
              mensaje: "Elige al estudiante que vas a calificar desde la lista importada.",
              esCirculo: false,
            ),
          if (keys.containsKey('tab_manual'))
            _crearTarget(
              id: "er_man",
              key: keys['tab_manual']!,
              paso: "3",
              titulo: "Ingreso Manual",
              mensaje: "Ingresa los datos del estudiante de forma directa si no utilizas una lista precalculada.",
              esCirculo: false,
            ),
          if (keys.containsKey('btn_comenzar'))
            _crearTarget(
              id: "er_btn",
              key: keys['btn_comenzar']!,
              paso: "4",
              titulo: "Comenzar Evaluación",
              mensaje: "Abre la pantalla interactiva de calificación para este estudiante.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'EJECUTAR_EVALUACION_TRADICIONAL':
        targets = [
          if (keys.containsKey('primer_nivel'))
            _crearTarget(
              id: "eet_nivel",
              key: keys['primer_nivel']!,
              paso: "1",
              titulo: "Marcación de Desempeño",
              mensaje: "Selecciona el descriptor que represente el nivel de logro demostrado por el estudiante.",
              esCirculo: false,
            ),
          if (keys.containsKey('nota_final'))
            _crearTarget(
              id: "eet_nota",
              key: keys['nota_final']!,
              paso: "2",
              titulo: "Nota en Tiempo Real",
              mensaje: "Visualiza cómo se actualiza la calificación total a medida que completas cada criterio.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('btn_guardar_eval'))
            _crearTarget(
              id: "eet_save",
              key: keys['btn_guardar_eval']!,
              paso: "3",
              titulo: "Guardar Evaluación",
              mensaje: "Almacena permanentemente el resultado final y sincroniza los datos con el historial.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'EJECUTAR_EVALUACION_DIFUSA':
        targets = [
          if (keys.containsKey('primer_nivel'))
            _crearTarget(
              id: "eed_nivel",
              key: keys['primer_nivel']!,
              paso: "1",
              titulo: "Asignación de Puntaje",
              mensaje: "Ingresa el puntaje del criterio manualmente o utiliza el slider para ajustarlo.",
              esCirculo: false,
            ),
          if (keys.containsKey('nota_final'))
            _crearTarget(
              id: "eed_nota",
              key: keys['nota_final']!,
              paso: "2",
              titulo: "Nota en Tiempo Real",
              mensaje: "Visualiza cómo se actualiza la calificación total a medida que completas cada criterio.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
          if (keys.containsKey('btn_guardar_eval'))
            _crearTarget(
              id: "eed_save",
              key: keys['btn_guardar_eval']!,
              paso: "3",
              titulo: "Guardar Evaluación",
              mensaje: "Almacena permanentemente el resultado final y sincroniza los datos con el historial.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
        ];
        break;

      case 'PERFIL':
        targets = [
          if (keys.containsKey('foto_perfil'))
            _crearTarget(
              id: "p_foto",
              key: keys['foto_perfil']!,
              paso: "1",
              titulo: "Fotografía de Perfil",
              mensaje: "Toca tu imagen para subir o cambiar tu foto desde la galería.",
              esCirculo: true,
            ),
          if (keys.containsKey('campos_datos'))
            _crearTarget(
              id: "p_datos",
              key: keys['campos_datos']!,
              paso: "2",
              titulo: "Datos Personales",
              mensaje: "Modifica tu información personal como nombres, apellidos y tu contraseña (con excepción de tu DNI y mail).",
              esCirculo: false,
            ),
          if (keys.containsKey('boton_guardar'))
            _crearTarget(
              id: "p_save",
              key: keys['boton_guardar']!,
              paso: "3",
              titulo: "Confirmar Cambios",
              mensaje: "Guarda la información modificada en tu cuenta de usuario.",
              esCirculo: false,
              alineacion: ContentAlign.top,
            ),
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