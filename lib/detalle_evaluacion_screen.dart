import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pdf_service.dart';

class DetalleEvaluacionScreen extends StatelessWidget {
  final Map<String, dynamic> evaluacion;

  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Detalle: ${evaluacion['estudiante']}"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Exportar a PDF",
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generarReporte(evaluacion),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final List<dynamic> criterios = evaluacion['criterios'] ?? [];
    String fechaFormateada = 'Sin fecha';

    if (evaluacion['fecha'] != null) {
      fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(evaluacion['fecha'].toDate());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD CALIFICACIÓN FINAL
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("CALIFICACIÓN FINAL",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(
                    "${evaluacion['notaFinal']}",
                    style: const TextStyle(fontSize: 58, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 5),
                  Text(fechaFormateada, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text("ANÁLISIS DE DESEMPEÑO POR CRITERIO",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          const SizedBox(height: 15),
          ...criterios.asMap().entries.map((entry) {
            int index = entry.key + 1;
            var crit = entry.value;
            final List<dynamic> descriptores = crit['descriptores'] ?? [];
            double sumaBase = descriptores.fold(0.0, (prev, desc) => prev + (desc['resultado_descriptor'] ?? 0.0));
            double puntajeCriterio = sumaBase.clamp(0.0, 1.0);

            return Card(
              margin: const EdgeInsets.only(bottom: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildCriterioHeader(index, crit['nombre'] ?? 'Criterio'),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusLegend(puntajeCriterio),
                        const SizedBox(height: 20),
                        ...descriptores.map((desc) => _buildDescriptorTile(desc)).toList(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "PUNTAJE CRITERIO $index: ${puntajeCriterio.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCriterioHeader(int index, String nombre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFF1A237E),
            child: Text("$index", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nombre.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptorTile(Map<String, dynamic> desc) {
    final List<dynamic> analiticos = desc['analiticos'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${desc['contexto']}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        ...analiticos.map((ana) => Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Text("• ${ana['nombre']}: ${(ana['valor_asignado'] ?? 0.0).toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        )).toList(),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal Descriptor:", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("${(desc['resultado_descriptor'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildStatusLegend(double valor) {
    Color color;
    String texto;
    IconData icono;
    if (valor >= 0.8) {
      color = const Color(0xFF2E7D32);
      texto = "El estudiante obtuvo un desempeño excelente";
      icono = Icons.stars;
    } else if (valor >= 0.4) {
      color = const Color(0xFFEF6C00); // Naranja para buen desempeño
      texto = "El estudiante obtuvo un buen desempeño";
      icono = Icons.check_circle;
    } else {
      color = Colors.redAccent;
      texto = "Alerta de desempeño para este criterio";
      icono = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}