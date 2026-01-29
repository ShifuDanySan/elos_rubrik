// add_operador_screen.dart
import 'package:flutter/material.dart';

class AddOperadorScreen extends StatefulWidget {
  const AddOperadorScreen({super.key});

  @override
  State<AddOperadorScreen> createState() => _AddOperadorScreenState();
}

class _AddOperadorScreenState extends State<AddOperadorScreen> {
  // Controladores y claves de estado
  final TextEditingController _nombreOperadorController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double _pesoOperador = 0.50; // Peso inicial

  @override
  void dispose() {
    _nombreOperadorController.dispose();
    super.dispose();
  }

  // Manejador del cambio de peso en el slider
  void _onPesoChanged(double value) {
    setState(() {
      // Asegura que el valor se mantenga con dos decimales
      _pesoOperador = double.parse(value.toStringAsFixed(2));
    });
  }

  // Función para guardar el operador y volver a la pantalla anterior
  void _guardarOperadorYVolver() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> nuevoOperador = {
        'nombre': _nombreOperadorController.text.trim(),
        'pesoOperador': _pesoOperador,
      };

      // Devolver el operador como resultado a AddCriterioScreen o AddDescriptorScreen
      Navigator.of(context).pop(nuevoOperador);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Operador Lógico'),
        // Usamos un color distintivo y consistente
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Permite desplazamiento si el teclado aparece
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Campo de texto para el Nombre del Operador
              TextFormField(
                controller: _nombreOperadorController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Operador (e.g., AND, OR, AVG)',
                  hintText: 'Ejemplo: AND (Media Aritmética)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.merge_type, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingrese el nombre del operador.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // 2. Slider para el Peso del Operador
              Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peso del Operador: ${_pesoOperador.toStringAsFixed(2)} / 1.00',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Slider(
                      value: _pesoOperador,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: _pesoOperador.toStringAsFixed(2),
                      activeColor: Colors.blue,
                      inactiveColor: Colors.blue.withOpacity(0.3),
                      onChanged: _onPesoChanged,
                    ),
                    const Text(
                      'Nota: El peso del operador define su influencia en la evaluación del criterio.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Botón de Guardar
              ElevatedButton.icon(
                onPressed: _guardarOperadorYVolver,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Operador y Volver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}