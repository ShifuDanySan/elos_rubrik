import 'package:flutter/material.dart';
import 'crear_rubrica_screen.dart';
import 'lista_rubricas_screen.dart';
import 'lista_evaluaciones_screen.dart';
import 'dart:math' as math;
import 'dart:math';

// ===============================================
// CONSTANTES DE ESTILO DEL HOME SCREEN (PALETA VIOLETA)
// ===============================================
const Color _primaryColor = Color(0xFF5E35B1); // Deep Purple
const Color _accentColor = Color(0xFFF06292); // Pink Claro (Fucsia Suave)
// COLOR CLAVE PARA FONDO SUAVE: Lavanda muy suave
const Color _homeBackgroundColor = Color(0xFFEDE7F6); // Deep Purple 50
// La imagen debe estar en la carpeta 'assets/images/'
const String _imageUrl = 'assets/images/unnamed.jpg';

// ===============================================
// WIDGET AUXILIAR: Fondo Animado Flotante (Floating Shapes)
// ===============================================

class FloatingShapesBackground extends StatefulWidget {
  const FloatingShapesBackground({super.key});

  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground> {
  List<Widget> _floatingShapes = [];
  final Random _random = Random();
  final int _numberOfShapes = 60; // Cantidad de figuras
  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentSize = MediaQuery.of(context).size;

    // Regenerar las formas si el tamaño de la pantalla ha cambiado
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
      // Las figuras usan los nuevos colores violeta y fucsia
      final Color color = _random.nextBool() ? _primaryColor : _accentColor;
      final Duration duration = Duration(seconds: 15 + _random.nextInt(20));

      // Generar posiciones iniciales que pueden estar fuera del 0.0 - 1.0 (pantalla visible)
      final double initialX = -0.5 + _random.nextDouble() * 2.0;
      final double initialY = -0.5 + _random.nextDouble() * 2.0;

      _floatingShapes.add(
        PositionedShape(
          key: ValueKey('shape_$i'),
          initialPositionX: initialX,
          initialPositionY: initialY,
          size: size,
          color: color,
          duration: duration,
          isSquare: isSquare,
        ),
      );
    }
    // Forzar el redibujado
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Fondo base de la pantalla
        Container(color: _homeBackgroundColor),

        // 2. Formas animadas flotantes
        ..._floatingShapes,
      ],
    );
  }
}

class PositionedShape extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final bool isSquare;
  final double initialPositionX;
  final double initialPositionY;

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

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PositionedShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset getMotionOffset(double animationValue) {
    // Calcula un movimiento sinusoidal/cosenoidal dentro de un rango
    final dx = math.sin(animationValue * 2 * math.pi + _sinOffset) * _motionRange / 2;
    final dy = math.cos(animationValue * 2 * math.pi + _cosOffset) * _motionRange / 2;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final constraints = MediaQuery.of(context).size;
    final double dynamicOpacity = 0.3 + (_random.nextDouble() * 0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {

        // Calcular la posición inicial basada en el tamaño de la pantalla
        final initialTop = widget.initialPositionY * constraints.height;
        final initialLeft = widget.initialPositionX * constraints.width;

        final motion = getMotionOffset(_controller.value);

        return Positioned(
          top: initialTop + motion.dy,
          left: initialLeft + motion.dx,

          child: Transform.rotate(
            angle: _controller.value * math.pi / 2,
            child: Opacity(
              opacity: dynamicOpacity,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  // Usar la opacidad del color más alta
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

// ===============================================
// WIDGET PRINCIPAL: Banner de Bienvenida con Imagen
// ===============================================

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura relativa al tamaño de la pantalla
      height: MediaQuery.of(context).size.height * 0.30,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        // Color de fallback si la imagen no carga
        color: _primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        // CONFIGURACIÓN CLAVE: Usa DecorationImage con BoxFit.cover
        image: const DecorationImage(
          image: AssetImage(_imageUrl),
          fit: BoxFit.cover,
          // Agregamos un colorFilter para asegurar la legibilidad del texto blanco
          colorFilter: ColorFilter.mode(
            Colors.black54, // Oscurece la imagen ligeramente
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Overlay de degradado (Se mantiene para un efecto visual suave)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // 2. Contenido de Bienvenida (Capa superior)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bienvenido, Prof. Dany San',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu centro de control para la gestión de rúbricas y el seguimiento académico.',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ===============================================
// WIDGET PRINCIPAL: HomeScreen
// ===============================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Estructura de datos para los tiles del menú
  final List<Map<String, dynamic>> _menuOptions = const [
    {
      'title': 'Crear Nueva Rúbrica',
      'subtitle': 'Diseña una nueva herramienta de evaluación con criterios, descriptores y analíticos.',
      'icon': Icons.edit_note_sharp,
      'color': Color(0xFF7E57C2), // Morado (Purple 400)
      'screen': CrearRubricaScreen(),
    },
    {
      'title': 'Gestionar y Evaluar Rúbricas',
      'subtitle': 'Visualiza tus rúbricas existentes, evalúa a estudiantes y revisa resultados.',
      'icon': Icons.rule_sharp,
      'color': Color(0xFF66BB6A), // Verde (Green 400) - Mantenemos contraste
      'screen': ListaRubricasScreen(),
    },
    {
      'title': 'Mis Evaluaciones',
      'subtitle': 'Acceso rápido a todas las evaluaciones realizadas y métricas de desempeño.',
      'icon': Icons.bar_chart_sharp,
      'color': Color(0xFFEF5350), // Rojo (Red 400) - Mantenemos contraste
      'screen': ListaEvaluacionesScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rúbrica Digital - Inicio'),
        // AppBar con color oscuro de la nueva paleta
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 10,
      ),
      // Aplicar un color base suave con algo de transparencia para que
      // las formas del Stack inferior puedan verse a través del cuerpo.
      backgroundColor: _homeBackgroundColor.withOpacity(0.7),
      body: Stack(
        children: [
          // 1. Fondo Animado Flotante (Capa inferior - Ahora más visible)
          const FloatingShapesBackground(),

          // 2. Contenido Central (Sección de Bienvenida y Tiles) (Capa superior)
          Center(
            child: Container(
              // Contenedor de contenido transparente
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Sección de Bienvenida (El Banner con la imagen) ---
                    const WelcomeBanner(),

                    // --- Separador y Texto de Acción ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                      child: Text(
                        'Selecciona una acción:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade900),
                      ),
                    ),

                    // --- Generación de los Tiles del menú ---
                    ..._menuOptions.map((option) {
                      final Color primaryColor = option['color'] as Color;
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
                                  // Icono Estilizado con Fondo
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: primaryColor.withOpacity(0.5)),
                                    ),
                                    child: Icon(
                                      option['icon'] as IconData,
                                      color: primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // Título y Subtítulo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['title'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            // Usar un color oscuro para legibilidad sobre fondo blanco
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option['subtitle'] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Flecha de navegación
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
}