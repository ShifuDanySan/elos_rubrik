// editar_rubrica_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';

class EditarRubricaScreen extends StatefulWidget {
  final String rubricaId;
  final String nombreInicial;

  const EditarRubricaScreen({super.key, required this.rubricaId, required this.nombreInicial});

  @override
  State<EditarRubricaScreen> createState() => _EditarRubricaScreenState();
}

class _EditarRubricaScreenState extends State<EditarRubricaScreen> {
  final String __app_id = 'rubrica_evaluator';
  final Color headerColor = const Color(0xFF283593);
  final Color primaryColor = const Color(0xFF00796B);

  double sumaCriteriosActual = 0.0;
  List<dynamic> listaCriteriosCache = [];

  // Función corregida para evitar errores de precisión decimal (evita el 1.01 fantasma)
  double _calcularSumaPesos(List elementos) {
    double sumaTotal = elementos.fold(0.0, (sum, item) => sum + (double.tryParse(item['peso'].toString()) ?? 0.0));
    return double.parse(sumaTotal.toStringAsFixed(2));
  }

  // --- VALIDACIÓN INTEGRAL ---
  Future<bool> _validarEstructuraCompleta() async {
    if (sumaCriteriosActual < 0.99 || sumaCriteriosActual > 1.01) {
      _mostrarAlertaIncompleta("La suma de los Criterios debe ser 1.00 (Actual: $sumaCriteriosActual)");
      return false;
    }

    for (var crit in listaCriteriosCache) {
      List descs = crit['descriptores'] ?? [];
      if (descs.isEmpty) {
        _mostrarAlertaIncompleta("El criterio '${crit['nombre']}' no tiene descriptores.");
        return false;
      }

      double sumaD = _calcularSumaPesos(descs);
      if (sumaD < 0.99 || sumaD > 1.01) {
        _mostrarAlertaIncompleta("Descriptores de '${crit['nombre']}' deben sumar 1.00 (Actual: $sumaD)");
        return false;
      }

      for (var d in descs) {
        if (d['analitico1']?['nombre']?.toString().trim().isEmpty ?? true) {
          _mostrarAlertaIncompleta("Falta el Analítico 1 en '${d['contexto']}'");
          return false;
        }
        if (d['operador'] != null && (d['analitico2']?['nombre']?.toString().trim().isEmpty ?? true)) {
          _mostrarAlertaIncompleta("Operador '${d['operador']}' activo sin Analítico 2 en '${d['contexto']}'");
          return false;
        }
      }
    }
    return true;
  }

  void _mostrarAlertaIncompleta(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.error_outline, color: Colors.red, size: 40),
        content: Text(mensaje, textAlign: TextAlign.center),
        actions: [Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CORREGIR')))],
      ),
    );
  }

  // --- DIÁLOGOS ---
  void _mostrarDialogoCriterio({Map<String, dynamic>? existente, int? index}) {
    final nombreCtrl = TextEditingController(text: existente?['nombre'] ?? '');
    double peso = double.tryParse(existente?['peso']?.toString() ?? '0.0') ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existente == null ? 'Nuevo Criterio' : 'Editar Criterio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, autofocus: true, decoration: InputDecoration(labelText: 'Nombre del Criterio')),
              SizedBox(height: 20),
              Text("Peso: ${peso.toStringAsFixed(2)}"),
              Slider(
                  value: peso,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100, // Fuerza pasos de 0.01
                  activeColor: primaryColor,
                  onChanged: (v) => setDialogState(() => peso = v)
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR')),
            ElevatedButton(onPressed: () => _guardarCriterio(nombreCtrl.text, peso, index), child: Text('GUARDAR')),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoDescriptor(int critIdx, {Map<String, dynamic>? existente, int? descIdx}) {
    final contextoCtrl = TextEditingController(text: existente?['contexto'] ?? '');
    double peso = double.tryParse(existente?['peso']?.toString() ?? '0.0') ?? 0.0;
    final a1NCtrl = TextEditingController(text: existente?['analitico1']?['nombre'] ?? '');
    double grado1 = double.tryParse(existente?['analitico1']?['grado']?.toString() ?? '0.0') ?? 0.0;
    String? operador = existente?['operador'];
    final a2NCtrl = TextEditingController(text: existente?['analitico2']?['nombre'] ?? '');
    double grado2 = double.tryParse(existente?['analitico2']?['grado']?.toString() ?? '0.0') ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Descriptor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: contextoCtrl, autofocus: true, decoration: InputDecoration(labelText: 'Contexto')),
                SizedBox(height: 10),
                Text("Peso: ${peso.toStringAsFixed(2)}"),
                Slider(value: peso, min: 0, max: 1, divisions: 100, activeColor: primaryColor, onChanged: (v) => setDialogState(() => peso = v)),
                Divider(),
                TextField(controller: a1NCtrl, decoration: InputDecoration(labelText: 'Analítico 1 *')),
                Text("Grado 1: ${grado1.toStringAsFixed(2)}"),
                Slider(value: grado1, min: 0, max: 1, divisions: 100, activeColor: primaryColor, onChanged: (v) => setDialogState(() => grado1 = v)),
                DropdownButtonFormField<String>(
                  value: operador,
                  items: [null, 'AND', 'OR'].map((op) => DropdownMenuItem(value: op, child: Text(op ?? 'Sin Operador'))).toList(),
                  onChanged: (val) => setDialogState(() => operador = val),
                  decoration: InputDecoration(labelText: 'Operador'),
                ),
                if (operador != null) ...[
                  TextField(controller: a2NCtrl, decoration: InputDecoration(labelText: 'Analítico 2 *')),
                  Text("Grado 2: ${grado2.toStringAsFixed(2)}"),
                  Slider(value: grado2, min: 0, max: 1, divisions: 100, activeColor: primaryColor, onChanged: (v) => setDialogState(() => grado2 = v)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                if (a1NCtrl.text.trim().isEmpty) return;
                if (operador != null && a2NCtrl.text.trim().isEmpty) return;
                _guardarDescriptor(critIdx, descIdx, contextoCtrl.text, peso, a1NCtrl.text, grado1, operador, a2NCtrl.text, grado2);
              },
              child: Text('ACEPTAR'),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA FIRESTORE ---
  Future<void> _guardarCriterio(String nombre, double peso, int? index) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final docRef = FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(widget.rubricaId);
    final doc = await docRef.get();
    List criterios = List.from(doc.data()?['criterios'] ?? []);

    // Si es el único, forzamos peso 1.0 para mantener integridad
    double pesoFinal = (index == null && criterios.isEmpty) || (index != null && criterios.length == 1) ? 1.0 : peso;

    final nuevo = {'nombre': nombre, 'peso': pesoFinal, 'descriptores': index != null ? criterios[index]['descriptores'] : []};
    if (index == null) criterios.add(nuevo); else criterios[index] = nuevo;
    await docRef.update({'criterios': criterios});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _guardarDescriptor(int cIdx, int? dIdx, String ctx, double peso, String a1n, double a1g, String? op, String a2n, double a2g) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final docRef = FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(widget.rubricaId);
    final doc = await docRef.get();
    List criterios = List.from(doc.data()?['criterios'] ?? []);
    Map<String, dynamic> crit = Map.from(criterios[cIdx]);
    List descs = List.from(crit['descriptores'] ?? []);

    double pesoFinal = (dIdx == null && descs.isEmpty) || (dIdx != null && descs.length == 1) ? 1.0 : peso;

    final nuevo = {
      'contexto': ctx, 'peso': pesoFinal,
      'analitico1': {'nombre': a1n, 'grado': a1g},
      'operador': op,
      'analitico2': op != null ? {'nombre': a2n, 'grado': a2g} : null
    };
    if (dIdx == null) descs.add(nuevo); else descs[dIdx] = nuevo;
    crit['descriptores'] = descs;
    criterios[cIdx] = crit;
    await docRef.update({'criterios': criterios});
    if (mounted) Navigator.pop(context);
  }

  void _confirmarEliminar(int cIdx, {int? dIdx}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar'),
        content: Text('¿Deseas eliminar este elemento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('NO')),
          TextButton(onPressed: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            final docRef = FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(widget.rubricaId);
            final doc = await docRef.get();
            List criterios = List.from(doc.data()?['criterios'] ?? []);
            if (dIdx == null) criterios.removeAt(cIdx);
            else {
              Map<String, dynamic> crit = Map.from(criterios[cIdx]);
              List descs = List.from(crit['descriptores'] ?? []);
              descs.removeAt(dIdx);
              crit['descriptores'] = descs;
              criterios[cIdx] = crit;
            }
            await docRef.update({'criterios': criterios});
            if (mounted) Navigator.pop(ctx);
          }, child: Text('SÍ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _validarEstructuraCompleta() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: headerColor,
          title: Text('Editando: ${widget.nombreInicial}', style: TextStyle(color: Colors.white, fontSize: 14)),
          leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () async {
            if (await _validarEstructuraCompleta()) Navigator.pop(context);
          }),
          actions: [AuthHelper.logoutButton(context)],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(widget.rubricaId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            listaCriteriosCache = snapshot.data!.data()?['criterios'] ?? [];
            sumaCriteriosActual = _calcularSumaPesos(listaCriteriosCache);
            return Column(
              children: [
                Container(
                  width: double.infinity, padding: EdgeInsets.all(8),
                  color: (sumaCriteriosActual > 0.99 && sumaCriteriosActual < 1.01) ? Colors.green : Colors.orange,
                  child: Text("Suma Criterios: ${sumaCriteriosActual.toStringAsFixed(2)} / 1.0", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: listaCriteriosCache.length,
                    itemBuilder: (context, cIdx) {
                      final c = listaCriteriosCache[cIdx];
                      final List descs = c['descriptores'] ?? [];
                      double sumaD = _calcularSumaPesos(descs);
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 3,
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(c['nombre'], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          subtitle: Text("Peso: ${c['peso'].toStringAsFixed(2)} | Suma Descs: ${sumaD.toStringAsFixed(2)}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: Icon(Icons.edit_note, color: Colors.blueGrey), onPressed: () => _mostrarDialogoCriterio(existente: c, index: cIdx)),
                              IconButton(icon: Icon(Icons.close, color: Colors.red), onPressed: () => _confirmarEliminar(cIdx)),
                            ],
                          ),
                          children: [
                            ...descs.asMap().entries.map((e) {
                              final d = e.value;
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300)
                                ),
                                child: ListTile(
                                  onTap: () => _mostrarDialogoDescriptor(cIdx, existente: d, descIdx: e.key),
                                  title: Text("${d['contexto']} (Peso: ${d['peso'].toStringAsFixed(2)})", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 5,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        _badge(d['analitico1']['nombre'], d['analitico1']['grado'], Colors.blue.shade100, Colors.blue.shade900),
                                        if (d['operador'] != null) ...[
                                          Text(d['operador'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                                          _badge(d['analitico2']['nombre'], d['analitico2']['grado'], Colors.blue.shade100, Colors.blue.shade900),
                                        ],
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                                    onPressed: () => _confirmarEliminar(cIdx, dIdx: e.key),
                                  ),
                                ),
                              );
                            }),
                            ListTile(
                              leading: Icon(Icons.add_circle_outline, color: primaryColor),
                              title: Text("Añadir Descriptor", style: TextStyle(color: primaryColor, fontSize: 13)),
                              onTap: () => _mostrarDialogoDescriptor(cIdx),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogoCriterio(),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text("AÑADIR CRITERIO DE EVALUACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _badge(String nombre, dynamic grado, Color bg, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text("$nombre: ${double.tryParse(grado.toString())?.toStringAsFixed(2)}", style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}