// lista_evaluaciones_screen.dart (Versión Corregida con Filtro Funcional)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detalle_evaluacion_screen.dart';
import 'auth_helper.dart';

// ===============================================
// CONSTANTES DE ENTORNO Y ESTILO
// ===============================================
const String __app_id = 'rubrica_evaluator';

const Color primaryColor = Color(0xFF00796B);
const Color accentColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFEF5350);
const Color warningColor = Color(0xFFFF9800);

class ListaEvaluacionesScreen extends StatefulWidget {
  const ListaEvaluacionesScreen({super.key});

  @override
  State<ListaEvaluacionesScreen> createState() => _ListaEvaluacionesScreenState();
}

class _ListaEvaluacionesScreenState extends State<ListaEvaluacionesScreen> {
  DateTime? _fechaFiltro;

  // ----------------------------------------------------
  // 1. Lógica de Carga de Evaluaciones (Firestore)
  // ----------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchEvaluacionesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    // Referencia corregida a tu estructura de Firebase
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(__app_id)
        .collection('users')
        .doc(userId)
        .collection('evaluaciones');

    // FILTRO POR FECHA: Usamos el campo 'fecha' que es el que genera serverTimestamp
    if (_fechaFiltro != null) {
      DateTime inicioDia = DateTime(_fechaFiltro!.year, _fechaFiltro!.month, _fechaFiltro!.day);
      DateTime finDia = inicioDia.add(const Duration(days: 1));

      query = query
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fecha', isLessThan: Timestamp.fromDate(finDia));
    }

    return query.orderBy('fecha', descending: true).snapshots();
  }

  // ----------------------------------------------------
  // 2. Selector de Fecha (Date Picker)
  // ----------------------------------------------------
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (seleccionado != null) {
      setState(() => _fechaFiltro = seleccionado);
    }
  }

  void _limpiarFiltro() {
    setState(() => _fechaFiltro = null);
  }

  // ----------------------------------------------------
  // 3. Navegación al Detalle
  // ----------------------------------------------------
  void _verDetalleEvaluacion(BuildContext context, Map<String, dynamic> evaluacion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEvaluacionScreen(evaluacion: evaluacion),
      ),
    );
  }

  // ----------------------------------------------------
  // 4. Funciones de Estilo
  // ----------------------------------------------------
  Color _getNotaColor(double nota) {
    if (nota >= 0.9) return accentColor;
    if (nota >= 0.7) return primaryColor;
    if (nota >= 0.5) return warningColor;
    return errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Evaluaciones'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          // PANEL DE FILTROS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _seleccionarFecha(context),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _fechaFiltro == null
                          ? 'FILTRAR POR FECHA'
                          : '${_fechaFiltro!.day}/${_fechaFiltro!.month}/${_fechaFiltro!.year}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _fechaFiltro == null ? Colors.white : primaryColor,
                      foregroundColor: _fechaFiltro == null ? primaryColor : Colors.white,
                    ),
                  ),
                ),
                if (_fechaFiltro != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _limpiarFiltro,
                    icon: const Icon(Icons.clear_all, color: errorColor),
                    tooltip: 'Mostrar todas',
                  ),
                ],
              ],
            ),
          ),

          // LISTADO (STREAM BUILDER)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _fetchEvaluacionesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: errorColor)));
                }

                final evaluacionesDocs = snapshot.data?.docs ?? [];

                if (evaluacionesDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _fechaFiltro == null ? 'No hay evaluaciones.' : 'No hay datos para esta fecha.',
                          style: const TextStyle(fontSize: 18, color: primaryColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: evaluacionesDocs.length,
                  itemBuilder: (context, index) {
                    final evaluacionDoc = evaluacionesDocs[index];
                    final evaluacionData = evaluacionDoc.data();

                    final double notaFinal = (evaluacionData['notaFinal'] ?? 0.0).toDouble();
                    final notaColor = _getNotaColor(notaFinal);

                    // Usamos el campo 'fecha' de Firestore
                    final Timestamp? timestamp = evaluacionData['fecha'] as Timestamp?;
                    final DateTime? fecha = timestamp?.toDate();
                    final String fechaStr = fecha != null
                        ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                        : 'Sin fecha';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notaColor,
                          child: Text(notaFinal.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(evaluacionData['estudiante'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Rúbrica: ${evaluacionData['nombreRubrica'] ?? 'S/N'}\n$fechaStr'),
                        trailing: const Icon(Icons.chevron_right, color: primaryColor),
                        onTap: () => _verDetalleEvaluacion(context, evaluacionData),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}