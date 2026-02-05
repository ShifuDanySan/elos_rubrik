import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'login_register_screen.dart'; // Asegúrate de que FloatingShapesBackground esté aquí

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

  // Controllers
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // FocusNodes para la navegación con Enter
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
    // Dispose FocusNodes
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
            _emailController.text = data['email'] ?? '';
            _photoUrl = data['photoUrl'];
            _dniController.text = _formatearDni(data['dni'] ?? '');
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    } finally {
      // Regla de negocio: El cursor debe empezar en el primer campo
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
        imageQuality: 85,
      );
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Imagen seleccionada. Implementa Firebase Storage para guardarla.")),
        );
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (_emailController.text.trim() != user?.email) {
        await user?.verifyBeforeUpdateEmail(_emailController.text.trim());
      }
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text);
      }
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'email': _emailController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? Icon(Icons.person, size: 60, color: primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _cambiarFoto,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: accentColor,
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
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
            label: 'Email',
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
            padding: EdgeInsets.symmetric(vertical: 20),
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
            label: 'Confirmar Nueva Contraseña',
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