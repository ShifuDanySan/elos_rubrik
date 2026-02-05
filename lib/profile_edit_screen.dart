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

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _apellidoFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode();
  final FocusNode _botonGuardarFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    _botonGuardarFocus.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _apellidoController.text = data['apellido'] ?? '';
          _dniController.text = data['dni'] ?? 'No registrado';
          _emailController.text = data['email'] ?? '';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nombreFocus.canRequestFocus) _nombreFocus.requestFocus();
    });
  }

  Future<void> _cambiarFoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 70);
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
      setState(() { _photoUrl = downloadUrl; _isSaving = false; });
    } catch (e) { setState(() => _isSaving = false); }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Actualizar Firestore (Nombre y Apellido)
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
      });
      // Actualizar Password si se escribió algo
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cambios guardados")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Reingresa para cambiar contraseña")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3949AB);
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: primaryColor, foregroundColor: Colors.white),
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
              _buildField(_nombreController, "Nombre", Icons.person, _nombreFocus, _apellidoFocus),
              _buildField(_apellidoController, "Apellido", Icons.person, _apellidoFocus, _passFocus),
              _buildField(_dniController, "DNI", Icons.badge, null, null, enabled: false),
              _buildField(_emailController, "Email", Icons.email, null, null, enabled: false),
              const Divider(height: 40),
              _buildField(_passwordController, "Nueva Contraseña", Icons.lock, _passFocus, _confirmPassFocus, isPass: true),
              _buildField(_confirmPasswordController, "Repetir Contraseña", Icons.lock, _confirmPassFocus, _botonGuardarFocus, isPass: true),
              const SizedBox(height: 30),
              ElevatedButton(
                focusNode: _botonGuardarFocus,
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[200],
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: CircleAvatar(
                radius: 18, backgroundColor: color,
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, FocusNode? current, FocusNode? next, {bool enabled = true, bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        focusNode: current,
        readOnly: !enabled,
        obscureText: isPass && !_mostrarPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3949AB)),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[200],
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