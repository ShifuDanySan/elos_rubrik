// Archivo: lib/models/rubrica_models.dart (Actualizado)

// === 1. COLECCIÓN CRITERIOS ANALITICOS ===
class CriterioAnalitico {
  String descripcionCriterioAnalitico;
  double gradoPertenenciaCriterioAnalitico; // Decimal(5,2)

  CriterioAnalitico({
    required this.descripcionCriterioAnalitico,
    required this.gradoPertenenciaCriterioAnalitico,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'descripcionCriterioAnalitico': descripcionCriterioAnalitico,
      'gradoPertenenciaCriterioAnalitico': gradoPertenenciaCriterioAnalitico,
    };
  }
}

// === 2. COLECCIÓN OPERADORES ===
class Operador {
  String simboloOperador;
  String tipoOperador; // (ej: AND, OR, NOT)
  String? formulaOperador;

  Operador({
    required this.simboloOperador,
    required this.tipoOperador,
    this.formulaOperador,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'simboloOperador': simboloOperador,
      'tipoOperador': tipoOperador,
      'formulaOperador': formulaOperador,
    };
  }
}

// === 3. COLECCIÓN DESCRIPTORES ===
class Descriptor {
  String contextoDescriptor;
  double resultadoCompensatorio; // Decimal(5,2)
  List<CriterioAnalitico> criteriosAnaliticos;
  List<Operador> operadores; // Agregamos la lista de Operadores

  Descriptor({
    required this.contextoDescriptor,
    required this.resultadoCompensatorio,
    this.criteriosAnaliticos = const [],
    this.operadores = const [], // Inicialización
  });

  Map<String, dynamic> toFirestore() {
    return {
      'contextoDescriptor': contextoDescriptor,
      'resultadoCompensatorio': resultadoCompensatorio,
      // Operadores y Criterios Analíticos se guardarán en colecciones separadas
    };
  }
}

// === 4. COLECCIÓN CRITERIOS DE EVALUACION ===
class CriterioEvaluacion {
  String nombreCriterio;
  double pesoCriterio; // Decimal(5,2)
  List<Descriptor> descriptores;

  CriterioEvaluacion({
    required this.nombreCriterio,
    required this.pesoCriterio,
    this.descriptores = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nombreCriterio': nombreCriterio,
      'pesoCriterio': pesoCriterio,
    };
  }
}

// La colección 'EVALUACIONES' se asocia a 'RUBRICAS'
// La colección 'RUBRICAS' se asocia a 'EVALUACIONES'
// Su creación se gestionará en una futura pantalla de 'Evaluar'.