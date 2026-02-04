import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar la Web
import 'crear_rubrica_screen.dart';
import 'lista_rubricas_screen.dart';
import 'lista_evaluaciones_screen.dart';
// import 'profile_edit_screen.dart'; // <--- ELIMINADO PARA CORREGIR ERROR
import 'dart:math' as math;
import 'dart:math';
import 'auth_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===============================================
// CONSTANTES DE ESTILO
// ===============================================
const Color _primaryColor = Color(0xFF5E35B1);
const Color _accentColor = Color(0xFFF06292);
const Color _homeBackgroundColor = Color(0xFFEDE7F6);
const String _imageUrl = 'assets/images/logo-elos.jpg';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = "";
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nombreUsuario = "${data['nombre'] ?? ''} ${data['apellido'] ?? ''}";
            _photoUrl = data['photoUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _nombreUsuario = user.displayName ?? "USUARIO";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _nombreUsuario = "USUARIO";
        _isLoading = false;
      });
      debugPrint("Error cargando datos: $e");
    }
  }

  String _obtenerSaludoPorHora() {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 13) return "BUENOS DÍAS";
    if (hora >= 13 && hora < 20) return "BUENAS TARDES";
    return "BUENAS NOCHES";
  }

  final List<Map<String, dynamic>> _menuOptions = const [
    {
      'title': 'Crear Nueva Rúbrica',
      'subtitle': 'Diseña una nueva herramienta de evaluación con criterios y descriptores.',
      'icon': Icons.edit_note_sharp,
      'color': Color(0xFF7E57C2),
      'screen': CrearRubricaScreen(),
    },
    {
      'title': 'Gestionar y Evaluar Rúbricas',
      'subtitle': 'Visualiza tus rúbricas existentes, evalúa a estudiantes y revisa resultados.',
      'icon': Icons.rule_sharp,
      'color': Color(0xFF66BB6A),
      'screen': ListaRubricasScreen(),
    },
    {
      'title': 'Mis Evaluaciones',
      'subtitle': 'Acceso rápido a todas las evaluaciones realizadas y métricas de desempeño.',
      'icon': Icons.bar_chart_sharp,
      'color': Color(0xFFEF5350),
      'screen': ListaEvaluacionesScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elos-Rubrik'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Tooltip(
            message: 'Perfil',
            child: GestureDetector(
              onTap: () {
                // CORRECCIÓN: En lugar de navegar a ProfileEditScreen, informamos al usuario
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ajustes de perfil no disponibles.")),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? const Icon(Icons.account_circle, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Stack(
        children: [
          const FloatingShapesBackground(),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildDynamicWelcomeBanner(),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selecciona una acción:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade900
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._menuOptions.map((option) {
                      final Color color = option['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => option['screen'] as Widget),
                              );
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withOpacity(0.5)),
                                    ),
                                    child: Icon(option['icon'] as IconData, color: color, size: 30),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['title'] as String,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.deepPurple.shade700
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option['subtitle'] as String,
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 24, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicWelcomeBanner() {
    double size = 380;
    double scaleFactor = kIsWeb ? 1.04 : 1.15;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 4,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scaleFactor,
              child: Image.asset(
                _imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 45,
              child: SizedBox(
                width: size * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoading ? 'CARGANDO...' : _obtenerSaludoPorHora(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(blurRadius: 12, color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                    if (!_isLoading) ...[
                      const SizedBox(height: 4),
                      Text(
                        _nombreUsuario.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 15, color: Colors.black, offset: Offset(2, 2)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASES DE FONDO ANIMADO ---
class FloatingShapesBackground extends StatefulWidget {
  const FloatingShapesBackground({super.key});
  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground> {
  List<Widget> _floatingShapes = [];
  final Random _random = Random();
  final int _numberOfShapes = 60;
  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.of(context).size;
    if (_lastSize == null || _lastSize != currentSize || _floatingShapes.isEmpty) {
      _lastSize = currentSize;
      _generateRandomShapes();
    }
  }

  void _generateRandomShapes() {
    _floatingShapes = [];
    for (int i = 0; i < _numberOfShapes; i++) {
      final bool isSquare = _random.nextBool();
      final double size = 30.0 + _random.nextDouble() * 120.0;
      final Color color = _random.nextBool() ? _primaryColor : _accentColor;
      final Duration duration = Duration(seconds: 15 + _random.nextInt(20));
      _floatingShapes.add(
        PositionedShape(
          key: ValueKey('shape_$i'),
          initialPositionX: -0.5 + _random.nextDouble() * 2.0,
          initialPositionY: -0.5 + _random.nextDouble() * 2.0,
          size: size,
          color: color,
          duration: duration,
          isSquare: isSquare,
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: _homeBackgroundColor),
        ..._floatingShapes,
      ],
    );
  }
}

class PositionedShape extends StatefulWidget {
  final double size, initialPositionX, initialPositionY;
  final Color color;
  final Duration duration;
  final bool isSquare;

  const PositionedShape({
    super.key,
    required this.size,
    required this.color,
    required this.duration,
    required this.isSquare,
    required this.initialPositionX,
    required this.initialPositionY,
  });

  @override
  State<PositionedShape> createState() => _PositionedShapeState();
}

class _PositionedShapeState extends State<PositionedShape> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late double _sinOffset;
  late double _cosOffset;
  final double _motionRange = 150.0;

  @override
  void initState() {
    super.initState();
    _sinOffset = _random.nextDouble() * math.pi * 2;
    _cosOffset = _random.nextDouble() * math.pi * 2;
    _controller = AnimationController(duration: widget.duration, vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final constraints = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = math.sin(_controller.value * 2 * math.pi + _sinOffset) * _motionRange / 2;
        final dy = math.cos(_controller.value * 2 * math.pi + _cosOffset) * _motionRange / 2;
        return Positioned(
          top: widget.initialPositionY * constraints.height + dy,
          left: widget.initialPositionX * constraints.width + dx,
          child: Transform.rotate(
            angle: _controller.value * math.pi / 2,
            child: Opacity(
              opacity: 0.3 + (_random.nextDouble() * 0.4),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(widget.isSquare ? 15.0 : widget.size / 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}