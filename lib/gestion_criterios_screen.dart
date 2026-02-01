// gestion_criterios_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_criterio_screen.dart';
import 'dart:math';
import 'auth_helper.dart';

// ===============================================
// CONSTANTES Y FUNCIONES AUXILIARES (Sincronizadas)
// ===============================================
typedef PesoCalculator = double Function(List<Map<String, dynamic>>);
const String __app_id = 'rubrica_evaluator';

// Constantes de color
const Color primaryColor = Color(0xFF00796B);
const Color accentColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color errorColor = Color(0xFFEF5350);
const Color saveButtonColor = Color(0xFF004D40);
const Color backgroundColor = Color(0xFFE0F2F1);
const double _tolerance = 0.0001;

// ===============================================

class GestionCriteriosScreen extends StatefulWidget {
  final String rubricaId;
  final PesoCalculator calcularPesoDescriptorTotal;
  final PesoCalculator calcularPesoAnaliticoTotal;

  const GestionCriteriosScreen({
    super.key,
    required this.rubricaId,
    required this.calcularPesoDescriptorTotal,
    required this.calcularPesoAnaliticoTotal,
  });

  @override
  State<GestionCriteriosScreen> createState() => _GestionCriteriosScreenState();
}

class _GestionCriteriosScreenState extends State<GestionCriteriosScreen> {
  // Estado para la lista de criterios añadidos
  List<Map<String, dynamic>> _criteriosPendientes = [];
  // Notificador para actualizar la UI con el peso total
  final ValueNotifier<double> _pesoTotalNotifier = ValueNotifier(0.0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchRubricaData();
  }

  // Carga inicial de datos
  void _fetchRubricaData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(__app_id)
          .collection('users')
          .doc(userId)
          .collection('rubricas')
          .doc(widget.rubricaId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('criterios')) {
          setState(() {
            _criteriosPendientes = List<Map<String, dynamic>>.from(data['criterios']);
          });
          _calcularPesoTotal();
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos de la rúbrica: $e');
    }
  }


  void _calcularPesoTotal() {
    double total = 0.0;
    for (var criterio in _criteriosPendientes) {
      total += (criterio['peso'] as double? ?? 0.0);
    }
    _pesoTotalNotifier.value = total;
  }

  // ----------------------------------------------------
  // 🚀 FUNCIÓN DE GUARDADO FINAL CORREGIDA (Permite forzar 1.00)
  // ----------------------------------------------------
  void _saveToFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.'), backgroundColor: errorColor),
        );
      }
      return;
    }

    // 🛑 LÓGICA DE FORZADO: Si solo hay un criterio, forzar su peso a 1.00
    if (_criteriosPendientes.length == 1) {
      // Usamos .abs() < _tolerance para ver si ya es 1.00 o no
      if ((_pesoTotalNotifier.value - 1.00).abs() >= _tolerance) {
        // Se aplica la corrección
        _criteriosPendientes[0]['peso'] = 1.00;
        // Se actualiza el notificador de peso total para reflejar el cambio en la UI
        _pesoTotalNotifier.value = 1.00;

        // Opcional: Mostrar un mensaje informativo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Peso del único criterio ajustado automáticamente a 1.00.'), backgroundColor: primaryColor),
          );
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      // RUTA DE FIRESTORE CORREGIDA Y SEGURA
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(__app_id)
          .collection('users')
          .doc(userId)
          .collection('rubricas')
          .doc(widget.rubricaId)
          .update({
        'criterios': _criteriosPendientes,
        'pesoTotalCriterios': _pesoTotalNotifier.value, // Ahora es 1.00 si se forzó
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rúbrica guardada con éxito.'), backgroundColor: accentColor),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la rúbrica: $e'), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  // ----------------------------------------------------

  void _navigateToAddCriterio() async {
    final nuevoCriterio = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCriterioScreen(
          calcularPesoDescriptorTotal: widget.calcularPesoDescriptorTotal,
          calcularPesoAnaliticoTotal: widget.calcularPesoAnaliticoTotal,
        ),
      ),
    );

    if (nuevoCriterio != null && nuevoCriterio is Map<String, dynamic>) {
      setState(() {
        _criteriosPendientes.add(nuevoCriterio);
      });
      _calcularPesoTotal();
    }
  }

  void _eliminarCriterio(int index) {
    setState(() {
      _criteriosPendientes.removeAt(index);
    });
    _calcularPesoTotal();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica si el peso total es válido (igual a 1.00 +/- una pequeña tolerancia)
    final bool pesoValido = (_pesoTotalNotifier.value - 1.00).abs() < _tolerance;
    final bool soloUnCriterio = _criteriosPendientes.length == 1;

    // 🛑 LÓGICA DE HABILITACIÓN DEL BOTÓN CORREGIDA
    // El botón se habilita si: (peso es válido) O (solo hay un criterio).
    final bool puedeGuardar = (pesoValido || soloUnCriterio) && _criteriosPendientes.isNotEmpty && !_isSaving;

    // Etiqueta del botón
    String botonLabel;
    if (_isSaving) {
      botonLabel = 'Guardando...';
    } else if (pesoValido) {
      botonLabel = 'Guardar Rúbrica Final';
    } else if (soloUnCriterio) {
      botonLabel = 'Guardar y Forzar Peso a 1.00 (Criterio Único)'; // ⬅️ Mensaje claro
    } else {
      botonLabel = 'Ajustar peso a 1.00 para guardar';
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Criterios'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          AuthHelper.logoutButton(context), // <--- Añadir aquí
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Indicador de Peso Total
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                child: ValueListenableBuilder<double>(
                  valueListenable: _pesoTotalNotifier,
                  builder: (context, pesoTotal, child) {
                    final color = pesoValido ? accentColor : warningColor;
                    final mensaje = 'Peso Total de Criterios: ${pesoTotal.toStringAsFixed(2)} / 1.00';
                    return Text(
                      mensaje,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
              ),

              // Lista de Criterios
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _criteriosPendientes.length,
                  itemBuilder: (context, index) {
                    final criterio = _criteriosPendientes[index];
                    final nombre = criterio['nombre'] ?? 'Criterio sin nombre';
                    final peso = (criterio['peso'] as double? ?? 0.0).toStringAsFixed(2);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.8),
                          child: Text('$peso', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Peso: $peso. Descriptores: ${criterio['descriptores'].length}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever, color: errorColor),
                          onPressed: () => _eliminarCriterio(index),
                        ),
                        // Aquí podrías añadir una navegación a edición si es necesario
                      ),
                    );
                  },
                ),
              ),

              // Botones de Acción
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    // Botón Añadir
                    ElevatedButton.icon(
                      onPressed: _navigateToAddCriterio,
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text('Añadir Nuevo Criterio', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Botón Guardar Rúbrica
                    ElevatedButton.icon(
                      onPressed: puedeGuardar ? _saveToFirestore : null,
                      icon: _isSaving
                          ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                          : const Icon(Icons.save, size: 24),
                      label: Text(
                        botonLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: saveButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}