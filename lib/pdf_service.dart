import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfService {
  // Colores idénticos a la interfaz de usuario
  static final azulOscuro = PdfColor.fromInt(0xFF1A237E);
  static final fondoMoradoClaro = PdfColor.fromInt(0xFFF8F4FF);
  static final grisTexto = PdfColors.grey700;

  /// Crea la estructura visual del PDF imitando la App
  static Future<pw.Document> _crearEstructuraPdf(Map<String, dynamic> evaluacion) async {
    final pdf = pw.Document();
    final String estudiante = evaluacion['estudiante'] ?? "Estudiante";
    final String notaFinal = evaluacion['notaFinal']?.toString() ?? "0.00";
    final List<dynamic> criterios = evaluacion['criterios'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // CABECERA DE CALIFICACIÓN (Caja morada superior)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 30),
            decoration: pw.BoxDecoration(
              color: fondoMoradoClaro,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
            ),
            child: pw.Column(
              children: [
                pw.Text("CALIFICACIÓN FINAL",
                    style: pw.TextStyle(color: grisTexto, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
                pw.SizedBox(height: 10),
                pw.Text(notaFinal,
                    style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold, color: azulOscuro)),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // INFORMACIÓN DEL ESTUDIANTE
          pw.Text("ESTUDIANTE: ${estudiante.toUpperCase()}",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: azulOscuro)),
          pw.SizedBox(height: 5),
          pw.Divider(color: PdfColors.grey300, thickness: 1),
          pw.SizedBox(height: 20),

          pw.Text("ANÁLISIS DE DESEMPEÑO POR CRITERIO",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: grisTexto)),
          pw.SizedBox(height: 15),

          // LISTA DE TARJETAS DE CRITERIOS
          ...criterios.asMap().entries.map((entry) {
            int index = entry.key + 1;
            var crit = entry.value;
            final List<dynamic> descriptores = crit['descriptores'] ?? [];
            double valor = descriptores.fold(0.0, (p, d) => p + (d['resultado_descriptor'] ?? 0.0)).clamp(0.0, 1.0);

            // Lógica de colores de desempeño
            PdfColor colorEstado = valor >= 0.8 ? PdfColors.green700 : (valor >= 0.4 ? PdfColors.orange700 : PdfColors.red700);
            String textoEstado = valor >= 0.8 ? "Desempeño excelente" : (valor >= 0.4 ? "Buen desempeño" : "Alerta de desempeño");

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: fondoMoradoClaro,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("CRITERIO $index: ${crit['nombre']}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
                  pw.SizedBox(height: 6),
                  pw.Text(textoEstado,
                      style: pw.TextStyle(color: colorEstado, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                  pw.SizedBox(height: 5),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("Puntaje: ${valor.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: azulOscuro, fontSize: 13)),
                  ),
                ],
              ),
            );
          }).toList(),

          // PIE DE PÁGINA
          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text("Generado por Elos-Rubrik App",
                style: pw.TextStyle(color: PdfColors.grey400, fontSize: 9, fontStyle: pw.FontStyle.italic)),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// Genera los bytes del PDF para Chrome (Web)
  static Future<Uint8List> obtenerBytesPdf(Map<String, dynamic> evaluacion) async {
    final pdf = await _crearEstructuraPdf(evaluacion);
    return await pdf.save();
  }

  /// Genera archivo físico para Android
  static Future<File?> generarArchivoPdf(Map<String, dynamic> evaluacion) async {
    if (kIsWeb) return null;
    final pdf = await _crearEstructuraPdf(evaluacion);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Informe_${evaluacion['estudiante']}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Dispara la previsualización o impresión directa
  static Future<void> generarReporte(Map<String, dynamic> evaluacion) async {
    final pdfBytes = await obtenerBytesPdf(evaluacion);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Informe_${evaluacion['estudiante']}',
    );
  }
}