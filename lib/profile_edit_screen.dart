// profile_edit_screen.dart
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
  final TextEditingController _dniController = TextEditingController();
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
        // 1. FORZAR ACTUALIZACIÓN: Detecta si el link de confirmación ya fue pulsado
        await user.reload();
        final userActualizado = FirebaseAuth.instance.currentUser;
        final emailDeAuth = userActualizado?.email;

        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userActualizado!.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          String emailEnFirestore = data['email'] ?? '';

          // 2. SINCRONIZACIÓN AUTOMÁTICA AL VUELO:
          // Si Auth ya cambió por el link pero Firestore tiene el viejo, corregimos la BD ahora mismo.
          if (emailDeAuth != null && emailDeAuth != emailEnFirestore) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userActualizado.uid)
                .update({'email': emailDeAuth});

            emailEnFirestore = emailDeAuth;
            debugPrint("Firestore sincronizado con el nuevo email confirmado.");
          }

          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _apellidoController.text = data['apellido'] ?? '';
            _emailOriginal = emailEnFirestore;
            _emailController.text = _emailOriginal;
            _photoUrl = data['photoUrl'];
            _dniController.text = _formatearDni(data['dni'] ?? '');
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al sincronizar datos: $e");
    } finally {
      // Regla: El cursor debe empezar en el primer campo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nombreFocus.canRequestFocus) {
          _nombreFocus.requestFocus();
        }
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

    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir imagen: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    bool emailCambiado = false;

    try {
      // Cambio de Email: Envía verificación
      if (_emailController.text.trim() != _emailOriginal) {
        await user?.verifyBeforeUpdateEmail(_emailController.text.trim());
        emailCambiado = true;
      }

      // Cambio de Password
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text);
      }

      // Actualizamos Nombre y Apellido
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
      });

      if (!mounted) return;

      if (emailCambiado) {
        _mostrarAlertaEmail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados con éxito'), backgroundColor: Colors.green),
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
      builder: (context) {
        final FocusNode botonFocus = FocusNode();
        Future.delayed(Duration.zero, () => botonFocus.requestFocus());

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Confirmación Pendiente", textAlign: TextAlign.center),
          content: const Text(
            "Se ha enviado un correo de verificación. El cambio en la base de datos se hará automáticamente la próxima vez que entres aquí tras confirmar el enlace.",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              focusNode: botonFocus,
              onPressed: () {
                Navigator.pop(context); // Cierra Dialog
                Navigator.pop(context); // Vuelve atrás
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3949AB)),
              child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3949AB);
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil"), backgroundColor: primaryColor, foregroundColor: Colors.white),
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
              const Divider(),
              _buildField(_passwordController, 'Nueva Contraseña', Icons.lock, _passFocus, _confirmPassFocus, isPass: true),
              _buildField(_confirmPasswordController, 'Repetir Contraseña', Icons.lock, _confirmPassFocus, _botonGuardarFocus, isPass: true),
              const SizedBox(height: 20),
              ElevatedButton(
                focusNode: _botonGuardarFocus,
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: primaryColor,
                ),
                child: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white)),
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
        onTap: _cambiarFoto,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null ? const Icon(Icons.camera_alt, size: 30) : null,
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