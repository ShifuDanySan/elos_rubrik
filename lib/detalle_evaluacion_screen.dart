import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf_service.dart';

class DetalleEvaluacionScreen extends StatelessWidget {
  final Map<String, dynamic> evaluacion;

  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  @override
  Widget build(BuildContext context) {
    final List criterios = evaluacion['criterios'] ?? [];
    final String estudiante = evaluacion['estudiante'] ?? 'Sin nombre';
    final double notaFinal = (evaluacion['notaFinal'] ?? 0.0).toDouble();

    String fechaStr = "S/F";
    if (evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy').format((evaluacion['fecha'] as Timestamp).toDate());
    }

    const Color primaryColor = Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Evaluación"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // REFORMA: Botón optimizado para Web (Icono + Texto)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: () => PdfService.generarReporteEvaluacion(evaluacion),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
              label: const Text(
                  "EXPORTAR PDF",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(estudiante, evaluacion['nombre'] ?? 'Rúbrica', fechaStr, notaFinal, primaryColor),
            const SizedBox(height: 20),
            const Text("RESULTADOS POR CRITERIO",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const Divider(),
            ...criterios.map((c) => _buildCriterioTile(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String alumno, String rubrica, String fecha, double nota, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(alumno, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text("$rubrica\nFecha: $fecha"),
        trailing: CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Text(nota.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCriterioTile(Map<String, dynamic> criterio) {
    final List descriptores = criterio['descriptores'] ?? [];
    double notaCriterio = 0.0;
    for (var d in descriptores) {
      notaCriterio += (d['resultado_descriptor'] ?? 0.0).toDouble();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(criterio['nombre'] ?? 'Criterio',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: Text(notaCriterio.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
        children: descriptores.map((desc) {
          final List analiticos = desc['analiticos'] ?? [];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc['contexto'] ?? 'Descriptor',
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 5),
                ...analiticos.map((ana) => Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("- ${ana['nombre']}", style: const TextStyle(fontSize: 12)),
                      Text("Val: ${(ana['valor_asignado'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
                const Divider(height: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}