import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFE1BEE7);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _keyAvatar = GlobalKey();
  final GlobalKey _keyCamposFijos = GlobalKey();
  final GlobalKey _keyBotonGuardar = GlobalKey();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _mostrarPassword = false;
  String? _photoUrl;

  Uint8List? _imageDataWeb;
  File? _imageFileMobile;

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
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Iniciar el bucle con pausa
    _iniciarAnimacionConPausa();

    WidgetsBinding.instance.addObserver(this);
    _cargarDatos();
  }

  // Lógica para reducir el tiempo de espera entre vueltas
  void _iniciarAnimacionConPausa() async {
    while (mounted) {
      await _animController.forward(from: 0.0);
      // Aquí controlas el tiempo de espera (reducido a 200ms)
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeMetrics() => TutorialHelper().forceClose();

  String _formatearDNI(String dniRaw) {
    String numeros = dniRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 8) return '${numeros.substring(0, 2)}.${numeros.substring(2, 5)}.${numeros.substring(5, 8)}';
    if (numeros.length == 7) return '${numeros.substring(0, 1)}.${numeros.substring(1, 4)}.${numeros.substring(4, 7)}';
    return numeros;
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
          _dniController.text = _formatearDNI(data['dni'] ?? '');
          _emailController.text = data['email'] ?? '';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cambiarFoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
      if (image == null) return;

      setState(() => _isSaving = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance.ref().child('perfiles/${user.uid}.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes);
        setState(() => _imageDataWeb = bytes);
      } else {
        final file = File(image.path);
        await storageRef.putFile(file);
        setState(() => _imageFileMobile = file);
      }

      final String downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({'photoUrl': downloadUrl});
      setState(() => _photoUrl = downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
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
      if (_passwordController.text.isNotEmpty) await user.updatePassword(_passwordController.text.trim());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: _primaryColor, foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 90, color: _primaryColor, child: Center(child: _buildAvatar())),
            Card(margin: const EdgeInsets.all(16), child: Padding(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
              _buildField(_nombreController, "Nombre", Icons.person_outline, _nombreFocus, _apellidoFocus),
              _buildField(_apellidoController, "Apellido", Icons.person_outline, _apellidoFocus, _passFocus),
              _buildField(_dniController, "DNI", Icons.badge_outlined, null, null, enabled: false),
              _buildField(_emailController, "Email", Icons.email_outlined, null, null, enabled: false),
              const SizedBox(height: 20),
              ElevatedButton(key: _keyBotonGuardar, onPressed: _isSaving ? null : _onSave, child: _isSaving ? const CircularProgressIndicator() : const Text("GUARDAR CAMBIOS")),
            ])))),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() => GestureDetector(key: _keyAvatar, onTap: _isSaving ? null : _cambiarFoto, child: CircleAvatar(radius: 38, backgroundColor: Colors.white, child: ClipOval(child: _buildImageWidget())));

  Widget _buildImageWidget() {
    if (kIsWeb && _imageDataWeb != null) return Image.memory(_imageDataWeb!, width: 76, height: 76, fit: BoxFit.cover);
    if (!kIsWeb && _imageFileMobile != null) return Image.file(_imageFileMobile!, width: 76, height: 76, fit: BoxFit.cover);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) return Image.network(_photoUrl!, width: 76, height: 76, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person));
    return const Icon(Icons.person, size: 40);
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, FocusNode? current, FocusNode? next, {bool enabled = true}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: ctrl, enabled: enabled, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))));
}