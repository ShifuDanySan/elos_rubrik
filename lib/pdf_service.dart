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

    final primaryColor = PdfColor.fromInt(0xFF3949AB);
    final accentColor = PdfColor.fromInt(0xFF4FC3F7);
    final lightGrey = PdfColor.fromInt(0xFFF5F5F5);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32), // Quitado 'const'
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("DETALLE DE EVALUACIÓN", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(fechaStr, style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(15), border: pw.Border.all(color: PdfColor.fromInt(0xFFD1D1D1))),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(estudiante.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: primaryColor)),
                      pw.Text(nombreRubrica, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]),
                  ),
                  pw.Container(
                    width: 50, height: 50,
                    decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle, border: pw.Border.all(color: accentColor, width: 2)),
                    alignment: pw.Alignment.center,
                    child: pw.Text(notaFinal.toStringAsFixed(2), style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            ...criterios.map((criterio) {
              final List descriptores = criterio['descriptores'] ?? [];
              double notaCriterio = 0.0;
              for (var d in descriptores) {
                notaCriterio += (d['resultado_descriptor'] ?? 0.0).toDouble();
              }

              return pw.Container(
                margin: pw.EdgeInsets.only(bottom: 16),
                decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(15), border: pw.Border.all(color: PdfColor.fromInt(0xFFD1D1D1))),
                child: pw.Column(children: [
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: pw.BoxDecoration(color: lightGrey, borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(15))),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(criterio['nombre'] ?? 'Criterio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 13)),
                        pw.Container(
                          padding: pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(12)),
                          child: pw.Text(notaCriterio.toStringAsFixed(2), style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  ...descriptores.map((desc) {
                    final List analiticos = desc['analiticos'] ?? [];
                    final double valDesc = (desc['resultado_descriptor'] ?? 0.0).toDouble();

                    return pw.Container(
                      padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text(desc['contexto'] ?? 'Descriptor', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: pw.BoxDecoration(color: lightGrey, borderRadius: pw.BorderRadius.circular(12), border: pw.Border.all(color: primaryColor)),
                            child: pw.Text(valDesc.toStringAsFixed(2), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ),
                        ]),
                        pw.SizedBox(height: 6),
                        ...analiticos.map((ana) => pw.Padding(
                          padding: pw.EdgeInsets.only(left: 12, bottom: 2),
                          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text("- ${ana['nombre']}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text((ana['valor_asignado'] ?? 0.0).toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ]),
                        )),
                      ]),
                    );
                  }).toList(),
                ]),
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