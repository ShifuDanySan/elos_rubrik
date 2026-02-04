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
        // MENSAJE DE CONFIRMACIÓN SOLICITADO
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rúbrica creada con éxito'),
            backgroundColor: Color(0xFF4CAF50), // Verde para éxito
            duration: Duration(seconds: 2),
          ),
        );

        // Navegamos a la pantalla de edición
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
    const Color primaryColor = Color(0xFF00796B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Rúbrica'),
        actions: [AuthHelper.logoutButton(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Cómo se llamará esta rúbrica?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              autofocus: true, // El cursor empieza aquí
              decoration: InputDecoration(
                labelText: 'Nombre de la rúbrica',
                hintText: 'Ej: Proyecto Final de Ciencias',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_note, color: primaryColor),
              ),
              onSubmitted: (_) => _guardarYContinuar(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _cargando ? null : _guardarYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _cargando
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text('CREAR Y CONFIGURAR', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}