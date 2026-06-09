import 'package:flutter/material.dart';
import 'crear_rubrica_screen.dart';
import 'lista_rubricas_screen.dart';
import 'lista_evaluaciones_screen.dart';
import 'profile_edit_screen.dart';
import 'dart:math' as math;
import 'dart:math';
import 'auth_helper.dart';
import 'tutorial_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color _primaryColor = Color(0xFF5E35B1);
const Color _accentColor = Color(0xFFF06292);
const Color _homeBackgroundColor = Color(0xFFEDE7F6);
const String _imageUrl = 'assets/images/logo-elos.jpg';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _nombreUsuario = "";
  String? _photoUrl;
  bool _isLoading = true;
  final String __app_id = 'rubrica_evaluator';

  final GlobalKey _keyBanner = GlobalKey();
  final GlobalKey _keyOpciones = GlobalKey();
  final GlobalKey _keyPerfil = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    TutorialHelper().forceClose();
  }

  void _lanzarTutorialManual() {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'HOME',
      keys: {
        'banner': _keyBanner,
        'opciones': _keyOpciones,
        'perfil': _keyPerfil,
      },
      force: true,
    );
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        String? firestorePhoto;
        String firestoreName = "";

        if (doc.exists) {
          final data = doc.data()!;
          firestoreName = "${data['nombre'] ?? ''} ${data['apellido'] ?? ''}".trim();
          firestorePhoto = data['photoUrl'];
        }

        setState(() {
          _nombreUsuario = firestoreName.isNotEmpty
              ? firestoreName
              : (user.displayName ?? "USUARIO");

          _photoUrl = (firestorePhoto != null && firestorePhoto.isNotEmpty)
              ? firestorePhoto
              : user.photoURL;

          _isLoading = false;
        });
      }
    } catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _nombreUsuario = user?.displayName ?? "USUARIO";
        _photoUrl = user?.photoURL;
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
    final snapshot = await FirebaseFirestore.instance.collection('artifacts/$__app_id/users/${user.uid}/rubricas').limit(1).get();
    if (snapshot.docs.isEmpty) {
      _mostrarDialogoInformativo("No hay rúbricas", "Crea una nueva para gestionar.");
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListaRubricasScreen()));
    }
  }

  Future<void> _verificarYEntrarAEvaluaciones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance.collection('artifacts/$__app_id/users/${user.uid}/evaluaciones').limit(1).get();
    if (snapshot.docs.isEmpty) {
      _mostrarDialogoInformativo("Sin evaluaciones", "No se han encontrado evaluaciones.");
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListaEvaluacionesScreen()));
    }
  }

  void _mostrarDialogoInformativo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.info_outline, size: 50, color: _primaryColor),
        content: Text(mensaje, textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elos-Rubrik'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TutorialHelper.helpButton(context, _lanzarTutorialManual),
          GestureDetector(
            key: _keyPerfil,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileEditScreen())).then((_) => _cargarDatosUsuario()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                    ? ClipOval(
                  child: Image.network(
                    _photoUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.account_circle, color: Colors.white);
                    },
                  ),
                )
                    : const Icon(Icons.account_circle, color: Colors.white),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        key: _keyBanner,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoinFlipLogo(
                              photoUrl: _photoUrl,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isLoading ? 'CARGANDO...' : _obtenerSaludoPorHora(),
                              style: const TextStyle(color: _primaryColor, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _nombreUsuario.toUpperCase(),
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      key: _keyOpciones,
                      children: [
                        _buildMenuCard('Crear Nueva Rúbrica', 'Diseña criterios.', Icons.edit_note_sharp, const Color(0xFF7E57C2), () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CrearRubricaScreen()))),
                        _buildMenuCard('Gestionar y Evaluar', 'Usa tus rúbricas creadas.', Icons.rule_sharp, const Color(0xFF66BB6A), _verificarYEntrarALista),
                        _buildMenuCard('Mis Evaluaciones', 'Historial de notas.', Icons.bar_chart_sharp, const Color(0xFFEF5350), _verificarYEntrarAEvaluaciones),
                      ],
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

  Widget _buildMenuCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// --- CLASES DE SOPORTE PARA ANIMACIONES ---

class CoinFlipLogo extends StatefulWidget {
  final String? photoUrl;
  const CoinFlipLogo({super.key, this.photoUrl});
  @override State<CoinFlipLogo> createState() => _CoinFlipLogoState();
}

class _CoinFlipLogoState extends State<CoinFlipLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0.0;

  @override void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _startTimer();
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        double nextAngle = _currentAngle - math.pi;
        setState(() {
          _animation = Tween<double>(begin: _currentAngle, end: nextAngle).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
        });
        await _controller.forward(from: 0);
        _currentAngle = nextAngle;
      }
    }
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    const double size = 300;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double angle = _animation.value;
        final double normalizedAngle = angle.abs() % (2 * math.pi);
        final bool isBackVisible = normalizedAngle > math.pi / 2 && normalizedAngle < 1.5 * math.pi;

        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
          alignment: Alignment.center,
          child: Container(
            width: size, height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isBackVisible) Image.asset(_imageUrl, width: size, height: size, fit: BoxFit.cover),
                  if (isBackVisible) Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                        ? Image.network(
                      widget.photoUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback automático si el link de almacenamiento guardado está roto o corrupto
                        return Image.asset(_imageUrl, width: size, height: size, fit: BoxFit.cover);
                      },
                    )
                        : Image.asset(_imageUrl, width: size, height: size, fit: BoxFit.cover),
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

class FloatingShapesBackground extends StatefulWidget {
  const FloatingShapesBackground({super.key});

  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground> {
  List<Widget> _staticShapes = [];
  final Random _random = Random();
  final int _numberOfShapes = 30;
  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.of(context).size;
    if (_lastSize == null || _lastSize != currentSize || _staticShapes.isEmpty) {
      _lastSize = currentSize;
      _generateStaticShapes();
    }
  }

  void _generateStaticShapes() {
    _staticShapes = [];
    for (int i = 0; i < _numberOfShapes; i++) {
      final double size = 30.0 + _random.nextDouble() * 100;
      final Color color = _random.nextBool() ? _primaryColor : _accentColor;
      final bool isSquare = _random.nextBool();
      final double posX = _random.nextDouble();
      final double posY = _random.nextDouble();

      _staticShapes.add(
        PositionedShape(
          key: ValueKey('static_shape_$i'),
          size: size,
          color: color,
          isSquare: isSquare,
          initialPositionX: posX,
          initialPositionY: posY,
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
        ..._staticShapes,
      ],
    );
  }
}

class PositionedShape extends StatelessWidget {
  final double size, initialPositionX, initialPositionY;
  final Color color;
  final bool isSquare;

  const PositionedShape({
    super.key,
    required this.size,
    required this.color,
    required this.isSquare,
    required this.initialPositionX,
    required this.initialPositionY,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      top: initialPositionY * screenSize.height,
      left: initialPositionX * screenSize.width,
      child: Opacity(
        opacity: 0.15,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isSquare ? 12 : size / 2),
          ),
        ),
      ),
    );
  }
}