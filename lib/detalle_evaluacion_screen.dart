import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf_service.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';
import 'dart:math' as math;

const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);

class DetalleEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> evaluacion;
  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  @override
  State<DetalleEvaluacionScreen> createState() => _DetalleEvaluacionScreenState();
}

class _DetalleEvaluacionScreenState extends State<DetalleEvaluacionScreen> {
  final GlobalKey _keyCardNota = GlobalKey();
  final GlobalKey _keyBtnPdf = GlobalKey();
  final GlobalKey _keyDesgloseCriterio = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  void _showTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'DETALLE_EVALUACION',
      keys: {
        'card_nota': _keyCardNota,
        'btn_pdf': _keyBtnPdf,
        'desglose_criterio': _keyDesgloseCriterio,
      },
      force: force,
    );
  }

  // DIÁLOGO TÉCNICO PROFESIONAL
  void _mostrarExplicacionLCD() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.psychology, color: _primaryColor),
            SizedBox(width: 10),
            Text("Lógica de Evaluación", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Este reporte utiliza Lógica Compensatoria Difusa (LCD) para garantizar una calificación justa y pedagógica.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _itemInfo(
                  Icons.analytics_outlined,
                  "Analíticos y Grados de Verdad",
                  "Cada evidencia marcada alimenta un predicado lógico. No es un 'sí/no' rígido, sino una acumulación de evidencias de aprendizaje."
              ),
              _itemInfo(
                  Icons.balance,
                  "Principio de Compensación",
                  "El modelo permite que fortalezas demostradas compensen debilidades menores, reflejando el aprendizaje como un proceso no lineal."
              ),
              _itemInfo(
                  Icons.functions,
                  "Suma Positiva",
                  "Cuando el balance de analíticos es favorable, el sistema valida matemáticamente el nivel de desempeño como 'Verdadero'."
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _itemInfo(IconData icon, String titulo, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primaryColor)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List criterios = widget.evaluacion['criterios'] ?? [];
    final String estudiante = widget.evaluacion['estudiante'] ?? 'Sin nombre';
    final double notaFinal = (widget.evaluacion['notaFinal'] ?? 0.0).toDouble();

    String fechaStr = "S/F";
    if (widget.evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy').format((widget.evaluacion['fecha'] as Timestamp).toDate());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Evaluación", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarExplicacionLCD,
            tooltip: "Ver lógica de cálculo",
          ),
          TutorialHelper.helpButton(context, () => _showTutorial(force: true)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
            child: ElevatedButton.icon(
              key: _keyBtnPdf,
              onPressed: () => PdfService.generarReporteEvaluacion(widget.evaluacion),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text("PDF", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Stack(
        children: [
          const _StaticFloatingBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(estudiante, widget.evaluacion['nombre'] ?? 'Rúbrica', fechaStr, notaFinal),
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "DESGLOSE DE RESULTADOS",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _primaryColor.withOpacity(0.8),
                          fontSize: 13,
                          letterSpacing: 1.2
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 2, color: _primaryColor),
                const SizedBox(height: 10),
                ...criterios.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var c = entry.value;
                  return _buildCriterioTile(c, idx == 0 ? _keyDesgloseCriterio : null);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String alumno, String rubrica, String fecha, double nota) {
    return Container(
      key: _keyCardNota,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alumno.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _primaryColor)),
                  const SizedBox(height: 5),
                  Text(rubrica, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                  Text("Fecha: $fecha", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: _accentColor, width: 3),
              ),
              child: Text(
                nota.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriterioTile(Map<String, dynamic> criterio, GlobalKey? key) {
    final List descriptores = criterio['descriptores'] ?? [];
    double notaCriterio = 0.0;
    for (var d in descriptores) {
      notaCriterio += (d['resultado_descriptor'] ?? 0.0).toDouble();
    }

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        iconColor: _primaryColor,
        title: Text(criterio['nombre'] ?? 'Criterio',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 16)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            notaCriterio.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w900, color: _primaryColor),
          ),
        ),
        children: descriptores.map((desc) {
          final List analiticos = desc['analiticos'] ?? [];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            color: _backgroundColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 16, color: _accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(desc['contexto'] ?? 'Descriptor',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...analiticos.map((ana) => Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 14, color: _primaryColor),
                      Expanded(child: Text(ana['nombre'], style: const TextStyle(fontSize: 13))),
                      Text("${(ana['valor_asignado'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryColor)),
                    ],
                  ),
                )).toList(),
                if (desc != descriptores.last) const Divider(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StaticFloatingBackground extends StatelessWidget {
  const _StaticFloatingBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: Stack(
        children: List.generate(15, (i) {
          final random = math.Random(i);
          return Positioned(
            top: random.nextDouble() * 800,
            left: random.nextDouble() * 400,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 50 + random.nextDouble() * 100,
                height: 50 + random.nextDouble() * 100,
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? _primaryColor : _accentColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}