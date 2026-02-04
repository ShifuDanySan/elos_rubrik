import 'package:flutter/material.dart';

class AddAnaliticoScreen extends StatefulWidget {
  final int analiticoIndex;

  const AddAnaliticoScreen({
    super.key,
    required this.analiticoIndex,
  });

  @override
  State<AddAnaliticoScreen> createState() => _AddAnaliticoScreenState();
}

class _AddAnaliticoScreenState extends State<AddAnaliticoScreen> {
  // Colores consistentes con tu diseño
  static const Color primaryColor = Color(0xFF00796B);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFE0F2F1);

  final TextEditingController _descripcionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Este valor es el "Grado" o "Peso" que definirá el impacto del analítico
  double _pesoAnalitico = 0.50;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardarAnaliticoYVolver() {
    if (_formKey.currentState!.validate()) {
      // Devolvemos el objeto con la llave 'descripcion' y 'peso'
      // Esto es vital para que EjecutarEvaluacion lo reconozca
      Navigator.pop(context, {
        'descripcion': _descripcionController.text.trim(),
        'peso': double.parse(_pesoAnalitico.toStringAsFixed(2)),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Configurar Analítico ${widget.analiticoIndex}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción del Analítico',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _descripcionController,
                          autofocus: true, // El cursor aparece aquí automáticamente
                          decoration: InputDecoration(
                            labelText: 'Ej: Capacidad de síntesis',
                            hintText: 'Ingrese qué se evaluará aquí',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.edit, color: primaryColor),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Peso del analítico:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _pesoAnalitico.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                        Slider(
                          value: _pesoAnalitico,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: accentColor,
                          onChanged: (val) => setState(() => _pesoAnalitico = val),
                        ),
                        const Text(
                          'Desliza para asignar la importancia de este punto.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _guardarAnaliticoYVolver,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('CONFIRMAR ANALÍTICO', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}