import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import 'dart:math';

import 'auth_helper.dart';

const Color _profilePrimary = Color(0xFF00897B);
const Color _profileAccent = Color(0xFF26C6DA);
const Color _profileBackground = Color(0xFFE0F2F1);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _apellidoFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode();

  String _dniVisual = "";
  String? _photoUrl;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _apellidoController.text = data['apellido'] ?? '';
            _emailController.text = user.email ?? '';
            _dniVisual = data['dni'] ?? '---';

            final rawUrl = data['photoUrl'];
            if (rawUrl != null && rawUrl.isNotEmpty) {
              _photoUrl = "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_pickedFile == null) return _photoUrl;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('perfiles/$uid.jpg');
      final bytes = await _pickedFile!.readAsBytes();
      await storageRef.putData(bytes);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return _photoUrl;
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (_emailController.text.trim() != user?.email) {
        await user?.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text.trim());
      }

      String? finalPhotoUrl = await _uploadImage(user!.uid);

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': finalPhotoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: _profilePrimary),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error: ${e.message}";
      if (e.code == 'requires-recent-login') {
        errorMsg = "Por seguridad, debe reingresar a la aplicación para cambiar estos datos.";
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FloatingShapesBackground(primary: _profilePrimary, accent: _profileAccent),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: _isLoading
                  ? const CircularProgressIndicator(color: _profilePrimary)
                  : _buildFormCard(),
            ),
          ),
          Positioned(
              top: 20,
              left: 15,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: _profilePrimary, size: 28),
                  onPressed: () => Navigator.pop(context)
              )
          ),
          Positioned(top: 20, right: 15, child: AuthHelper.logoutButton(context)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            const SizedBox(height: 12),
            Text("DNI: $_dniVisual", style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(_nombreController, 'Nombre', Icons.person,
                focusNode: _nombreFocus, nextFocus: _apellidoFocus, autofocus: true),
            _buildField(_apellidoController, 'Apellido', Icons.person_outline,
                focusNode: _apellidoFocus, nextFocus: _emailFocus),
            _buildField(_emailController, 'Email', Icons.email,
                isEmail: true, focusNode: _emailFocus, nextFocus: _passFocus),
            const Divider(height: 40),
            const Text("Cambiar Contraseña (opcional)", style: TextStyle(color: _profilePrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildField(_passwordController, 'Nueva Contraseña', Icons.lock_outline,
                isPassword: true, obscure: _obscurePass,
                focusNode: _passFocus, nextFocus: _confirmPassFocus,
                toggleObscure: () => setState(() => _obscurePass = !_obscurePass)),
            _buildField(_confirmPasswordController, 'Confirmar Contraseña', Icons.lock_clock_outlined,
                isPassword: true, isConfirm: true, obscure: _obscureConfirm,
                focusNode: _confirmPassFocus, isLast: true,
                toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _profilePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? img;
    if (_pickedFile != null) {
      img = NetworkImage(_pickedFile!.path);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      img = NetworkImage(_photoUrl!);
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: _profilePrimary, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 65,
            backgroundColor: Colors.white,
            backgroundImage: img,
            child: img == null ? const Icon(Icons.person, size: 60, color: _profilePrimary) : null,
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: CircleAvatar(
            backgroundColor: _profilePrimary,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              onPressed: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool isEmail = false, bool isPassword = false, bool isConfirm = false, bool obscure = false,
        VoidCallback? toggleObscure, FocusNode? focusNode, FocusNode? nextFocus, bool isLast = false, bool autofocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        obscureText: obscure,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else if (isLast) {
            _guardarCambios();
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _profilePrimary),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: toggleObscure) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: (value) {
          if (!isPassword && (value == null || value.isEmpty)) return 'Campo requerido';
          if (isEmail && !value!.contains('@')) return 'Email inválido';
          if (isPassword && value!.isNotEmpty && value.length < 6) return 'Mínimo 6 caracteres';
          if (isConfirm && value != _passwordController.text) return 'Las contraseñas no coinciden';
          return null;
        },
      ),
    );
  }
}

class FloatingShapesBackground extends StatefulWidget {
  final Color primary;
  final Color accent;
  const FloatingShapesBackground({super.key, required this.primary, required this.accent});
  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground> {
  final List<Widget> _floatingShapes = [];
  final Random _random = Random();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_floatingShapes.isEmpty) {
      for (int i = 0; i < 25; i++) {
        _floatingShapes.add(PositionedShape(
          size: 40.0 + _random.nextDouble() * 120.0,
          color: _random.nextBool() ? widget.primary : widget.accent,
          duration: Duration(seconds: 10 + _random.nextInt(20)),
          isSquare: _random.nextBool(),
          initialX: _random.nextDouble(),
          initialY: _random.nextDouble(),
        ));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack(children: [Container(color: _profileBackground), ..._floatingShapes]);
  }
}

class PositionedShape extends StatefulWidget {
  final double size, initialX, initialY;
  final Color color;
  final Duration duration;
  final bool isSquare;
  const PositionedShape({super.key, required this.size, required this.color, required this.duration, required this.isSquare, required this.initialX, required this.initialY});
  @override
  State<PositionedShape> createState() => _PositionedShapeState();
}

class _PositionedShapeState extends State<PositionedShape> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: widget.initialY * screenSize.height + (math.sin(_controller.value * 2 * math.pi) * 30),
          left: widget.initialX * screenSize.width + (math.cos(_controller.value * 2 * math.pi) * 30),
          child: Opacity(
            opacity: 0.1,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.isSquare ? 16 : widget.size / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}