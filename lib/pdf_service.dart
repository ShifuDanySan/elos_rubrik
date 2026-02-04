import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<void> generarReporteEvaluacion(Map<String, dynamic> evaluacion) async {
    final pdf = pw.Document();

    final String estudiante = evaluacion['estudiante'] ?? 'N/A';
    final String rubricaNom = evaluacion['nombre'] ?? 'Evaluación';
    final double notaFinal = (evaluacion['notaFinal'] ?? 0.0).toDouble();

    String fechaStr = "S/F";
    if (evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy').format((evaluacion['fecha'] as Timestamp).toDate());
    }

    final PdfColor primaryBlue = PdfColor.fromInt(0xFF1A237E);
    final PdfColor secondaryGreen = PdfColor.fromInt(0xFF00796B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // CABECERA
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(estudiante, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                    pw.SizedBox(height: 4),
                    pw.Text(rubricaNom, style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("Fecha: $fechaStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(color: primaryBlue, shape: pw.BoxShape.circle),
                  alignment: pw.Alignment.center,
                  child: pw.Text(notaFinal.toStringAsFixed(2),
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          pw.Text("RESULTADOS POR CRITERIO",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.Divider(color: primaryBlue, thickness: 1),
          pw.SizedBox(height: 10),

          // LISTADO DE CRITERIOS
          ...(evaluacion['criterios'] as List? ?? []).map((criterio) {
            final List descriptores = criterio['descriptores'] ?? [];
            double notaCriterio = 0.0;

            // Cálculo seguro de nota
            for (var d in descriptores) {
              notaCriterio += (d['resultado_descriptor'] ?? 0.0).toDouble();
            }

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(criterio['nombre'] ?? 'Criterio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Nota: ${notaCriterio.toStringAsFixed(2)}",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: secondaryGreen)),
                      ],
                    ),
                  ),

                  ...descriptores.map((desc) {
                    final List analiticos = desc['analiticos'] ?? [];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(desc['contexto'] ?? 'Descriptor',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          pw.SizedBox(height: 4),
                          ...analiticos.map((ana) => pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                // Cambiamos el símbolo especial por un guión simple para evitar la "X"
                                pw.Text("- ${ana['nombre']}", style: const pw.TextStyle(fontSize: 9)),
                                pw.Text("Val: ${(ana['valor_asignado'] ?? 0.0).toStringAsFixed(2)}",
                                    style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${estudiante.replaceAll(" ", "_")}.pdf',
    );
  }
}