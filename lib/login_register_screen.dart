import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'dart:math' as math; // Necesario para la función seno y coseno en la animación
import 'dart:math'; // Para la generación de números aleatorios

// Constantes de estilo para la coherencia visual
const Color _primaryColor = Color(0xFF3949AB); // Índigo oscuro
const Color _accentColor = Color(0xFF4FC3F7); // Azul cielo brillante para botones secundarios
const Color _backgroundColor = Color(0xFFE1BEE7); // Lila o Malva muy claro (Purple 100)

// ===============================================
// WIDGET AUXILIAR: Fondo Animado Flotante (Floating Shapes)
// ===============================================

class FloatingShapesBackground extends StatefulWidget {
  const FloatingShapesBackground({super.key});

  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground> {
  // Lista que contendrá todas las formas generadas aleatoriamente
  List<Widget> _floatingShapes = [];
  final Random _random = Random();
  // CAMBIO CLAVE: Aumentado el número de figuras de 20 a 60
  final int _numberOfShapes = 60;

  // Guardamos el tamaño anterior para detectar si la pantalla cambió
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    // Ya no generamos las formas aquí, lo haremos en didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtenemos el tamaño actual de la pantalla
    final currentSize = MediaQuery.of(context).size;

    // Comprobamos si el tamaño ha cambiado desde la última vez o si la lista está vacía (primer inicio)
    if (_lastSize == null || _lastSize != currentSize || _floatingShapes.isEmpty) {
      _lastSize = currentSize;
      _generateRandomShapes();
    }
  }

  // Función para generar las formas con valores aleatorios
  void _generateRandomShapes() {
    // IMPORTANTE: Reseteamos la lista antes de generar nuevas formas
    _floatingShapes = [];

    for (int i = 0; i < _numberOfShapes; i++) {
      final bool isSquare = _random.nextBool();
      final double size = 30.0 + _random.nextDouble() * 120.0; // Tamaño entre 30 y 150
      final Color color = _random.nextBool() ? _primaryColor : _accentColor;
      // Duración aleatoria entre 15s y 35s
      final Duration duration = Duration(seconds: 15 + _random.nextInt(20));

      // Coordenadas iniciales aleatorias (usaremos -0.5 a 1.5 para que empiecen y terminen fuera de la vista)
      // Estas posiciones son fijas para cada forma, pero su valor absoluto depende del tamaño de la pantalla
      final double initialX = -0.5 + _random.nextDouble() * 2.0;
      final double initialY = -0.5 + _random.nextDouble() * 2.0;

      _floatingShapes.add(
        PositionedShape(
          key: ValueKey('shape_$i'), // Clave única para Flutter
          initialPositionX: initialX,
          initialPositionY: initialY,
          size: size,
          color: color,
          duration: duration,
          isSquare: isSquare,
        ),
      );
    }
    // Forzamos la reconstrucción del widget para mostrar las nuevas formas
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    // Usamos el LayoutBuilder solo para obtener constraints del padre si fuera necesario,
    // pero MediaQeury.of(context).size ya nos da el tamaño de la ventana.
    // Simplemente devolvemos el Stack con las formas
    return Stack(
      children: [
        // 1. Fondo base de la pantalla (Ahora color lila)
        Container(color: _backgroundColor),

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
  // Posiciones iniciales como porcentaje del tamaño del LayoutBuilder (-0.5 a 1.5)
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

  // Rango de desplazamiento (que tan lejos se moverá del punto inicial)
  final double _motionRange = 100.0;

  @override
  void initState() {
    super.initState();
    // Offset para que las animaciones de seno/coseno no se sincronicen
    _sinOffset = _random.nextDouble() * math.pi * 2;
    _cosOffset = _random.nextDouble() * math.pi * 2;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  // Si las propiedades del widget padre cambian (ej: si cambia la duración de la animación), actualizamos
  @override
  void didUpdateWidget(PositionedShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      // Si la duración de la animación cambia, reseteamos el controlador
      _controller.duration = widget.duration;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Define el movimiento de la forma (movimiento sutil en 2D)
  Offset getMotionOffset(double animationValue) {
    // Crea un movimiento en forma de 8 (combinando seno y coseno con diferentes offsets)
    final dx = math.sin(animationValue * 2 * math.pi + _sinOffset) * _motionRange / 2;
    final dy = math.cos(animationValue * 2 * math.pi + _cosOffset) * _motionRange / 2;
    return Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la ventana actual en cada frame de construcción
    final constraints = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {

        // Calcular la posición inicial absoluta basada en el tamaño actual de la pantalla
        final initialTop = widget.initialPositionY * constraints.height;
        final initialLeft = widget.initialPositionX * constraints.width;

        // Calcular el desplazamiento de la animación
        final motion = getMotionOffset(_controller.value);

        return Positioned(
          // Posición final = Posición Inicial Absoluta + Desplazamiento de la Animación
          top: initialTop + motion.dy,
          left: initialLeft + motion.dx,

          child: Transform.rotate(
            // Rotación más lenta
            angle: _controller.value * math.pi / 2,
            child: Opacity(
              opacity: 0.2 + (_random.nextDouble() * 0.4), // Opacidad más sutil entre 0.2 y 0.6
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  // Opacidad del color base del Container muy baja
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
// FIN WIDGET AUXILIAR: Fondo Animado Flotante
// ===============================================

// NOTE: The LoginRegisterScreen class itself is a StateFulWidget, so it must be a StateFulWidget
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  // Estado para controlar el modo (Login o Registro)
  bool _esLogin = true;
  bool _mostrarPassword = false;
  bool _isLoading = false; // Nuevo estado para el indicador de carga

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final int _tipoUsuarioPorDefecto = 2; // Valor por defecto

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
  }

  // ======================================================================
  // FUNCIÓN _onSubmit() - LÓGICA DE LOGIN Y REGISTRO
  // ======================================================================
  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });
    final dniLimpio = _dniController.text.replaceAll('.', '');
    final password = _passwordController.text;

    // Muestra SnackBar de proceso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_esLogin ? 'Iniciando sesión...' : 'Registrando usuario...'), duration: const Duration(seconds: 5), backgroundColor: _primaryColor),
    );

    try {
      if (_esLogin) {
        // --- LÓGICA DE INICIO DE SESIÓN (LOGIN) ---
        // Simulación: Buscar usuario por DNI y obtener email (esto se debe hacer en Firestore)
        final querySnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('dni', isEqualTo: dniLimpio)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found', message: 'No existe una cuenta registrada con ese DNI.');
        }

        final userEmail = querySnapshot.docs.first.data()['email'] as String;

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail,
          password: password,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // La navegación a Home aquí es opcional si AuthScreen ya lo maneja
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de Sesión Exitoso!'), backgroundColor: Colors.green),
        );

      } else {
        // --- LÓGICA DE REGISTRO ---
        final email = _emailController.text;

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
          'dni': dniLimpio,
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'email': email,
          'tipo_usuario': _tipoUsuarioPorDefecto,
          'fecha_registro': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡REGISTRO EXITOSO! Iniciando sesión...'),
              backgroundColor: Colors.green
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String errorMessage = 'Error de autenticación. Verifique sus credenciales.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Usuario no encontrado. Verifique el DNI.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Contraseña incorrecta. Intente de nuevo.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'El email ya está registrado. Intente iniciar sesión.';
        _cambiarModo();
      } else {
        errorMessage = e.message ?? 'Error desconocido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage'), backgroundColor: Colors.red),
      );
    }
    on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de Firebase: [cloud_firestore/permission-denied] Revise las reglas de la base de datos.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de Firebase: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
    catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // ===============================================
  // WIDGETS DE CONSTRUCCIÓN RESPONSIVE
  // ===============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aplicamos el fondo animado en la capa más baja del Stack
      body: Stack(
        children: [
          // 1. Fondo Animado Flotante
          const FloatingShapesBackground(),

          // 2. Contenido Central (Formulario)
          // Se envuelve Center con un Contenedor para que la tarjeta no use todo el espacio vertical en desktop
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double breakpoint = 600.0;
                if (constraints.maxWidth > breakpoint) {
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

  // El layout de escritorio ahora solo se enfoca en la tarjeta
  Widget _buildDesktopLayout() {
    return Container(
      width: 500, // Ancho fijo para el formulario en escritorio
      // Altura máxima para evitar que ocupe todo el espacio y oculte el fondo
      constraints: const BoxConstraints(maxHeight: 700),
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        // Color blanco sólido para la tarjeta
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Sombra pronunciada para destacar la tarjeta sobre el fondo animado
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: _buildFormContent(),
      ),
    );
  }

  // El layout móvil ahora solo se enfoca en la tarjeta
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: _buildFormContent(),
      ),
    );
  }

  // WIDGET DE CAMPO DE TEXTO ESTILIZADO (Reutilizable)
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool hideCounter = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_mostrarPassword,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: _primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: hideCounter ? '' : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                color: _primaryColor.withOpacity(0.6)
            ),
            onPressed: () {
              setState(() => _mostrarPassword = !_mostrarPassword);
            },
          )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  // CONTENIDO DEL FORMULARIO (Común a ambos layouts)
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            _esLogin ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
            size: 80,
            color: _primaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            _esLogin ? 'INICIA SESIÓN EN ELOS-RUBRIK' : 'CREA TU CUENTA',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // --- CAMPOS DE REGISTRO ---
          if (!_esLogin) ...[
            _buildStyledTextField(
              controller: _nombreController,
              label: 'Nombre',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio.' : null,
            ),
            _buildStyledTextField(
              controller: _apellidoController,
              label: 'Apellido',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty) ? 'El apellido es obligatorio.' : null,
            ),
            _buildStyledTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              isEmail: true,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@')) ? 'Ingrese un email válido.' : null,
            ),
          ],

          // --- CAMPO DNI ---
          _buildStyledTextField(
            controller: _dniController,
            label: 'DNI (ej: 11.222.333)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 10,
            hideCounter: true,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              DniInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.replaceAll('.', '').length != 8) {
                return 'El DNI debe contener 8 dígitos.';
              }
              return null;
            },
          ),

          // --- CAMPO CONTRASEÑA ---
          _buildStyledTextField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (value) => (value == null || value.length < 6) ? 'La contraseña debe tener al menos 6 caracteres.' : null,
          ),

          // --- CAMPO CONFIRMAR CONTRASEÑA ---
          if (!_esLogin) ...[
            _buildStyledTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar Contraseña',
              icon: Icons.lock_open_outlined,
              isPassword: true,
              validator: (value) => (value != _passwordController.text) ? 'Las contraseñas no coinciden.' : null,
            ),
          ],

          const SizedBox(height: 10),

          // --- Botón de Acción Principal ---
          ElevatedButton(
            onPressed: _isLoading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
                : Text(_esLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // --- Botón para cambiar entre Login y Registro ---
          TextButton(
            onPressed: _isLoading ? null : _cambiarModo,
            style: TextButton.styleFrom(
              foregroundColor: _accentColor,
            ),
            child: Text(
              _esLogin ? '¿No tienes cuenta? ¡Regístrate aquí!' : '¿Ya tienes cuenta? ¡Inicia Sesión!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// CLASE AUXILIAR PARA DAR FORMATO AL DNI (XX.XXX.XXX)
// ===============================================

class DniInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 4) {
        if (i != text.length - 1) {
          buffer.write('.');
        }
      }
    }

    final formattedText = buffer.toString();

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}