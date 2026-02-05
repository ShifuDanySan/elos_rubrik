import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generarReporteEvaluacion(Map<String, dynamic> evaluacion) async {
    final pdf = pw.Document();

    final String estudiante = evaluacion['estudiante'] ?? 'Sin nombre';
    final String nombreRubrica = evaluacion['nombre'] ?? 'Evaluación';
    final double notaFinal = (evaluacion['notaFinal'] ?? 0.0).toDouble();
    final List criterios = evaluacion['criterios'] ?? [];

    String fechaStr = "S/F";
    if (evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy').format((evaluacion['fecha'] as Timestamp).toDate());
    }

    // COLORES EXACTOS DE LA UI (Corregidos)
    final primaryColor = PdfColor.fromInt(0xFF3949AB);
    final accentColor = PdfColor.fromInt(0xFF4FC3F7);
    final lightGrey = PdfColor.fromInt(0xFFF5F5F5);
    final borderColor = PdfColor.fromInt(0xFFD1D1D1); // Reemplazo de transparencia

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ESTILO APPBAR ---
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("DETALLE DE EVALUACIÓN",
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(fechaStr, style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- INFO CARD ---
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(15),
                border: pw.Border.all(color: borderColor, width: 1),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(estudiante.toUpperCase(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: primaryColor)),
                        pw.SizedBox(height: 4),
                        pw.Text(nombreRubrica, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: accentColor, width: 2),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      notaFinal.toStringAsFixed(2),
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.Row(children: [
              pw.Text("DESGLOSE DE RESULTADOS",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 10, letterSpacing: 1.2)),
            ]),
            pw.Divider(thickness: 1, color: primaryColor),
            pw.SizedBox(height: 10),

            // --- CRITERIOS ---
            ...criterios.map((criterio) {
              final List descriptores = criterio['descriptores'] ?? [];
              double notaCriterio = 0.0;
              for (var d in descriptores) {
                notaCriterio += (d['resultado_descriptor'] ?? 0.0).toDouble();
              }

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: lightGrey,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(12),
                          topRight: pw.Radius.circular(12),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(criterio['nombre'] ?? 'Criterio',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Text(notaCriterio.toStringAsFixed(2),
                                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                    ...descriptores.map((desc) {
                      final List analiticos = desc['analiticos'] ?? [];
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(desc['contexto'] ?? 'Descriptor',
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.SizedBox(height: 5),
                            ...analiticos.map((ana) => pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text("- ${ana['nombre']}", style: const pw.TextStyle(fontSize: 10)),
                                  pw.Text((ana['valor_asignado'] ?? 0.0).toStringAsFixed(2),
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                ],
                              ),
                            )),
                            if (desc != descriptores.last) pw.Divider(color: lightGrey, thickness: 0.5),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Evaluacion_${estudiante.replaceAll(" ", "_")}.pdf'
    );
  }
}