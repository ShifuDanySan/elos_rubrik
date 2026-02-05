import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_helper.dart';
import 'editar_rubrica_screen.dart';

class CrearRubricaScreen extends StatefulWidget {
  const CrearRubricaScreen({super.key});

  @override
  State<CrearRubricaScreen> createState() => _CrearRubricaScreenState();
}

class _CrearRubricaScreenState extends State<CrearRubricaScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final String __app_id = 'rubrica_evaluator';
  bool _cargando = false;

  final Color primaryColor = Colors.blue;
  final Color actionButtonColor = const Color(0xFF2E7D32);

  Future<void> _guardarYContinuar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un nombre para la rúbrica')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('artifacts/$__app_id/users/$userId/rubricas')
          .doc();

      await docRef.set({
        'nombre': nombre,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'criterios': [],
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditarRubricaScreen(
              rubricaId: docRef.id,
              nombreInicial: nombre,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        title: const Text('Nueva Rúbrica', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: Column(
        children: [
          // Tarjeta superior
          Container(
            padding: const EdgeInsets.all(25.0),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¿Cómo se llamará esta rúbrica?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nombreController,
                  autofocus: true, // El cursor empieza aquí
                  decoration: InputDecoration(
                    hintText: 'Ej: Proyecto Final de Ciencias',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none
                    ),
                    prefixIcon: Icon(Icons.edit_note, color: primaryColor),
                  ),
                  onSubmitted: (_) => _guardarYContinuar(),
                ),
              ],
            ),
          ),

          // Área de imagen que destaca y ocupa el espacio central
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/unnamed.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Botón fijo en la parte inferior
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: ElevatedButton(
              onPressed: _cargando ? null : _guardarYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionButtonColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 6,
              ),
              child: _cargando
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text(
                  'CREAR Y CONFIGURAR',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }
}