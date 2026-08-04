import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<void> generarReporteEvaluacion(Map<String, dynamic> evaluacion) async {
    final pdf = pw.Document();

    final String estudiante = (evaluacion['estudiante'] ?? 'SIN NOMBRE').toString().toUpperCase();
    final String rubrica = (evaluacion['nombre'] ?? 'RÚBRICA').toString();
    final double notaFinal = (evaluacion['notaFinal'] ?? 0.0).toDouble();
    final List criterios = evaluacion['criterios'] ?? [];

    String fechaStr = "S/F";
    if (evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy HH:mm').format((evaluacion['fecha'] as Timestamp).toDate());
    } else if (evaluacion['fecha'] != null) {
      fechaStr = evaluacion['fecha'].toString();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ENCABEZADO Y TÍTULO
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1A237E'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "REPORTE DE EVALUACIÓN",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        rubrica.toUpperCase(),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "NOTA FINAL",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1A237E'),
                          ),
                        ),
                        pw.Text(
                          notaFinal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1A237E'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // DATOS DEL ESTUDIANTE Y FECHA
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "ESTUDIANTE: $estudiante",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.Text(
                    "FECHA: $fechaStr",
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              "DESGLOSE DE RESULTADOS",
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A237E'),
              ),
            ),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#1A237E')),
            pw.SizedBox(height: 10),

            // LISTADO DE CRITERIOS
            ...criterios.asMap().entries.map((entry) {
              int idx = entry.key;
              var c = entry.value;

              final String nombreCriterio = (c['nombre'] ?? 'Criterio').toString().toUpperCase();
              final double porcentaje = (c['porcentaje'] ?? 0.0).toDouble();
              final Map<String, dynamic>? nivelSeleccionado = c['nivel_seleccionado'];

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            "CRITERIO ${idx + 1}: $nombreCriterio",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: PdfColor.fromHex('#1A237E'),
                            ),
                          ),
                        ),
                        if (porcentaje > 0)
                          pw.Text(
                            "Ponderación: $porcentaje%",
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.SizedBox(height: 6),

                    if (nivelSeleccionado != null) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            (nivelSeleccionado['nivel_nombre'] ?? 'NIVEL SELECCIONADO').toString().toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColor.fromHex('#00796B'),
                            ),
                          ),
                          if (nivelSeleccionado.containsKey('puntos'))
                            pw.Text(
                              "Puntos: ${nivelSeleccionado['puntos']}",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColor.fromHex('#00796B'),
                              ),
                            ),
                        ],
                      ),
                      if ((nivelSeleccionado['texto'] ?? nivelSeleccionado['descripcion'] ?? '').toString().isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          nivelSeleccionado['texto'] ?? nivelSeleccionado['descripcion'] ?? '',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#E8F5E9'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "VALOR DESCRIPTOR:",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                                color: PdfColor.fromHex('#2E7D32'),
                              ),
                            ),
                            pw.Text(
                              ((nivelSeleccionado['valor_descriptor'] ?? 0.0) as num).toStringAsFixed(2),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColor.fromHex('#2E7D32'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      pw.Text(
                        "Sin nivel seleccionado.",
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
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
      name: 'Evaluacion_$estudiante.pdf',
    );
  }
}