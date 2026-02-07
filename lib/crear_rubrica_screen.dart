import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_helper.dart';
import 'editar_rubrica_screen.dart';

class CrearRubricaScreen extends StatefulWidget {
  const CrearRubricaScreen({Key? key}) : super(key: key);

  @override
  State<CrearRubricaScreen> createState() => _CrearRubricaScreenState();
}

class _CrearRubricaScreenState extends State<CrearRubricaScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final String __app_id = 'rubrica_evaluator';
  bool _cargando = false;

  final Color primaryColor = Colors.blue;
  final Color actionButtonColor = const Color(0xFF2E7D32);
  final Color _accentColor = const Color(0xFFF06292);

  final GlobalKey _keyIconoNombre = GlobalKey();
  final GlobalKey _keyBotonCrear = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _initTutorial();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('seen_crear_rubrica_tutorial') ?? false);
    if (!seen) {
      Future.delayed(const Duration(milliseconds: 600), () => _showTutorial());
      await prefs.setBool('seen_crear_rubrica_tutorial', true);
    }
  }

  void _initTutorial() {
    targets.clear();
    targets.add(
      TargetFocus(
        identify: "IconoNombreTarget",
        keyTarget: _keyIconoNombre,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialStep("1", "Nombre de la Rúbrica", "Asigna un nombre claro (ej. 'Exposición Oral') para identificarla luego."),
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "BotonCrearTarget",
        keyTarget: _keyBotonCrear,
        shape: ShapeLightFocus.RRect,
        radius: 15,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialStep("2", "Confirmar", "Presiona aquí para guardar el nombre y comenzar a configurar los criterios."),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(String step, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _accentColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: _accentColor, radius: 12, child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      textSkip: "SALTAR",
    )..show(context: context);
  }

  Future<void> _guardarYContinuar() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un nombre para la rúbrica')));
      return;
    }

    setState(() => _cargando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = await FirebaseFirestore.instance.collection('rubricas').add({
          'nombre': _nombreController.text.trim(),
          'userId': user.uid,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'app_id': __app_id,
          'criterios': [],
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EditarRubricaScreen(
                rubricaId: docRef.id,
                nombreInicial: _nombreController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Nueva Rúbrica'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón para repetir tutorial
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
            tooltip: 'Ver tutorial',
          ),
          // Botón de cerrar sesión restaurado
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Título de la Rúbrica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nombreController,
                    autofocus: true, // El cursor empieza aquí
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.description, key: _keyIconoNombre, color: primaryColor),
                      hintText: 'Ej: Evaluación de Proyecto Final',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/unnamed.jpg',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: ElevatedButton(
              key: _keyBotonCrear,
              onPressed: _cargando ? null : _guardarYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionButtonColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 6,
              ),
              child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('CREAR Y CONFIGURAR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}