// lib/screens/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _mostrarPassword = false;
  String? _photoUrl;
  String _emailOriginal = "";

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
  final FocusNode _botonGuardarFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    _botonGuardarFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosActuales() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); //
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _apellidoController.text = data['apellido'] ?? '';
            _emailOriginal = data['email'] ?? '';
            _emailController.text = _emailOriginal;
            _photoUrl = data['photoUrl'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      // Regla: El cursor debe empezar en el primer campo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nombreFocus.canRequestFocus) _nombreFocus.requestFocus();
      });
    }
  }

  Future<void> _cambiarFoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() => _isSaving = true);
      final user = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance.ref().child('perfiles/${user!.uid}.jpg');

      if (kIsWeb) {
        await storageRef.putData(await image.readAsBytes());
      } else {
        await storageRef.putFile(File(image.path));
      }

      final String downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    bool emailCambiado = false;

    try {
      if (_emailController.text.trim() != _emailOriginal) {
        // Actualizar Firestore con la intención de cambio
        await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
          'email': _emailController.text.trim(),
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
        });

        // Enviar link de confirmación
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        emailCambiado = true;
      } else {
        await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
        });
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);
        }
      }

      if (!mounted) return;

      if (emailCambiado) {
        _mostrarAlertaEmailYSalir(); // Aquí se activa la ventana central
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarAlertaEmailYSalir() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirmación Requerida", textAlign: TextAlign.center),
        content: const Text(
          "Se ha enviado un enlace a tu nuevo correo.\n\nPor seguridad, la sesión se cerrará. Deberás hacer click en el enlace que se envió para poder ingresar nuevamente.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Cierre de sesión
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
              padding: const EdgeInsets.symmetric(horizontal: 30),
            ),
            child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3949AB);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(primaryColor),
              const SizedBox(height: 30),
              _buildField(_nombreController, 'Nombre', Icons.person, _nombreFocus, _apellidoFocus),
              _buildField(_apellidoController, 'Apellido', Icons.person, _apellidoFocus, _emailFocus),
              _buildField(_emailController, 'Email', Icons.email, _emailFocus, _passFocus),
              const Divider(height: 40),
              _buildField(_passwordController, 'Nueva Contraseña', Icons.lock, _passFocus, _confirmPassFocus, isPass: true),
              _buildField(_confirmPasswordController, 'Repetir Contraseña', Icons.lock, _confirmPassFocus, _botonGuardarFocus, isPass: true),
              const SizedBox(height: 30),
              ElevatedButton(
                focusNode: _botonGuardarFocus,
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Center(
      child: GestureDetector(
        onTap: _isSaving ? null : _cambiarFoto,
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.grey[300],
          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null ? const Icon(Icons.camera_alt, size: 35, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, FocusNode node, FocusNode? next, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        focusNode: node,
        obscureText: isPass && !_mostrarPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: isPass ? IconButton(
            icon: Icon(_mostrarPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
          ) : null,
        ),
        onFieldSubmitted: (_) => next != null ? FocusScope.of(context).requestFocus(next) : null,
      ),
    );
  }
}