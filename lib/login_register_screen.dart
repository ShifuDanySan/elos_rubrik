// login_register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'dart:math' as math;
import 'dart:math';
import 'package:video_player/video_player.dart';

// Constantes de estilo
const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);

// ===============================================
// WIDGET AUXILIAR: Video Splash (Corrección de Ruta)
// ===============================================

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  // Verificamos que la ruta sea assets/gif/ como en tu captura
  final List<String> _videos = [
    'assets/gif/astronauta_espacio.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _playRandomVideo();
  }

  void _playRandomVideo() {
    final randomVideo = _videos[Random().nextInt(_videos.length)];

    _controller = VideoPlayerController.asset(randomVideo)
      ..initialize().then((_) {
        // Mute para asegurar que Chrome/Web no bloquee el inicio
        _controller.setVolume(0.0);
        _controller.setLooping(false);
        _controller.play();
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      }).catchError((error) {
        print("Error cargando video: $error");
        // Si falla el video, saltamos al Home para no trabar al usuario
        _navigateToHome();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          _controller.value.duration != Duration.zero) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Imagen de fondo (solo se ve mientras el video carga)
          SizedBox.expand(
            child: Image.asset(
              'assets/images/unnamed.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 2. Video (solo aparece si se inicializó correctamente)
          if (_initialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          // 3. Indicador de carga sutil sobre la imagen
          if (!_initialized)
            const CircularProgressIndicator(color: Colors.white),
        ],
      ),
    );
  }
}

// ===============================================
// WIDGET AUXILIAR: Fondo Animado Flotante
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: _backgroundColor),
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
  final double _motionRange = 100.0;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset getMotionOffset(double animationValue) {
    final dx = math.sin(animationValue * 2 * math.pi + _sinOffset) * _motionRange / 2;
    final dy = math.cos(animationValue * 2 * math.pi + _cosOffset) * _motionRange / 2;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final constraints = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final initialTop = widget.initialPositionY * constraints.height;
        final initialLeft = widget.initialPositionX * constraints.width;
        final motion = getMotionOffset(_controller.value);

        return Positioned(
          top: initialTop + motion.dy,
          left: initialLeft + motion.dx,
          child: Transform.rotate(
            angle: _controller.value * math.pi / 2,
            child: Opacity(
              opacity: 0.2 + (_random.nextDouble() * 0.4),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.3),
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
// PANTALLA PRINCIPAL: Login & Registro
// ===============================================

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool _esLogin = true;
  bool _mostrarPassword = false;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _firstFieldFocusNode = FocusNode();
  final int _tipoUsuarioPorDefecto = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    _firstFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _mostrarRecuperarPassword() async {
    final TextEditingController _resetEmailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Recuperar Acceso', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el correo electrónico asociado a tu cuenta para restablecer tu contraseña.'),
            const SizedBox(height: 20),
            TextField(
              controller: _resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () async {
              final email = _resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, ingresa un correo válido')),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mail enviado. Revisa tu correo.'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al enviar el correo.')),
                );
              }
            },
            child: const Text('ENVIAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cambiarModo() {
    setState(() {
      _esLogin = !_esLogin;
      _mostrarPassword = false;
    });
    _formKey.currentState?.reset();
    _dniController.clear();
    _passwordController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    _emailController.clear();
    _confirmPasswordController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFieldFocusNode.requestFocus();
    });
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    await FirebaseAuth.instance.signOut();

    final dniLimpio = _dniController.text.replaceAll('.', '');
    final password = _passwordController.text;

    try {
      if (_esLogin) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('dni', isEqualTo: dniLimpio)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found', message: 'No existe una cuenta registrada con ese DNI.');
        }

        final userEmail = querySnapshot.docs.first.data()['email'] as String;
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: userEmail, password: password);
      } else {
        final email = _emailController.text;
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
          'dni': dniLimpio,
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'email': email,
          'tipo_usuario': _tipoUsuarioPorDefecto,
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      // NAVEGACIÓN AL VIDEO SPLASH
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const VideoSplashScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FloatingShapesBackground(),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      width: 500,
      constraints: const BoxConstraints(maxHeight: 850),
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 35, offset: const Offset(0, 15))],
      ),
      child: SingleChildScrollView(child: _buildFormContent()),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(24.0),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int? maxLength,
    bool hideCounter = false,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !_mostrarPassword,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLength: maxLength,
        scrollPadding: const EdgeInsets.only(bottom: 100),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.white,
          counterText: hideCounter ? '' : null,
          suffixIcon: isPassword
              ? IconButton(
            focusNode: FocusNode(canRequestFocus: false),
            icon: Icon(_mostrarPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
          )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(_esLogin ? Icons.login_rounded : Icons.person_add_alt_1_rounded, size: 80, color: _primaryColor),
          const SizedBox(height: 10),
          if (_esLogin) ...[
            const Text(
              'INICIA SESIÓN EN ELOS-RUBRIK',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryColor),
              textAlign: TextAlign.center,
            ),
            const Text(
              'TU GESTOR ESPECIALIZADO EN RÚBRICAS BASADAS EN LÓGICA DIFUSA',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _accentColor, letterSpacing: 0.8),
              textAlign: TextAlign.center,
            ),
          ] else
            const Text(
              'CREA TU CUENTA',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryColor),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 30),

          if (!_esLogin) ...[
            _buildStyledTextField(
                controller: _nombreController,
                label: 'Nombre',
                icon: Icons.person_outline,
                focusNode: _firstFieldFocusNode,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null),
            _buildStyledTextField(
                controller: _apellidoController,
                label: 'Apellido',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null),
            _buildStyledTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null),
          ],

          _buildStyledTextField(
            controller: _dniController,
            label: 'DNI (ej: 11.222.333)',
            icon: Icons.badge_outlined,
            focusNode: _esLogin ? _firstFieldFocusNode : null,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 10,
            hideCounter: true,
            formatters: [FilteringTextInputFormatter.digitsOnly, DniInputFormatter()],
            validator: (v) => (v == null || v.replaceAll('.', '').length != 8) ? 'DNI debe tener 8 dígitos' : null,
          ),

          _buildStyledTextField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            textInputAction: _esLogin ? TextInputAction.go : TextInputAction.next,
            onSubmitted: (v) {
              if (_esLogin) {
                _onSubmit();
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),

          if (_esLogin)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: TextButton(
                  onPressed: _mostrarRecuperarPassword,
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: _primaryColor, fontSize: 13)),
                ),
              ),
            ),

          if (!_esLogin) ...[
            _buildStyledTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar Contraseña',
              icon: Icons.lock_open_outlined,
              isPassword: true,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _onSubmit(),
              validator: (v) => (v != _passwordController.text) ? 'No coinciden' : null,
            ),
          ],

          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_esLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _isLoading ? null : _cambiarModo,
            child: Text(_esLogin ? '¿No tienes cuenta? ¡Regístrate!' : '¿Ya tienes cuenta? ¡Entra!'),
          ),
        ],
      ),
    );
  }
}

class DniInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 4) && i != text.length - 1) buffer.write('.');
    }
    final formattedText = buffer.toString();
    return newValue.copyWith(text: formattedText, selection: TextSelection.collapsed(offset: formattedText.length));
  }
}