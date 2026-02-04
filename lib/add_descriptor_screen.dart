import 'package:flutter/material.dart';
import 'add_analitico_screen.dart';

class AddDescriptorScreen extends StatefulWidget {
  final String nombreCriterio;
  const AddDescriptorScreen({super.key, required this.nombreCriterio});

  @override
  State<AddDescriptorScreen> createState() => _AddDescriptorScreenState();
}

class _AddDescriptorScreenState extends State<AddDescriptorScreen> {
  final TextEditingController _contextoController = TextEditingController();
  Map<String, dynamic>? _a1;
  Map<String, dynamic>? _a2;
  String _operador = "AND";

  void _guardar() {
    if (_contextoController.text.isEmpty || _a1 == null) return;

    // IMPORTANTE: Creamos la lista 'analiticos' explícitamente
    List<Map<String, dynamic>> listaParaFirebase = [];
    listaParaFirebase.add(_a1!);
    if (_a2 != null) listaParaFirebase.add(_a2!);

    Navigator.pop(context, {
      'contexto': _contextoController.text.trim(),
      'operador': _operador,
      'analiticos': listaParaFirebase, // El evaluador buscará esta llave
      'peso': 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Descriptor')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _contextoController,
            autofocus: true, // Cursor al inicio
            decoration: const InputDecoration(labelText: 'Contexto/Descripción'),
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.white,
            title: Text(_a1 == null ? "Añadir Analítico 1" : "A1: ${_a1!['descripcion']}"),
            trailing: const Icon(Icons.add_circle),
            onTap: () async {
              var res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnaliticoScreen(analiticoIndex: 1)));
              if (res != null) setState(() => _a1 = res);
            },
          ),
          DropdownButton<String>(
            value: _operador,
            isExpanded: true,
            items: ["AND", "OR"].map((e) => DropdownMenuItem(value: e, child: Text("Operador: $e"))).toList(),
            onChanged: (v) => setState(() => _operador = v!),
          ),
          ListTile(
            tileColor: Colors.white,
            title: Text(_a2 == null ? "Añadir Analítico 2 (Opcional)" : "A2: ${_a2!['descripcion']}"),
            trailing: const Icon(Icons.add_circle),
            onTap: () async {
              var res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnaliticoScreen(analiticoIndex: 2)));
              if (res != null) setState(() => _a2 = res);
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _guardar, child: const Text("GUARDAR DESCRIPTOR")),
        ],
      ),
    );
  }
}