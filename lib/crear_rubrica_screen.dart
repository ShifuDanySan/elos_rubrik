import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 IMPORTACIÓN NECESARIA
import 'gestion_criterios_screen.dart'; // Importa la pantalla de gestión de criterios
import 'add_criterio_screen.dart'; // Importa la pantalla para añadir criterios
import 'dart:math';

// ===============================================
// CONSTANTES Y FUNCIONES AUXILIARES (Sincronizadas)
// ===============================================
const String __app_id = 'rubrica_evaluator'; // 💡 CONSTANTE DE ENTORNO
const double _tolerance = 0.0001;

// Define la función para calcular el peso total de los descriptores (para pasarla como callback)
double _calcularPesoDescriptorTotal(List<Map<String, dynamic>> descriptores) {
  // Asume que la clave para el peso dentro de cada descriptor es 'pesoDescriptor'
  return descriptores.fold(0.0, (sum, item) => sum + (item['pesoDescriptor'] as double? ?? 0.0));
}

// Define la función para calcular el peso total de los analíticos (para pasarla como callback)
double _calcularPesoAnaliticoTotal(List<Map<String, dynamic>> analiticos) {
  // Asume que la clave para el peso dentro de cada analítico es 'gradoPertenencia'
  return analiticos.fold(0.0, (sum, item) => sum + (item['gradoPertenencia'] as double? ?? 0.0));
}

// ===============================================

class CrearRubricaScreen extends StatefulWidget {
  const CrearRubricaScreen({super.key});

  @override
  State<CrearRubricaScreen> createState() => _CrearRubricaScreenState();
}

class _CrearRubricaScreenState extends State<CrearRubricaScreen> {
  final TextEditingController _nombreRubricaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Constantes de color
  static const Color primaryColor = Color(0xFF00796B); // Teal oscuro
  static const Color accentColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFEF5350); // Rojo Error
  static const Color saveButtonColor = Color(0xFF004D40); // Teal muy oscuro
  static const Color backgroundColor = Color(0xFFE0F2F1); // Teal 50 (Fondo)

  bool _isSaving = false;

  @override
  void dispose() {
    _nombreRubricaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FUNCIÓN DE CREACIÓN INICIAL CORREGIDA CON RUTA SEGURA
  // ==========================================================
  void _saveRubricaInitial() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de autenticación. No se pudo obtener el ID de usuario.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Obtener la referencia a la colección segura y anidada del usuario.
      // RUTA CORREGIDA: artifacts/rubrica_evaluator/users/{userId}/rubricas
      final CollectionReference rubricasRef = FirebaseFirestore.instance
          .collection('artifacts')
          .doc(__app_id)
          .collection('users')
          .doc(userId)
          .collection('rubricas');

      // 2. Crear el documento inicial en la ruta correcta
      final DocumentReference newDocRef = await rubricasRef.add({
        'nombre': _nombreRubricaController.text,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'criterios': [], // Lista vacía para ser llenada en la siguiente pantalla
        'pesoTotalCriterios': 0.0,
      });

      // 3. Navegar a la pantalla de gestión de criterios, pasando el ID recién creado
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GestionCriteriosScreen(
            rubricaId: newDocRef.id, // Pasamos el ID del documento
            calcularPesoDescriptorTotal: _calcularPesoDescriptorTotal,
            calcularPesoAnaliticoTotal: _calcularPesoAnaliticoTotal,
          ),
        ),
      );

      // Si el resultado de GestionCriteriosScreen es 'true' (guardado exitoso), volvemos a la lista
      if (result == true && mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear rúbrica: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool criteriosValidos = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Rúbrica'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Campo Nombre
                        TextFormField(
                          controller: _nombreRubricaController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de la Rúbrica',
                            hintText: 'Ej. Proyecto Final, Presentación Oral',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.description, color: primaryColor),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un nombre para la rúbrica.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. Indicador de estado para el siguiente paso
                        Card(
                          elevation: 2,
                          color: backgroundColor,
                          child: ListTile(
                            leading: Icon(Icons.playlist_add_check, color: primaryColor, size: 40),
                            title: const Text('Criterios de Evaluación'),
                            subtitle: const Text('La adición y validación de los pesos de los criterios se realiza en la siguiente pantalla.'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Instrucción
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: warningColor),
                          ),
                          child: const Text(
                            'Al presionar el botón, se creará la rúbrica base y se abrirá la pantalla de Gestión de Criterios para empezar a añadir y configurar los pesos (que deben sumar 1.00).',
                            style: TextStyle(color: warningColor, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Botón de Navegación/Guardado Inicial
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () {
                        if (_formKey.currentState!.validate()) {
                          _saveRubricaInitial();
                        }
                      },
                      icon: _isSaving
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        // 🛑 LÍNEA CORREGIDA: Eliminado 'padding: const EdgeInsets.all(2.0),'
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Icon(
                        criteriosValidos ? Icons.check_circle_outline : Icons.lock_outline,
                        size: 28,
                      ),
                      label: Text(
                        _isSaving
                            ? 'Guardando...'
                            : 'Crear y Añadir Criterios',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: saveButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: criteriosValidos ? primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
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