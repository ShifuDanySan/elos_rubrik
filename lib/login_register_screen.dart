import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'dart:math' as math;
import 'dart:math';

// Constantes de estilo
const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);
const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

// ===============================================
// WIDGET AUXILIAR: Fondo Estático de Figuras Fijas
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
      final double initialX = -0.5 + _random.nextDouble() * 2.0;
      final double initialY = -0.5 + _random.nextDouble() * 2.0;
      final double staticRotation = _random.nextDouble() * math.pi / 2;
      final double staticOpacity = 0.2 + (_random.nextDouble() * 0.4);

      _floatingShapes.add(
        PositionedShape(
          key: ValueKey('shape_$i'),
          initialPositionX: initialX,
          initialPositionY: initialY,
          size: size,
          color: color,
          isSquare: isSquare,
          rotation: staticRotation,
          opacity: staticOpacity,
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

class PositionedShape extends StatelessWidget {
  final double size;
  final Color color;
  final bool isSquare;
  final double initialPositionX;
  final double initialPositionY;
  final double rotation;
  final double opacity;

  const PositionedShape({
    super.key,
    required this.size,
    required this.color,
    required this.isSquare,
    required this.initialPositionX,
    required this.initialPositionY,
    required this.rotation,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final constraints = MediaQuery.of(context).size;
    final initialTop = initialPositionY * constraints.height;
    final initialLeft = initialPositionX * constraints.width;

    return Positioned(
      top: initialTop,
      left: initialLeft,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isSquare ? 15.0 : size / 2),
            ),
          ),
        ),
      ),
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

class _LoginRegisterScreenState extends State<LoginRegisterScreen> with SingleTickerProviderStateMixin {
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

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFieldFocusNode.requestFocus();
    });

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(_blinkController);
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
    _blinkController.dispose();
    super.dispose();
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

  void _mostrarInfoPagina() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "¡BIENVENIDO A ELOS!",
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text(
                "Estás en una plataforma moderna diseñada para la evaluación por competencias, en la cual puedes optar por utilizar Rúbricas Tradicionales o Rúbricas Difusas, según tus necesidades pedagógicas.",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text("¿Qué puedes hacer como docente en ELOS?"),
              const SizedBox(height: 10),
              _bulletPoint("Doble Metodología: diseña y evalúa con rúbricas tradicionales de niveles fijos, o aprovecha la flexibilidad del modelo difuso."),
              _bulletPoint("Potencia de la Lógica Difusa: califica en una escala continua de 0.00 a 10 mediante controles deslizantes (sliders), capturando matices sutiles del aprendizaje, sin encasillar al estudiante en notas o niveles rígidos."),
              _bulletPoint("Creación Ágil y Simplificada: las rúbricas difusas facilitan la configuración de criterios y descriptores, al definir un único rango continuo de puntuación (un sólo nivel por defecto)."),
              _bulletPoint("Gestión Masiva/Individual de Alumnos: importa listados completos directamente desde archivos Excel para agilizar el proceso administrativo, o ingresa manualmente los datos de un alumno, según la situación lo requiera."),
              _bulletPoint("Historial y Exportación PDF: consulta evaluaciones anteriores guardadas en la nube, y genera reportes oficiales en formato PDF para tus estudiantes."),
              const SizedBox(height: 15),
              const Text(
                "¡Aprovecha el poder del modelo difuso para transformar la subjetividad del aprendizaje en una calificación justa, precisa y verdaderamente representativa!",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo enviado. Revisa tu bandeja de entrada.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No se pudo enviar el correo de recuperación.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('ENVIAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarAvisoRegistroExitoso(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¡Correo de Verificación Enviado!', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 60, color: _primaryColor),
            const SizedBox(height: 15),
            Text(
              'Hemos enviado un correo de verificación a:\n\n$email\n\nPor favor, ingresa a tu casilla de correo para confirmar tu cuenta antes de iniciar sesión.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () {
                Navigator.pop(context);
                _cambiarModo();
              },
              child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAvisoEmailNoVerificado(String email, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Correo No Verificado', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
            const SizedBox(height: 15),
            Text(
              'Aún no has verificado tu correo electrónico ($email).\n\nRevisa tu bandeja de entrada o spam para activar tu cuenta.',
              textAlign: TextAlign.center,
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
              Navigator.pop(context);
              setState(() { _isLoading = true; });
              try {
                UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
                await userCred.user?.sendEmailVerification();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo de verificación reenviado exitosamente.'), backgroundColor: Colors.green),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo reenviar el correo. Inténtalo de nuevo.'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() { _isLoading = false; });
              }
            },
            child: const Text('REENVIAR CORREO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoConfirmacionRegistro() {
    final email = _emailController.text.trim();
    final dniLimpio = _dniController.text.replaceAll('.', '').trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Aviso de Registro',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 55, color: _primaryColor),
              const SizedBox(height: 15),
              Text(
                'Se registrará la cuenta asociada a:\n\n$email\n(DNI: $dniLimpio)\n\nSe enviará un correo electrónico de verificación que deberás confirmar antes de poder ingresar a la plataforma.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () {
                Navigator.pop(dialogContext);
                _procesarRegistroBackend();
              },
              child: const Text('CONFIRMAR Y REGISTRAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarRegistroBackend() async {
    setState(() { _isLoading = true; });
    final email = _emailController.text.trim();
    final exito = await _ejecutarRegistroBackend();
    if (mounted) setState(() { _isLoading = false; });
    if (mounted && exito) {
      _mostrarAvisoRegistroExitoso(email);
    }
  }

  Future<bool> _ejecutarRegistroBackend() async {
    final dniLimpio = _dniController.text.replaceAll('.', '').trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    try {
      // Validar DNI duplicado
      final queryDni = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('dni', isEqualTo: dniLimpio)
          .limit(1)
          .get();

      if (queryDni.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'dni-already-in-use',
          message: 'El DNI ingresado ya se encuentra registrado por otro usuario.',
        );
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Envío de email de verificación
      await userCredential.user!.sendEmailVerification();

      // Registro en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
        'dni': dniLimpio,
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'email': email,
        'tipo_usuario': _tipoUsuarioPorDefecto,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return false;
      String mensajeError;
      switch (e.code) {
        case 'email-already-in-use':
          mensajeError = 'Este correo electrónico ya está en uso.';
          break;
        case 'weak-password':
          mensajeError = 'La contraseña debe tener al menos 6 caracteres.';
          break;
        case 'invalid-email':
          mensajeError = 'El formato del correo electrónico no es válido.';
          break;
        case 'dni-already-in-use':
          mensajeError = e.message ?? 'El DNI ya se encuentra registrado.';
          break;
        default:
          mensajeError = 'Error al procesar el registro. Verifica tus datos.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión o datos inválidos.'), backgroundColor: Colors.red),
      );
      return false;
    }
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

    if (!_esLogin) {
      _mostrarDialogoConfirmacionRegistro();
      return;
    }

    setState(() { _isLoading = true; });

    final dniLimpio = _dniController.text.replaceAll('.', '').trim();
    final password = _passwordController.text;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('dni', isEqualTo: dniLimpio)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'No existe una cuenta registrada con ese DNI.');
      }

      final userEmail = querySnapshot.docs.first.data()['email'] as String;
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: userEmail, password: password);

      // Verificación de Email al iniciar sesión
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _mostrarAvisoEmailNoVerificado(userEmail, password);
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensajeError;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          mensajeError = 'DNI o contraseña incorrectos.';
          break;
        case 'user-disabled':
          mensajeError = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'too-many-requests':
          mensajeError = 'Demasiados intentos. Inténtalo más tarde.';
          break;
        default:
          mensajeError = 'Error al procesar la solicitud. Verifica tus datos.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.red)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión o datos inválidos.'), backgroundColor: Colors.red)
      );
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
      constraints: const BoxConstraints(maxHeight: 900),
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
          FadeTransition(
            opacity: _blinkAnimation,
            child: Column(
              children: [
                const Text(
                  "INFORMACIÓN DE LA PÁGINA",
                  style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  iconSize: 85,
                  icon: const Icon(Icons.login_rounded, color: _primaryColor),
                  onPressed: _mostrarInfoPagina,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
          const SizedBox(height: 15),
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