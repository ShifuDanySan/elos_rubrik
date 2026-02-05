import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_helper.dart';

// Volvemos a tus constantes de estilo originales
const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);

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
          _dniController.text = data['dni'] ?? '';
          _emailController.text = data['email'] ?? '';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
      }
    }
    // El cursor empieza en el primer campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nombreFocus.canRequestFocus) _nombreFocus.requestFocus();
    });
  }

  Future<void> _cambiarFoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
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
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
      });
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar cambios"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          AuthHelper.logoutButton(context),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        // Compactamos para evitar el scroll innecesario
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
              ),
              child: Center(child: _buildAvatar()),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 500, // Ancho igual a login_register_screen
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 15, 24, 15),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildField(_nombreController, "Nombre", Icons.person_outline, _nombreFocus, _apellidoFocus),
                          _buildField(_apellidoController, "Apellido", Icons.person_outline, _apellidoFocus, _passFocus),
                          _buildField(_dniController, "DNI", Icons.badge_outlined, null, null, enabled: false),
                          _buildField(_emailController, "Email", Icons.email_outlined, null, null, enabled: false),
                          const Divider(height: 25, thickness: 1),
                          _buildField(_passwordController, "Nueva Contraseña", Icons.lock_outline, _passFocus, _confirmPassFocus, isPass: true),
                          _buildField(_confirmPasswordController, "Confirmar Contraseña", Icons.lock_open_outlined, _confirmPassFocus, _botonGuardarFocus, isPass: true,
                              validator: (v) => (v != _passwordController.text) ? 'No coinciden' : null),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            focusNode: _botonGuardarFocus,
                            onPressed: _isSaving ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isSaving ? null : _cambiarFoto,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null ? const Icon(Icons.person, size: 40, color: _primaryColor) : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: _accentColor,
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, FocusNode? current, FocusNode? next, {bool enabled = true, bool isPass = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        focusNode: current,
        readOnly: !enabled,
        obscureText: isPass && !_mostrarPassword,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: isPass ? IconButton(
            icon: Icon(_mostrarPassword ? Icons.visibility : Icons.visibility_off, size: 22),
            onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
          ) : null,
        ),
        validator: validator,
        onFieldSubmitted: (_) => next != null ? FocusScope.of(context).requestFocus(next) : null,
      ),
    );
  }
}