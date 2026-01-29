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
  // Constantes de color (Mismo esquema que las pantallas anteriores)
  static const Color primaryColor = Color(0xFF00796B); // Teal oscuro
  static const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFEF5350); // Rojo Error
  static const Color backgroundColor = Color(0xFFE0F2F1); // Azul Verdoso muy pálido (Teal 50)

  // Inicialización de forma segura
  final TextEditingController _descripcionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double _gradoPertenencia = 0.50;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _onGradoPertenenciaChanged(double value) {
    setState(() {
      _gradoPertenencia = double.parse(value.toStringAsFixed(2));
    });
  }

  void _guardarAnaliticoYVolver() {
    if (_formKey.currentState!.validate()) {
      // Leer valores del controller antes del pop para evitar "disposed" error
      final String descripcion = _descripcionController.text.trim();
      final double gradoPertenencia = _gradoPertenencia;

      final Map<String, dynamic> nuevoAnalitico = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'descripcion': descripcion,
        'gradoPertenencia': gradoPertenencia,
        'index': widget.analiticoIndex,
      };

      // Llamar a pop inmediatamente
      Navigator.of(context).pop(nuevoAnalitico);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 Habilitar responsividad: detecta si es una pantalla pequeña
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: backgroundColor, // Fondo Azul Verdoso Suave
      appBar: AppBar(
        title: Text('Añadir Analítico ${widget.analiticoIndex}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor, // AppBar Teal Oscuro
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          // 🚨 Ajuste de padding y margin para hacerlo responsive
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
            // 🚨 Usar ListView para evitar overflows en pantallas pequeñas/teclado
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Define la descripción y el grado de pertenencia (peso) del Analítico ${widget.analiticoIndex}.',
                  style: const TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // 1. Descripción
                TextFormField(
                  controller: _descripcionController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Descripción del Analítico',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.rate_review, color: primaryColor),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'La descripción es obligatoria.';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // 2. Grado de Pertenencia (Slider)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grado de Pertenencia: ${_gradoPertenencia.toStringAsFixed(2)} / 1.00',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                      ),
                      Slider(
                        value: _gradoPertenencia,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: _gradoPertenencia.toStringAsFixed(2),
                        activeColor: accentColor, // Usamos verde para el peso
                        inactiveColor: accentColor.withOpacity(0.3),
                        onChanged: _onGradoPertenenciaChanged,
                      ),
                      const Text(
                        'Nota: El valor representa el peso o la importancia del Analítico dentro de la fórmula del Descriptor.',
                        style: TextStyle(fontSize: 12, color: warningColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 3. Botón Guardar
                ElevatedButton.icon(
                  onPressed: _guardarAnaliticoYVolver,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Analítico y Volver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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