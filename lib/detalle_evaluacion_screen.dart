import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetalleEvaluacionScreen extends StatelessWidget {
  final Map<String, dynamic> evaluacion;

  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  @override
  Widget build(BuildContext context) {
    final String estudiante = evaluacion['estudiante'] ?? 'N/A';
    final double notaFinal = (evaluacion['notaFinal'] ?? 0.0).toDouble();
    final String nombreRubrica = evaluacion['nombre'] ?? 'Sin nombre especificado';

    String fechaStr = "N/A";
    if (evaluacion['fecha'] != null) {
      fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(evaluacion['fecha'].toDate());
    }

    final List criterios = evaluacion['criterios'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Detalle de Evaluación"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECCIÓN CABECERA: Estudiante y Nota
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                children: [
                  Text(
                    estudiante,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text("Fecha: $fechaStr", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),

                  // ETIQUETA LLAMATIVA DE LA RÚBRICA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_turned_in, size: 18, color: Color(0xFF1A237E)),
                        const SizedBox(width: 8),
                        Text(
                          "Rúbrica: $nombreRubrica",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    notaFinal.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: notaFinal >= 7 ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                    ),
                  ),
                  const Text("NOTA FINAL", style: TextStyle(letterSpacing: 1.5, fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // LISTADO DE CRITERIOS EVALUADOS
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "DESGLOSE POR CRITERIO",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ...criterios.map((crit) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        title: Text(
                          crit['nombre'] ?? 'Criterio',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          "Nota: ${crit['notaObtenida']?.toStringAsFixed(2) ?? '0.00'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: (crit['descriptores'] as List? ?? []).map((desc) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      desc['contexto'] ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    // Muestra los analíticos y lo que se evaluó en ellos
                                    ...(desc['analiticos'] as List? ?? []).map((ana) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "- ${ana['nombre']}",
                                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              "Val: ${ana['valor_asignado']?.toStringAsFixed(2)}",
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}