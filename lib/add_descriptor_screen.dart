import 'package:flutter/material.dart';
import 'add_analitico_screen.dart';
import 'add_operador_descriptor_screen.dart';

class AddDescriptorScreen extends StatefulWidget {
  final String nombreCriterio;

  const AddDescriptorScreen({
    super.key,
    required this.nombreCriterio,
  });

  @override
  State<AddDescriptorScreen> createState() => _AddDescriptorScreenState();
}

class _AddDescriptorScreenState extends State<AddDescriptorScreen> {
  final TextEditingController _contextoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Constantes de color (Mismo esquema que las pantallas anteriores)
  static const Color primaryColor = Color(0xFF00796B); // Teal oscuro
  static const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFEF5350); // Rojo Error
  static const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50
  static const Color actionColor = Color(0xFF00ACC1); // Cyan (para acciones de añadir)

  Map<String, dynamic>? _criterioAnalitico1; // Criterio Analítico 1 (Obligatorio)
  Map<String, dynamic>? _operador;
  Map<String, dynamic>? _criterioAnalitico2; // Criterio Analítico 2 (Condicional)
  double _pesoDescriptor = 0.50; // Peso del Descriptor (default)

  @override
  void dispose() {
    _contextoController.dispose();
    super.dispose();
  }

  void _navigateToAddAnalitico(int index) async {
    final Map<String, dynamic>? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAnaliticoScreen(analiticoIndex: index),
      ),
    );

    if (result != null) {
      setState(() {
        if (index == 1) {
          _criterioAnalitico1 = result;
        } else if (index == 2) {
          _criterioAnalitico2 = result;
        }
      });
    }
  }

  void _navigateToAddOperador() async {
    final Map<String, dynamic>? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddOperadorDescriptorScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _operador = result;
      });
    }
  }

  void _onPesoDescriptorChanged(double value) {
    setState(() {
      _pesoDescriptor = double.parse(value.toStringAsFixed(2));
    });
  }

  void _eliminar(int type) {
    setState(() {
      if (type == 1) {
        _criterioAnalitico1 = null;
        // Si se elimina CA1, se debe eliminar el operador y CA2
        _operador = null;
        _criterioAnalitico2 = null;
      } else if (type == 0) {
        _operador = null;
        // Si se elimina el operador, se debe eliminar CA2
        _criterioAnalitico2 = null;
      } else if (type == 2) {
        _criterioAnalitico2 = null;
      }
    });
  }

  void _guardarDescriptorYVolver() {
    if (!_formKey.currentState!.validate()) return;

    // 1. Validar existencia del Contexto y CA1 (mínimo requerido)
    if (_contextoController.text.trim().isEmpty || _criterioAnalitico1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ERROR: Debe proporcionar Contexto y al menos el Criterio Analítico 1.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // 2. REGLA CRUCIAL: Si hay Operador, debe haber Criterio Analítico 2.
    if (_operador != null && _criterioAnalitico2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ERROR: Si se añade un Operador Lógico (AND/OR), es obligatorio añadir el Criterio Analítico 2.'),
          backgroundColor: warningColor,
        ),
      );
      return;
    }

    // 3. (Opcional) Si NO hay operador, CA2 debe ser nulo.
    // Aunque el usuario no debería poder añadirlo por la deshabilitación, validamos por si acaso.
    if (_operador == null && _criterioAnalitico2 != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ADVERTENCIA: Criterio Analítico 2 requiere un Operador. Se eliminará CA2 de este Descriptor.'),
          backgroundColor: warningColor,
        ),
      );
      _criterioAnalitico2 = null;
    }


    final Map<String, dynamic> nuevoDescriptor = {
      'contexto': _contextoController.text.trim(),
      'pesoDescriptor': _pesoDescriptor, // Peso relativo al Criterio (suma debe ser 1.00)
      'analiticos': [
        _criterioAnalitico1,
        if (_criterioAnalitico2 != null) _criterioAnalitico2, // Añadir CA2 solo si existe
      ],
      'operador': _operador, // Puede ser null
    };

    Navigator.of(context).pop(nuevoDescriptor);
  }

  // Widget auxiliar para añadir o mostrar items (omitiendo la implementación para brevedad)
  Widget _buildItemCard({
    required String title,
    required String hintText,
    required IconData icon,
    required Color actionColor,
    required bool canAdd,
    required VoidCallback onAdd,
    Map<String, dynamic>? data,
    VoidCallback? onRemove,
  }) {
    // ... Implementación del Card ... (se mantiene igual)
    if (data != null) {
      String subtitleText = title.contains('Analítico')
          ? 'Grado Pertenencia: ${data['gradoPertenencia'].toStringAsFixed(2)}'
          : 'Operador: ${data['nombre']}';

      return Card(
        color: actionColor.withOpacity(0.1),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: actionColor,
            child: Text(title.substring(title.length - 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(data['descripcion'] ?? data['nombre'], style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(subtitleText),
          trailing: onRemove != null ? IconButton(
            icon: const Icon(Icons.delete_outline, color: errorColor),
            onPressed: onRemove,
            tooltip: 'Eliminar',
          ) : null,
        ),
      );
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      leading: Icon(icon, size: 30, color: canAdd ? actionColor : Colors.grey),
      title: Text(hintText, style: TextStyle(color: canAdd ? Colors.black : Colors.grey)),
      trailing: ElevatedButton.icon(
        onPressed: canAdd ? onAdd : null,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: actionColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    // 🛑 CORRECCIÓN DE LÓGICA
    // 1. Operador: Solo se puede añadir si ya existe CA1.
    final bool canAddOperador = _criterioAnalitico1 != null && _operador == null;
    // 2. CA2: Solo se puede añadir si ya existe el OPERADOR y si CA2 no ha sido añadido.
    final bool canAddCA2 = _operador != null && _criterioAnalitico2 == null;


    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Descriptor para: ${widget.nombreCriterio}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
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
              children: [
                // 1. Contexto/Descripción del Descriptor (omitiendo código interno para brevedad)
                TextFormField(
                  controller: _contextoController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Contexto/Descripción del Descriptor',
                    labelStyle: TextStyle(color: primaryColor),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40.0, left: 8.0, top: 8.0),
                      child: Icon(Icons.description, color: primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El contexto del descriptor es obligatorio.';
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // 2. Peso del Descriptor (Slider, se mantiene igual)
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
                          'Peso del Descriptor: ${_pesoDescriptor.toStringAsFixed(2)} / 1.00',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)
                      ),
                      Slider(
                        value: _pesoDescriptor,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: _pesoDescriptor.toStringAsFixed(2),
                        activeColor: primaryColor,
                        inactiveColor: primaryColor.withOpacity(0.3),
                        onChanged: _onPesoDescriptorChanged,
                      ),
                      const Text(
                        'Nota: La suma de pesos de todos los Descriptores en el Criterio debe sumar 1.00.',
                        style: TextStyle(fontSize: 12, color: warningColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                const Divider(thickness: 1, color: primaryColor),
                const SizedBox(height: 10),

                // 3. Criterio Analítico 1 (Obligatorio)
                _buildItemCard(
                  title: 'Criterio Analítico 1',
                  hintText: _criterioAnalitico1 == null ? 'Añadir Criterio Analítico 1 (Obligatorio)' : 'Criterio Analítico 1 añadido',
                  icon: Icons.filter_1,
                  actionColor: accentColor,
                  canAdd: _criterioAnalitico1 == null,
                  onAdd: () => _navigateToAddAnalitico(1),
                  data: _criterioAnalitico1,
                  onRemove: _criterioAnalitico1 != null ? () => _eliminar(1) : null,
                ),
                const SizedBox(height: 15),

                // 4. Operador Lógico (Opcional, pero necesario si hay CA2)
                _buildItemCard(
                  title: 'Operador Lógico',
                  hintText: _operador == null ? 'Añadir Operador Lógico (AND/OR)' : 'Operador Lógico añadido',
                  icon: Icons.call_split,
                  actionColor: actionColor,
                  canAdd: canAddOperador,
                  onAdd: _navigateToAddOperador,
                  data: _operador,
                  onRemove: _operador != null ? () => _eliminar(0) : null,
                ),
                const SizedBox(height: 15),

                // 5. Criterio Analítico 2 (Obligatorio si hay Operador)
                _buildItemCard(
                  title: 'Criterio Analítico 2',
                  hintText: _criterioAnalitico2 == null ? 'Añadir Criterio Analítico 2 (Necesario con Operador)' : 'Criterio Analítico 2 añadido',
                  icon: Icons.filter_2,
                  actionColor: accentColor,
                  // 🛑 Usa la lógica corregida: requiere operador
                  canAdd: canAddCA2,
                  onAdd: () => _navigateToAddAnalitico(2),
                  data: _criterioAnalitico2,
                  onRemove: _criterioAnalitico2 != null ? () => _eliminar(2) : null,
                ),

                const SizedBox(height: 40),

                // 6. Botón de Guardar
                ElevatedButton.icon(
                  onPressed: _guardarDescriptorYVolver,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Descriptor y Volver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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