// lista_evaluaciones_screen.dart (Versión con Filtro por Fecha)
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
  DateTime? _fechaFiltro; // Almacena la fecha seleccionada por el usuario

  // ----------------------------------------------------
  // 1. Lógica de Carga de Evaluaciones (Firestore)
  // ----------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchEvaluacionesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(__app_id)
        .collection('users')
        .doc(userId)
        .collection('evaluaciones');

    // FILTRO POR FECHA: Si hay una fecha seleccionada, filtramos el rango del día
    if (_fechaFiltro != null) {
      DateTime inicioDia = DateTime(_fechaFiltro!.year, _fechaFiltro!.month, _fechaFiltro!.day);
      DateTime finDia = inicioDia.add(const Duration(days: 1));

      query = query
          .where('fechaEvaluacion', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fechaEvaluacion', isLessThan: Timestamp.fromDate(finDia));
    }

    return query.orderBy('fechaEvaluacion', descending: true).snapshots();
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
      setState(() {
        _fechaFiltro = seleccionado;
      });
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaFiltro = null;
    });
  }

  // ----------------------------------------------------
  // 3. Navegación al Detalle
  // ----------------------------------------------------
  void _verDetalleEvaluacion(BuildContext context, Map<String, dynamic> evaluacion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEvaluacionScreen(evaluacionData: evaluacion),
      ),
    );
  }

  // ----------------------------------------------------
  // 4. Widget Auxiliar de Estilo
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
                  return Center(
                    child: Text(
                      'Error al cargar las evaluaciones: ${snapshot.error}',
                      style: const TextStyle(color: errorColor),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final evaluacionesDocs = snapshot.data?.docs;

                if (evaluacionesDocs == null || evaluacionesDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _fechaFiltro == null
                                ? 'Aún no hay evaluaciones guardadas.'
                                : 'No hay evaluaciones para esta fecha.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: evaluacionesDocs.length,
                  itemBuilder: (context, index) {
                    final evaluacionDoc = evaluacionesDocs[index];
                    final evaluacionData = evaluacionDoc.data();

                    final double notaFinal = evaluacionData['notaFinal'] as double? ?? 0.0;
                    final notaColor = _getNotaColor(notaFinal);

                    final fecha = (evaluacionData['fechaEvaluacion'] as Timestamp?)?.toDate();
                    final fechaStr = fecha != null
                        ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                        : 'Fecha desconocida';

                    final Map<String, dynamic> fullEvaluacionData = {
                      ...evaluacionData,
                      'docId': evaluacionDoc.id,
                      'fecha': fechaStr,
                    };

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: notaColor,
                          child: Text(
                            notaFinal.toStringAsFixed(2),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        title: Text(
                          evaluacionData['estudiante'] ?? 'Estudiante desconocido',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Rúbrica: ${evaluacionData['nombreRubrica'] ?? 'Sin nombre'}\nFecha: $fechaStr',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right, color: primaryColor, size: 24),
                        onTap: () => _verDetalleEvaluacion(context, fullEvaluacionData),
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