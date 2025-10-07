// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elos_rubrik/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Controladores para capturar el texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Clave global para el formulario (necesaria para la validación)
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función principal para iniciar sesión
  void _performLogin(BuildContext context) async {
    // Asegurarse de que el formulario es válido antes de intentar el login
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // 2. Acceder al proveedor de autenticación
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 3. Llamar al método login con los valores de los controladores
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    // 4. Manejo del resultado
    if (success) {
      // Navegación automática: El widget MainApp maneja la navegación
      // al detectar el cambio de authProvider.isLoggedIn a true.
      // Opcionalmente, podrías navegar aquí si no usaras el listener en main.dart:
      // Navigator.of(context).pushReplacementNamed('/home');
      print('Login exitoso. Navegando a Home.');
    } else {
      // 5. Mostrar error si el login falla
      final errorMessage = authProvider.errorMessage ?? "Error desconocido.";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado de carga para habilitar/deshabilitar el botón
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo o Icono de la Aplicación
                Icon(
                  Icons.vpn_key_sharp,
                  size: 100,
                  color: Colors.blueGrey.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 30),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'ejemplo@dominio.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu correo.';
                    }
                    // Validación de email básica (se puede mejorar)
                    if (!value.contains('@')) {
                      return 'Introduce un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu contraseña.';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Botón de Login
                ElevatedButton(
                  onPressed: isLoading ? null : () => _performLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade600,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'INGRESAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Enlace a Registro (funcionalidad pendiente, solo visual)
                TextButton(
                  onPressed: () {
                    // TODO: Implementar navegación a la pantalla de Registro
                    print('Navegando a Registro...');
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate aquí.',
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}