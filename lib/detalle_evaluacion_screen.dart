// detalle_evaluacion_screen.dart
import 'package:flutter/material.dart';

class DetalleEvaluacionScreen extends StatelessWidget {
  final Map<String, dynamic> evaluacionData;

  const DetalleEvaluacionScreen({
    super.key,
    required this.evaluacionData,
  });

  String get _appBarTitle {
    return 'Detalle: ${evaluacionData['estudiante']}';
  }

  String get _notaFinalDisplay {
    final nota = evaluacionData['notaFinal'] as double? ?? 0.0;
    return nota.toStringAsFixed(2);
  }

  // Widget auxiliar para mostrar la información detallada de un Analítico
  Widget _buildAnaliticoDetail({required String nombre, required double gradoAsignado}) {
    // Definimos el color basado en si el grado asignado es cero o no
    final Color color = gradoAsignado > 0.0 ? Colors.purple : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
      child: Text(
        '$nombre - Grado Asignado: ${gradoAsignado.toStringAsFixed(1)}',
        style: TextStyle(color: color, fontSize: 14),
      ),
    );
  }

  // Lógica principal para construir la vista de los resultados
  Widget _buildResultados(BuildContext context) {
    final notaFinal = _notaFinalDisplay;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Center( // Centramos el contenido para mayor responsiveness en pantallas grandes
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800), // Limita el ancho máximo
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de resumen
              Text(
                'Rúbrica: ${evaluacionData['nombreRubrica']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Fecha: ${evaluacionData['fecha']}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Nota Final (Usando un Card vistoso)
              Card(
                color: primaryColor.withOpacity(0.05), // Fondo sutil
                elevation: 4, // Usamos una elevación separada para este Card de resumen
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                          'Nota Final de Evaluación',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                      Text(
                        notaFinal,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // TÍTULO CORREGIDO: "Detalle"
              const Text(
                'Detalle:', // Título corregido
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 60, 60, 60)),
              ),
              const SizedBox(height: 12),

              // Simulación del Detalle del Criterio 1:
              Card(
                // Usa la configuración de CardTheme de main.dart (bordes redondeados, sombra)
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del Criterio
                      Text(
                        'Criterio 1: Investigación',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Peso Criterio: 0.50', style: TextStyle(color: Colors.grey.shade600)),
                      const Divider(),

                      // Descriptor
                      Text(
                        'Descriptor: Profundidad de las fuentes',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 8),

                      // Analítico 1
                      _buildAnaliticoDetail(
                        nombre: 'Analítico 1: Fuentes académicas',
                        gradoAsignado: 0.6,
                      ),

                      const SizedBox(height: 12),

                      // OPERADOR LÓGICO (Posición corregida: entre Analítico 1 y Analítico 2)
                      Text(
                        'Operador Lógico: Media Aritmética (AND)',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 12),

                      // Analítico 2
                      _buildAnaliticoDetail(
                        nombre: 'Analítico 2: Fuentes primarias',
                        gradoAsignado: 0.0,
                      ),

                      const SizedBox(height: 12),

                      // Resultado Compensatorio
                      Text(
                        'Resultado Compensatorio (Descriptor): 0.30',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              // Aquí se agregarían otros criterios de forma dinámica...
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        // El estilo del AppBar ya viene del tema global en main.dart
      ),
      body: _buildResultados(context),
    );
  }
}