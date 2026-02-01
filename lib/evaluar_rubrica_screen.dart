// evaluar_rubrica_screen.dart (Versión Final Corregida)
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <<< Añadir Import de FirebaseAuth
import 'auth_helper.dart';

class EvaluarRubricaScreen extends StatefulWidget {
  final Map<String, dynamic> rubrica;

  const EvaluarRubricaScreen({super.key, required this.rubrica});

  @override
  State<EvaluarRubricaScreen> createState() => _EvaluarRubricaScreenState();
}

class _EvaluarRubricaScreenState extends State<EvaluarRubricaScreen> {
  // ... (Las variables de estado se mantienen) ...
  final List<String> _estudiantes = ['Juan Pérez', 'Ana Gómez', 'Grupo A', 'Grupo B'];
  String? _estudianteSeleccionado;
  final Map<String, double> _evaluacionValores = {};
  double _notaCalculada = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _estudianteSeleccionado = _estudiantes.first;
    _inicializarEvaluacion();
    _calcularNotaFinal();
  }

  void _inicializarEvaluacion() {
    _evaluacionValores.clear();
    for (var criterio in (widget.rubrica['criterios'] as List? ?? [])) {
      for (var descriptor in (criterio['descriptores'] as List? ?? [])) {
        for (var analitico in (descriptor['analiticos'] as List? ?? [])) {
          final String key = '${criterio['nombre']}_${descriptor['contexto']}_${analitico['descripcion']}';
          _evaluacionValores[key] = 0.0;
        }
      }
    }
  }

  void _onGradoPertenenciaChanged(String key, double newValue) {
    setState(() {
      _evaluacionValores[key] = newValue;
      _calcularNotaFinal();
    });
  }

  void _onEstudianteChanged(String? newValue) {
    setState(() {
      _estudianteSeleccionado = newValue;
      _inicializarEvaluacion();
      _calcularNotaFinal();
    });
  }

  double _calcularValorDescriptorCompensatorio(List<double> gradosAsignados, Map<String, dynamic>? operador) {
    if (gradosAsignados.isEmpty) return 0.0;
    if (gradosAsignados.length == 1) return gradosAsignados.first;

    if (operador != null && operador['nombre'] == 'Media Aritmética') {
      final double suma = gradosAsignados.reduce((a, b) => a + b);
      return suma / gradosAsignados.length;
    }

    return gradosAsignados.first;
  }

  void _calcularNotaFinal() {
    double notaFinal = 0.0;
    final List criterios = widget.rubrica['criterios'] as List? ?? [];

    for (var criterio in criterios) {
      final double pesoCriterio = criterio['peso'] as double? ?? 0.0;
      final List descriptores = criterio['descriptores'] as List? ?? [];

      double valorCriterio = 0.0;

      for (var descriptor in descriptores) {
        final double pesoDescriptor = descriptor['pesoDescriptor'] as double? ?? 0.0;
        final List analiticos = descriptor['analiticos'] as List? ?? [];
        final Map<String, dynamic>? operador = descriptor['operador'] as Map<String, dynamic>?;

        List<double> gradosAsignados = [];
        for (var analitico in analiticos) {
          final String analiticoDesc = analitico['descripcion'];
          final String analiticoKey = '${criterio['nombre']}_${descriptor['contexto']}_$analiticoDesc';
          gradosAsignados.add(_evaluacionValores[analiticoKey] ?? 0.0);
        }

        final double valorDescriptor = _calcularValorDescriptorCompensatorio(gradosAsignados, operador);
        valorCriterio += (pesoDescriptor * valorDescriptor);
      }
      notaFinal += (pesoCriterio * valorCriterio);
    }

    setState(() {
      _notaCalculada = notaFinal;
    });
  }

  // ==========================================================
  // LÓGICA DE GUARDADO EN FIRESTORE (FINAL)
  // ==========================================================
  void _guardarEvaluacion() async {
    if (_estudianteSeleccionado == null || _isSaving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, seleccione un estudiante/grupo.')),
      );
      return;
    }

    // Obtener el ID del usuario actual para el registro
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 1. Crear el mapa de valores analíticos con precisión de 2 decimales, manteniendo el tipo double
    final Map<String, double> valoresAnaliticosPonderados = _evaluacionValores.map(
          (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
    );

    // 2. Crear el objeto de la evaluación
    final Map<String, dynamic> evaluacionData = {
      'rubricaId': widget.rubrica['docId'],
      'nombreRubrica': widget.rubrica['nombre'],
      'estudiante': _estudianteSeleccionado,
      'evaluadorId': userId, // <<< ID del usuario para saber quién evaluó
      'notaFinal': double.parse(_notaCalculada.toStringAsFixed(2)),
      'fechaEvaluacion': FieldValue.serverTimestamp(),
      'valoresAnaliticos': valoresAnaliticosPonderados, // Usamos el mapa de doubles
    };

    try {
      // 3. Guardar en la colección 'evaluaciones'
      // Usamos una colección de evaluaciones para el usuario actual (similar a cómo se carga en lista_rubricas_screen.dart)
      // Ruta: artifacts/{appId}/users/{userId}/evaluaciones
      const String appId = 'rubrica_evaluator'; // Usamos la misma constante de la otra pantalla
      final String collectionPath = 'artifacts/$appId/users/$userId/evaluaciones';

      await FirebaseFirestore.instance.collection(collectionPath).add(evaluacionData);

      // 4. Mostrar éxito y salir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evaluación guardada con éxito para $_estudianteSeleccionado. NOTA: ${_notaCalculada.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );

      // Volver a la pantalla anterior después de guardar
      Navigator.of(context).pop();

    } catch (e) {
      // 5. Manejar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la evaluación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ... (El resto del método build se mantiene igual) ...

  @override
  Widget build(BuildContext context) {
    final List criterios = widget.rubrica['criterios'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar: ${widget.rubrica['nombre']}'),
        actions: [
          AuthHelper.logoutButton(context), // <--- Añadir aquí
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Estudiante
              DropdownButtonFormField<String>(
                value: _estudianteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Evaluar a',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.person),
                ),
                items: _estudiantes.map((String est) {
                  return DropdownMenuItem<String>(
                    value: est,
                    child: Text(est),
                  );
                }).toList(),
                onChanged: _onEstudianteChanged,
              ),
              const SizedBox(height: 16),

              // 2. Nota Final Calculada (Actualizada en tiempo real)
              Text(
                'NOTA FINAL CALCULADA: ${_notaCalculada.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 3. Iteración sobre Criterios y Asignación de Puntuación
              Expanded(
                child: ListView.builder(
                  itemCount: criterios.length,
                  itemBuilder: (context, criterioIndex) {
                    final criterio = criterios[criterioIndex];
                    final List descriptores = criterio['descriptores'] as List? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                            'Criterio ${criterioIndex + 1}: ${criterio['nombre']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)
                        ),
                        subtitle: Text('Peso Criterio: ${(criterio['peso'] as double? ?? 0.0).toStringAsFixed(2)}'),
                        children: descriptores.map((descriptor) {
                          final List analiticos = descriptor['analiticos'] as List? ?? [];
                          final operador = descriptor['operador'];

                          List<double> gradosAsignados = analiticos.map((a) {
                            final String key = '${criterio['nombre']}_${descriptor['contexto']}_${a['descripcion']}';
                            return _evaluacionValores[key] ?? 0.0;
                          }).toList();
                          final double valorDescriptorCalculado = _calcularValorDescriptorCompensatorio(gradosAsignados, operador);


                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Descriptor
                                Text(
                                    'Descriptor:',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)
                                ),
                                Text('Peso Descriptor: ${(descriptor['pesoDescriptor'] as double? ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                Text(
                                    'Contexto: ${descriptor['contexto']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black87)
                                ),
                                const Divider(height: 10),

                                // Iteración sobre Criterios Analíticos
                                ...analiticos.asMap().entries.map((entry) {
                                  final int analiticoIndex = entry.key;
                                  final analitico = entry.value;

                                  final String analiticoDesc = analitico['descripcion'];
                                  final double objetivo = analitico['gradoPertenencia'] as double? ?? 0.0;
                                  final String displayTitle = 'Criterio Analítico ${analiticoIndex + 1}: $analiticoDesc';
                                  final String analiticoKey = '${criterio['nombre']}_${descriptor['contexto']}_$analiticoDesc';
                                  final double currentValue = _evaluacionValores[analiticoKey] ?? 0.0;


                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('Grado de Pertenencia (Objetivo): ${objetivo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.indigo)),

                                      // SLIDER (Entrada de datos del docente)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              value: currentValue,
                                              min: 0.0,
                                              max: 1.0,
                                              divisions: 10,
                                              label: currentValue.toStringAsFixed(1),
                                              onChanged: (double value) {
                                                _onGradoPertenenciaChanged(analiticoKey, double.parse(value.toStringAsFixed(1)));
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              currentValue.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (analiticoIndex == 0 && operador != null && analiticos.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Text(
                                            'Operador: ${operador['nombre']}',
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                }).toList(),

                                Text(
                                    'Valor del Descriptor (suma ponderada) [V: ${valorDescriptorCalculado.toStringAsFixed(2)}]',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              // Botón de Guardar Evaluación
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarEvaluacion,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Evaluación y Finalizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}