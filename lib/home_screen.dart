import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'crear_rubrica_screen.dart';
import 'lista_rubricas_screen.dart';
import 'lista_evaluaciones_screen.dart';
import 'profile_edit_screen.dart';
import 'dart:math' as math;
import 'dart:math';
import 'auth_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===============================================
// CONSTANTES DE ESTILO
// ===============================================
const Color _primaryColor = Color(0xFF5E35B1);
const Color _accentColor = Color(0xFFF06292);
const Color _homeBackgroundColor = Color(0xFFEDE7F6);
const String _imageUrl = 'assets/images/logo-elos.jpg';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = "";
  String? _photoUrl;
  bool _isLoading = true;
  final String __app_id = 'rubrica_evaluator';

  final GlobalKey _keyBanner = GlobalKey();
  final GlobalKey _keyOpciones = GlobalKey();
  final GlobalKey _keyPerfil = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _initTutorial();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('seen_home_tutorial') ?? false);

    if (!seen) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _showTutorial();
      });
      await prefs.setBool('seen_home_tutorial', true);
    }
  }

  void _initTutorial() {
    targets.clear();
    targets.add(
      TargetFocus(
        identify: "BannerTarget",
        keyTarget: _keyBanner,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialStep("1", "Panel Principal", "Aquí verás el saludo dinámico y el logo oficial de ELOS en formato moneda."),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "OpcionesTarget",
        keyTarget: _keyOpciones,
        shape: ShapeLightFocus.RRect,
        radius: 15,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _buildTutorialStep("2", "Acciones", "Desde aquí puedes crear rúbricas, gestionar evaluaciones o ver tus resultados."),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "PerfilTarget",
        keyTarget: _keyPerfil,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _buildTutorialStep("3", "Tu Cuenta", "Accede a la edición de tu perfil y sincronización de datos aquí."),
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
              CircleAvatar(
                backgroundColor: _accentColor,
                radius: 12,
                child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      textSkip: "SALTAR",
      onFinish: () => debugPrint("Tutorial finalizado"),
    )..show(context: context);
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
    }
  }

  String _obtenerSaludoPorHora() {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 13) return "BUENOS DÍAS";
    if (hora >= 13 && hora < 20) return "BUENAS TARDES";
    return "BUENAS NOCHES";
  }

  Future<void> _verificarYEntrarALista() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('artifacts/$__app_id/users/${user.uid}/rubricas')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      _mostrarDialogoInformativo(
        "No hay rúbricas",
        "Aún no has creado ninguna rúbrica. Por favor, crea una nueva para poder gestionarla.",
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ListaRubricasScreen()),
      );
    }
  }

  Future<void> _verificarYEntrarAEvaluaciones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('artifacts/$__app_id/users/${user.uid}/evaluaciones')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      _mostrarDialogoInformativo(
        "Sin evaluaciones",
        "No se han encontrado evaluaciones realizadas. Realiza una evaluación desde 'Gestionar y Evaluar' para ver el historial.",
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ListaEvaluacionesScreen()),
      );
    }
  }

  void _mostrarDialogoInformativo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.info_outline, size: 50, color: _primaryColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _menuOptions = const [
    {
      'id': 'crear',
      'title': 'Crear Nueva Rúbrica',
      'subtitle': 'Diseña una nueva herramienta de evaluación con criterios.',
      'icon': Icons.edit_note_sharp,
      'color': Color(0xFF7E57C2),
    },
    {
      'id': 'gestionar',
      'title': 'Gestionar y Evaluar',
      'subtitle': 'Visualiza tus rúbricas y evalúa a estudiantes.',
      'icon': Icons.rule_sharp,
      'color': Color(0xFF66BB6A),
    },
    {
      'id': 'evaluaciones',
      'title': 'Mis Evaluaciones',
      'subtitle': 'Acceso rápido a todas las evaluaciones realizadas.',
      'icon': Icons.bar_chart_sharp,
      'color': Color(0xFFEF5350),
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Repetir Tutorial',
            onPressed: _showTutorial,
          ),
          Tooltip(
            message: 'Perfil',
            child: GestureDetector(
              key: _keyPerfil,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                ).then((_) => _cargarDatosUsuario());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      key: _keyBanner,
                      fit: BoxFit.scaleDown,
                      child: CoinFlipLogo(
                        photoUrl: _photoUrl,
                        saludo: _isLoading ? 'CARGANDO...' : _obtenerSaludoPorHora(),
                        nombre: _nombreUsuario.toUpperCase(),
                      ),
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
                    Column(
                      key: _keyOpciones,
                      children: _menuOptions.map((option) {
                        final Color color = option['color'] as Color;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: InkWell(
                              onTap: () {
                                if (option['id'] == 'crear') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const CrearRubricaScreen()),
                                  );
                                } else if (option['id'] == 'gestionar') {
                                  _verificarYEntrarALista();
                                } else if (option['id'] == 'evaluaciones') {
                                  _verificarYEntrarAEvaluaciones();
                                }
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
                    ),
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

// ===============================================
// WIDGET: MONEDA GIRATORIA SIEMPRE A LA DERECHA
// ===============================================
class CoinFlipLogo extends StatefulWidget {
  final String? photoUrl;
  final String saludo;
  final String nombre;

  const CoinFlipLogo({
    super.key,
    this.photoUrl,
    required this.saludo,
    required this.nombre,
  });

  @override
  State<CoinFlipLogo> createState() => _CoinFlipLogoState();
}

class _CoinFlipLogoState extends State<CoinFlipLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Inicialmente de 0 a 0
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);

    _startTimer();
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        // Incrementamos el ángulo 180 grados (pi) siempre hacia adelante
        double nextAngle = _currentAngle + math.pi;

        setState(() {
          _animation = Tween<double>(
            begin: _currentAngle,
            end: nextAngle,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutBack,
          ));
        });

        await _controller.forward(from: 0);
        _currentAngle = nextAngle;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 300;
    const double scaleFactor = kIsWeb ? 1.04 : 1.15;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double angle = _animation.value;

        // Normalizamos el ángulo para saber qué cara mostrar (0-360 grados)
        // Cada pi (180 grados) cambia la visibilidad.
        final double normalizedAngle = angle % (2 * math.pi);
        final bool isBackVisible = normalizedAngle > math.pi / 2 && normalizedAngle < 1.5 * math.pi;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspectiva
            ..rotateY(angle),
          alignment: Alignment.center,
          child: Container(
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
                  // Lado FRONT: Logo
                  if (!isBackVisible)
                    Transform.scale(
                      scale: scaleFactor,
                      child: Image.asset(
                        _imageUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      ),
                    ),

                  // Lado BACK: Foto Perfil
                  if (isBackVisible)
                    Transform(
                      // Rotamos el contenido trasero 180 grados para que no se vea espejado
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: scaleFactor,
                        child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                            ? Image.network(
                          widget.photoUrl!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          _imageUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Texto sobre el Logo (Solo visible cuando el frente está hacia nosotros)
                  if (!isBackVisible)
                    Positioned(
                      top: 45,
                      child: SizedBox(
                        width: size * 0.8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.saludo,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [Shadow(blurRadius: 12, color: Colors.black, offset: Offset(2, 2))],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.nombre,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 15, color: Colors.black, offset: Offset(2, 2))],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===============================================
// FONDO ANIMADO
// ===============================================
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