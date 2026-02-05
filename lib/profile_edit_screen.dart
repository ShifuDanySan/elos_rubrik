// profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_register_screen.dart';

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
  String _emailOriginal = ""; // Para comparar si el mail cambió

  // Controllers
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // FocusNodes para navegación con Enter
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
    _dniController.dispose();
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
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _apellidoController.text = data['apellido'] ?? '';
            _emailOriginal = data['email'] ?? ''; // Guardamos el original
            _emailController.text = _emailOriginal;
            _photoUrl = data['photoUrl'];
            _dniController.text = _formatearDni(data['dni'] ?? '');
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nombreFocus.requestFocus();
      });
    }
  }

  String _formatearDni(String dni) {
    if (dni.length != 8) return dni;
    return "${dni.substring(0, 2)}.${dni.substring(2, 5)}.${dni.substring(5, 8)}";
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

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      setState(() {
        _photoUrl = downloadUrl;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto actualizada"), backgroundColor: Colors.green),
      );
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
      // 1. Lógica de Cambio de Email con Verificación Obligatoria
      if (_emailController.text.trim() != _emailOriginal) {
        // Envía el correo de verificación al NUEVO email.
        // El email en Firebase Auth NO cambia hasta que el usuario verifique.
        await user?.verifyBeforeUpdateEmail(_emailController.text.trim());
        emailCambiado = true;
      }

      // 2. Cambio de Password (si se escribió algo)
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text);
      }

      // 3. Actualización en Firestore
      // IMPORTANTE: NO actualizamos el campo 'email' en Firestore todavía.
      // Solo actualizamos nombre y apellido. El mail se actualizará en Firestore
      // la próxima vez que el usuario inicie sesión tras haber verificado.
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        // Notar que omitimos el campo 'email' aquí para que no cambie sin verificar
      });

      if (!mounted) return;

      if (emailCambiado) {
        _mostrarAlertaEmail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarAlertaEmail() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verificación enviada"),
        content: const Text("Se ha enviado un correo de confirmación a tu nueva dirección. El cambio de email solo se hará efectivo cuando lo verifiques."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Vuelve al Home
            },
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3949AB);
    const Color accentColor = Color(0xFFF06292);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración de Perfil"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          const FloatingShapesBackground(),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                padding: const EdgeInsets.all(30),
                child: _buildForm(primaryColor, accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Color primaryColor, Color accentColor) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: (_photoUrl == null || _photoUrl!.isEmpty)
                        ? Icon(Icons.person, size: 60, color: primaryColor.withOpacity(0.5))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _cambiarFoto,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: accentColor,
                      child: _isSaving
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildField(
            controller: _nombreController,
            label: 'Nombre',
            icon: Icons.person_outline,
            focusNode: _nombreFocus,
            nextFocus: _apellidoFocus,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
          ),
          _buildField(
            controller: _apellidoController,
            label: 'Apellido',
            icon: Icons.person_outline,
            focusNode: _apellidoFocus,
            nextFocus: _emailFocus,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
          ),
          _buildField(
            controller: _emailController,
            label: 'Nuevo Email',
            icon: Icons.email_outlined,
            focusNode: _emailFocus,
            nextFocus: _passFocus,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
          ),
          _buildField(
            controller: _dniController,
            label: 'DNI (No editable)',
            icon: Icons.badge_outlined,
            enabled: false,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),

          _buildField(
            controller: _passwordController,
            label: 'Nueva Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            focusNode: _passFocus,
            nextFocus: _confirmPassFocus,
            validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          _buildField(
            controller: _confirmPasswordController,
            label: 'Confirmar Contraseña',
            icon: Icons.lock_open_outlined,
            isPassword: true,
            focusNode: _confirmPassFocus,
            nextFocus: _botonGuardarFocus,
            validator: (v) => (v != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            focusNode: _botonGuardarFocus,
            onPressed: _isSaving ? null : _onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        obscureText: isPassword && !_mostrarPassword,
        keyboardType: keyboardType,
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF3949AB) : Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: !enabled,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_mostrarPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
          ) : null,
        ),
        validator: validator,
      ),
    );
  }
}