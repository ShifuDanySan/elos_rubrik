import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_helper.dart';
import 'editar_rubrica_screen.dart';
import 'editar_rubrica_difusa_screen.dart';
import 'tutorial_helper.dart';

const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

class CrearRubricaScreen extends StatefulWidget {
  const CrearRubricaScreen({Key? key}) : super(key: key);

  @override
  State<CrearRubricaScreen> createState() => _CrearRubricaScreenState();
}

class _CrearRubricaScreenState extends State<CrearRubricaScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final String __app_id = 'rubrica_evaluator';
  bool _cargando = false;
  int? _tipoRubrica;

  final Color primaryColor = Colors.blue;
  final Color actionButtonColor = const Color(0xFF2E7D32);

  final GlobalKey _keyNombreRubrica = GlobalKey();
  final GlobalKey _keyTipoRubrica = GlobalKey();
  final GlobalKey _keyBotonCrear = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void _lanzarTutorial({bool force = true}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'CREAR_RUBRICA',
      keys: {
        'nombre_rubrica': _keyNombreRubrica,
        'tipo_rubrica': _keyTipoRubrica,
        'btn_guardar': _keyBotonCrear,
      },
      force: force,
    );
  }

  Future<void> _abrirManualPdf() async {
    final Uri uri = Uri.parse(_pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el manual de usuario.')),
        );
      }
    }
  }

  Future<void> _guardarYContinuar() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un nombre para la rúbrica')));
      return;
    }

    if (_tipoRubrica == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un tipo de rúbrica')));
      return;
    }

    setState(() => _cargando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<Map<String, dynamic>> plantillaInicial = [];

        if (_tipoRubrica == 2) {
          plantillaInicial = [
            {
              'nombre': 'Criterio 1',
              'porcentaje': 0.0,
              'descriptores': [
                {
                  'contexto': 'Nivel 1',
                  'puntos': 10.0,
                  'texto': '',
                  'analiticos': [],
                }
              ]
            }
          ];
        }

        final docRef = await FirebaseFirestore.instance
            .collection('artifacts/$__app_id/users/${user.uid}/rubricas')
            .add({
          'nombre': _nombreController.text.trim(),
          'tipoRubrica': _tipoRubrica,
          'userId': user.uid,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'app_id': __app_id,
          'criterios': plantillaInicial,
        });

        if (mounted) {
          if (_tipoRubrica == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditarRubricaScreen(
                  rubricaId: docRef.id,
                  nombreInicial: _nombreController.text.trim(),
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditarRubricaDifusaScreen(
                  rubricaId: docRef.id,
                  nombreInicial: _nombreController.text.trim(),
                ),
              ),
            );
          }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Nueva Rúbrica'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'Manual de usuario',
              onPressed: _abrirManualPdf,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                ),
                onPressed: _abrirManualPdf,
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: const Text(
                  'MANUAL DE USUARIO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _lanzarTutorial(force: true),
            tooltip: 'Ver tutorial',
          ),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Text('Título de la Rúbrica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  const SizedBox(height: 15),
                  TextFormField(
                    key: _keyNombreRubrica,
                    controller: _nombreController,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.description, color: primaryColor),
                      hintText: 'Ej: Evaluación de Proyecto Final',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Align(alignment: Alignment.centerLeft, child: Text('SELECCIONE EL TIPO DE RÚBRICA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    key: _keyTipoRubrica,
                    value: _tipoRubrica,
                    hint: const Text('SELECCIONE EL TIPO DE RÚBRICA'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('RÚBRICA TRADICIONAL'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('RÚBRICA DIFUSA'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _tipoRubrica = val);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/unnamed.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}