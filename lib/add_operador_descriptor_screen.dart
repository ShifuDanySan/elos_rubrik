import 'package:flutter/material.dart';
import 'auth_helper.dart';

class AddOperadorDescriptorScreen extends StatefulWidget {
  const AddOperadorDescriptorScreen({super.key});

  @override
  State<AddOperadorDescriptorScreen> createState() => _AddOperadorDescriptorScreenState();
}

class _AddOperadorDescriptorScreenState extends State<AddOperadorDescriptorScreen> {
  // Constantes de color (Mismo esquema que las pantallas anteriores)
  static const Color primaryColor = Color(0xFF00796B); // Teal oscuro
  static const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFEF5350); // Rojo Error
  static const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 🛑 Eliminado: double _pesoOperador = 0.50;

  // Valores predefinidos: solo AND y OR.
  final List<String> _operadoresDisponibles = ['AND', 'OR'];
  String? _operadorSeleccionado;

  @override
  void initState() {
    super.initState();
    _operadorSeleccionado = _operadoresDisponibles.first;
  }

  // 🛑 Eliminado: void _onPesoChanged(double value) {...}
  // 🛑 Eliminado: dispose() solo llama a super.dispose()

  void _onOperadorChanged(String? newValue) {
    setState(() {
      _operadorSeleccionado = newValue;
    });
  }

  void _guardarOperadorYVolver() {
    if (_formKey.currentState!.validate() && _operadorSeleccionado != null) {
      final Map<String, dynamic> nuevoOperador = {
        // 🛑 Solo devolvemos el nombre del operador
        'nombre': _operadorSeleccionado,
        // 🛑 Eliminado: 'pesoOperador': _pesoOperador,
      };

      // Devolver el operador a AddDescriptorScreen
      Navigator.of(context).pop(nuevoOperador);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Añadir Operador Lógico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        actions: [
          AuthHelper.logoutButton(context), // <--- AGREGAR EL BOTÓN AQUÍ
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          margin: EdgeInsets.all(isSmallScreen ? 8.0 : 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Seleccione el operador lógico para conectar los dos Criterios Analíticos (CA1 y CA2) de este Descriptor:',
                  style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // 1. Selector de Operador (Dropdown)
                DropdownButtonFormField<String>(
                  value: _operadorSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Seleccione Operador',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.call_split, color: primaryColor),
                  ),
                  items: _operadoresDisponibles.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: _onOperadorChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El operador es obligatorio.';
                    return null;
                  },
                ),

                // 🛑 Eliminado: Sección del peso del operador (Container y Slider)

                const SizedBox(height: 40),

                // Botón de Guardar
                ElevatedButton.icon(
                  onPressed: _guardarOperadorYVolver,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Operador y Volver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
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