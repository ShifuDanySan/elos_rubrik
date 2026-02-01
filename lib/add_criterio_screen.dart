import 'package:flutter/material.dart';
import 'add_descriptor_screen.dart';
import 'auth_helper.dart'; // <--- AGREGAR ESTO// Asegúrate de que este archivo ya está corregido

// Define un alias para el tipo de función que calcula el peso total
typedef PesoCalculator = double Function(List<Map<String, dynamic>>);

class AddCriterioScreen extends StatefulWidget {
  final PesoCalculator calcularPesoDescriptorTotal;
  final PesoCalculator calcularPesoAnaliticoTotal;

  const AddCriterioScreen({
    super.key,
    required this.calcularPesoDescriptorTotal,
    required this.calcularPesoAnaliticoTotal,
  });

  @override
  State<AddCriterioScreen> createState() => _AddCriterioScreenState();
}

class _AddCriterioScreenState extends State<AddCriterioScreen> {
  final TextEditingController _nombreCriterioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Constantes de color (Mismo esquema que la pantalla principal)
  static const Color primaryColor = Color(0xFF00796B); // Teal oscuro
  static const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFEF5350); // Rojo Error
  static const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50

  List<Map<String, dynamic>> _descriptoresPendientes = [];

  // 1. 🛑 CORRECCIÓN: Variable de estado para guardar el peso del Criterio
  double _pesoCriterio = 0.10;

  // Variables de Validación Descriptor
  bool _pesoDescriptorEsUno = false;
  double _pesoDescriptorActual = 0.0;

  // Tolerancia para comparación de 1.00
  static const double _tolerance = 0.0001;

  @override
  void initState() {
    super.initState();
    _recalcularPesosDescriptores();
  }

  @override
  void dispose() {
    _nombreCriterioController.dispose();
    super.dispose();
  }

  void _recalcularPesosDescriptores() {
    // Usar la función de cálculo inyectada para obtener el peso total
    final pesoActual = widget.calcularPesoDescriptorTotal(_descriptoresPendientes);

    setState(() {
      _pesoDescriptorActual = pesoActual;
      // Validamos que la suma de pesos esté muy cerca de 1.00
      _pesoDescriptorEsUno = (_descriptoresPendientes.isEmpty && pesoActual == 0.0) ||
          (_descriptoresPendientes.isNotEmpty && (pesoActual - 1.00).abs() < _tolerance);
    });
  }

  // 2. 🛑 CORRECCIÓN: Función para forzar la suma de pesos de Descriptores a 1.00
  void _forzarPesoDescriptorAUno() {
    if (_descriptoresPendientes.isEmpty) return;

    final double suma = _pesoDescriptorActual;

    if (suma > _tolerance && !_pesoDescriptorEsUno) {
      final double factor = 1.00 / suma;

      setState(() {
        _descriptoresPendientes = _descriptoresPendientes.map((descriptor) {
          final double pesoOriginal = descriptor['pesoDescriptor'] as double? ?? 0.0;
          // 🛑 CORRECCIÓN: Actualizar el campo 'pesoDescriptor' del mapa
          descriptor['pesoDescriptor'] = (pesoOriginal * factor);
          return descriptor;
        }).toList();

        // Volver a calcular para reflejar el cambio (debería dar 1.00)
        _recalcularPesosDescriptores();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesos de Descriptores ajustados para sumar 1.00.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: accentColor,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  // 3. 🛑 CORRECCIÓN: Handler para el Slider de Peso del Criterio
  void _onPesoCriterioChanged(double value) {
    setState(() {
      _pesoCriterio = double.parse(value.toStringAsFixed(2));
    });
  }

  void _navigateToAddDescriptor() async {
    final String nombreCriterio = _nombreCriterioController.text.trim().isEmpty
        ? 'Nuevo Criterio'
        : _nombreCriterioController.text.trim();

    final Map<String, dynamic>? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddDescriptorScreen(nombreCriterio: nombreCriterio),
      ),
    );

    if (result != null) {
      setState(() {
        _descriptoresPendientes.add(result);
        _recalcularPesosDescriptores();
      });
    }
  }

  void _eliminarDescriptor(int index) {
    setState(() {
      _descriptoresPendientes.removeAt(index);
      _recalcularPesosDescriptores();
    });
  }

  void _guardarCriterioYVolver() {
    if (!_formKey.currentState!.validate() || _descriptoresPendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ERROR: El nombre del Criterio y al menos un Descriptor son obligatorios.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // 4. VALIDACIÓN DE PESOS DESCRIPTORES
    if (!_pesoDescriptorEsUno && _descriptoresPendientes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ERROR: La suma de pesos de los Descriptores debe ser 1.00 (Actual: ${_pesoDescriptorActual.toStringAsFixed(2)}). Use "Forzar a 1.00" o ajústelos.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // 5. 🛑 CORRECCIÓN: Incluir el peso del Criterio en el mapa final
    final Map<String, dynamic> nuevoCriterio = {
      'nombre': _nombreCriterioController.text.trim(),
      'pesoDescriptor': _pesoCriterio, // Campo utilizado en crear_rubrica_screen.dart
      'descriptores': _descriptoresPendientes,
    };

    Navigator.of(context).pop(nuevoCriterio);
  }


  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool descriptoresValidos = _descriptoresPendientes.isNotEmpty && _pesoDescriptorEsUno;
    final Color saveButtonColor = descriptoresValidos ? primaryColor : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Añadir Nuevo Criterio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        actions: [
          AuthHelper.logoutButton(context), // <--- AGREGAR EL BOTÓN AQUÍ
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Nombre del Criterio
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nombreCriterioController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Criterio (Ej: Claridad de la Exposición)',
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.label_important_outline, color: primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El nombre del criterio es obligatorio.';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 25),

              // 2. Peso del Criterio (Slider)
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
                        'Peso del Criterio: ${_pesoCriterio.toStringAsFixed(2)} / 1.00',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)
                    ),
                    Slider(
                      value: _pesoCriterio,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: _pesoCriterio.toStringAsFixed(2),
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.3),
                      // 🛑 CORRECCIÓN: Usar el handler del peso del criterio
                      onChanged: _onPesoCriterioChanged,
                    ),
                    const Text(
                      'Nota: La suma de pesos de todos los Criterios en la Rúbrica debe sumar 1.00.',
                      style: TextStyle(fontSize: 12, color: warningColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Divider(thickness: 1, color: primaryColor),

              // 3. Indicador de Pesos Descriptores y Botón Forzar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total de Peso de Descriptores: ${_pesoDescriptorActual.toStringAsFixed(2)} / 1.00',
                        style: TextStyle(
                          color: _pesoDescriptorEsUno ? accentColor : errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    // Botón Forzar a 1.00 (se habilita si no es 1.00 y hay descriptores)
                    if (!_pesoDescriptorEsUno && _descriptoresPendientes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _forzarPesoDescriptorAUno, // 🛑 CORRECCIÓN: Llamada a la función
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: isSmallScreen ? const Text('Forzar', style: TextStyle(fontSize: 12)) : const Text('Forzar a 1.00'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: warningColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 8 : 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(thickness: 1, color: primaryColor),

              // 4. Lista de Descriptores (Usamos Expanded con ListView para el scrolling)
              Expanded(
                child: _descriptoresPendientes.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 80, color: primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 10),
                      Text(
                        'Añada Descriptores para este Criterio.',
                        style: TextStyle(fontSize: 16, color: primaryColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _descriptoresPendientes.length,
                  itemBuilder: (context, index) {
                    final descriptor = _descriptoresPendientes[index];
                    final peso = descriptor['pesoDescriptor'] as double? ?? 0.0;
                    final contexto = descriptor['contexto'] as String? ?? 'Descriptor sin contexto';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accentColor,
                          child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(contexto, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Peso: ${peso.toStringAsFixed(2)} - Analíticos: ${descriptor['analiticos'].length}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: errorColor),
                          onPressed: () => _eliminarDescriptor(index),
                          tooltip: 'Eliminar Descriptor',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 5. Botones de Acción (Añadir Descriptor y Guardar Criterio)
              // Usamos Row con Expanded para pantallas grandes, o Column para pantallas pequeñas
              isSmallScreen
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _navigateToAddDescriptor,
                    icon: const Icon(Icons.add_comment_outlined, color: primaryColor),
                    label: const Text('Añadir Descriptor', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: descriptoresValidos ? _guardarCriterioYVolver : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Criterio y Volver', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: saveButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _navigateToAddDescriptor,
                      icon: const Icon(Icons.add_comment_outlined, color: primaryColor),
                      label: const Text('Añadir Descriptor', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        side: const BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: descriptoresValidos ? _guardarCriterioYVolver : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Criterio y Volver', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        backgroundColor: saveButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}