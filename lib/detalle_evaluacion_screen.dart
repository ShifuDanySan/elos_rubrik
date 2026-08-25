import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_service.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';
import 'dart:math' as math;

const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);
const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

class DetalleEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> evaluacion;
  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  @override
  State<DetalleEvaluacionScreen> createState() => _DetalleEvaluacionScreenState();
}

class _DetalleEvaluacionScreenState extends State<DetalleEvaluacionScreen> {
  final GlobalKey _keyPuntajeTotal = GlobalKey();
  final GlobalKey _keyTablaResumen = GlobalKey();
  final GlobalKey _keyListaDesglosada = GlobalKey();
  final GlobalKey _keyBtnPdf = GlobalKey();
  final GlobalKey _keyBtnInfo = GlobalKey();

  Future<void> _abrirManualPdf() async {
    final Uri uri = Uri.parse(_pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el manual de usuario.')),
        );
      }
    }
  }

  void _showTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'DETALLE_EVALUACION',
      keys: {
        'puntaje_total': _keyPuntajeTotal,
        'tabla_resumen': _keyTablaResumen,
        'lista_desglosada': _keyListaDesglosada,
        'btn_pdf': _keyBtnPdf,
        'btn_compartir': _keyBtnInfo,
      },
      force: force,
    );
  }

  void _mostrarExplicacionLCD() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: _primaryColor),
            SizedBox(width: 10),
            Text(
              "Lógica de Evaluación",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryColor),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Este reporte detalla los criterios evaluados, la ponderación aplicada y el nivel de desempeño seleccionado.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
              SizedBox(height: 20),
              _ItemInfo(
                icon: Icons.analytics_outlined,
                titulo: "Ponderación y Puntos",
                desc: "El valor del descriptor resulta de multiplicar los puntos alcanzados en el nivel por la ponderación asignada al criterio.",
              ),
              _ItemInfo(
                icon: Icons.check_circle_outline,
                titulo: "Nivel Seleccionado",
                desc: "Cada criterio muestra únicamente el nivel seleccionado con su descripción y calificación.",
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

  @override
  Widget build(BuildContext context) {
    final List criterios = widget.evaluacion['criterios'] ?? [];
    final String estudiante = widget.evaluacion['estudiante'] ?? 'Sin nombre';
    final double notaFinal = (widget.evaluacion['notaFinal'] ?? 0.0).toDouble();

    String fechaStr = "S/F";
    if (widget.evaluacion['fecha'] is Timestamp) {
      fechaStr = DateFormat('dd/MM/yyyy').format((widget.evaluacion['fecha'] as Timestamp).toDate());
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isMobile ? kToolbarHeight : 80,
        title: isMobile
            ? null
            : const Text(
          "Detalle de Evaluación",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
              tooltip: 'Manual de usuario',
              onPressed: _abrirManualPdf,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                ),
                onPressed: _abrirManualPdf,
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: const Text(
                  'MANUAL DE USUARIO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          IconButton(key: _keyBtnInfo, icon: const Icon(Icons.info_outline), onPressed: _mostrarExplicacionLCD),
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
          Column(
            children: [
              if (isMobile)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "DETALLE DE EVALUACIÓN",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(estudiante, widget.evaluacion['nombre'] ?? 'Rúbrica', fechaStr, notaFinal),
                      const SizedBox(height: 25),
                      Container(
                        key: _keyTablaResumen,
                        child: Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: _primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "DESGLOSE DE RESULTADOS",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _primaryColor.withOpacity(0.8),
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(thickness: 2, color: _primaryColor),
                      const SizedBox(height: 10),
                      ...criterios.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var c = entry.value;
                        return _buildCriterioTile(c, idx == 0 ? _keyListaDesglosada : null, idx + 1);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String alumno, String rubrica, String fecha, double nota) {
    return Container(
      key: _keyPuntajeTotal,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
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
                  Text(alumno.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _primaryColor)),
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

  Widget _buildCriterioTile(Map<String, dynamic> criterio, GlobalKey? key, int numeroCriterio) {
    final double porcentaje = (criterio['porcentaje'] ?? 0.0).toDouble();
    final Map<String, dynamic>? nivelSeleccionado = criterio['nivel_seleccionado'];
    final bool esDifusa = widget.evaluacion['esDifusa'] ?? false;

    final List descriptores = criterio['descriptores'] ?? (nivelSeleccionado != null ? [nivelSeleccionado] : []);

    String tituloNivel = "NIVEL SELECCIONADO";
    if (esDifusa) {
      tituloNivel = "NIVEL DE LOGRO ALCANZADO EN EL DESARROLLO DE LA COMPETENCIA (GRADO EN EL QUE SE ALCANZÓ LA COMPETENCIA)";
    } else if (nivelSeleccionado != null) {
      tituloNivel = (nivelSeleccionado['nivel_nombre'] ?? 'NIVEL SELECCIONADO').toString().toUpperCase();
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
        title: Text(
          "CRITERIO $numeroCriterio: ${(criterio['nombre'] ?? 'Criterio').toString().toUpperCase()}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 15),
        ),
        subtitle: porcentaje > 0
            ? Text("Ponderación: $porcentaje%", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
            : null,
        children: [
          if (nivelSeleccionado != null) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              color: _backgroundColor.withOpacity(0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.star, size: 18, color: Color(0xFF00796B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tituloNivel,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (nivelSeleccionado.containsKey('puntos'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00796B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Puntos: ${nivelSeleccionado['puntos']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00796B), fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if ((nivelSeleccionado['texto'] ?? nivelSeleccionado['descripcion'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      nivelSeleccionado['texto'] ?? nivelSeleccionado['descripcion'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "VALOR DESCRIPTOR:",
                          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          ((nivelSeleccionado['valor_descriptor'] ?? 0.0) as num).toStringAsFixed(2),
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (descriptores.isNotEmpty) ...[
            ...descriptores.map((desc) {
              final double valorDescriptor = ((desc['valor_descriptor'] ?? desc['resultado_descriptor'] ?? 0.0) as num).toDouble();
              final String texto = desc['texto'] ?? desc['descripcion'] ?? desc['contexto'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                color: _backgroundColor.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: _accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  desc['nivel_nombre'] ?? desc['contexto'] ?? 'Descriptor',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            valorDescriptor.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    if (texto.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(texto, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                    if (desc != descriptores.last) const Divider(height: 20),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String desc;

  const _ItemInfo({
    required this.icon,
    required this.titulo,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
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