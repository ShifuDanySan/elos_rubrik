import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../managers/session_manager.dart';

// Importa las pantallas que necesitamos
import 'loading_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Enum para manejar el estado de navegación dentro del AuthWrapper
enum AuthFlowState {
  login,
  register,
  forgotPassword,
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Estado para manejar la navegación entre pantallas de autenticación
  AuthFlowState _authFlowState = AuthFlowState.login;

  /// Método para cambiar a la pantalla de Registro
  void _goToRegister() {
    setState(() {
      _authFlowState = AuthFlowState.register;
    });
  }

  /// Método para cambiar a la pantalla de Login
  void _goToLogin() {
    setState(() {
      _authFlowState = AuthFlowState.login;
    });
  }

  /// Método para cambiar a la pantalla de Olvidé Contraseña
  void _goToForgotPassword() {
    setState(() {
      _authFlowState = AuthFlowState.forgotPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el SessionManager
    final sessionManager = Provider.of<SessionManager>(context);

    // 1. Mostrar pantalla de carga si la sesión no se ha inicializado
    if (!sessionManager.isInitialized) {
      // Este estado es necesario para verificar el token/sesión guardada
      return const LoadingScreen(message: 'Cargando sesión...');
    }

    // 2. Si el usuario está autenticado, mostrar la Home Screen
    if (sessionManager.isAuthenticated) {
      // Si está logueado, pasamos el usuario (si no es null) y la función de logout
      return HomeScreen(
        // El usuario está garantizado de ser no-null aquí
        user: sessionManager.currentUser!,
        onLogout: sessionManager.logout,
      );
    }

    // 3. Si el usuario NO está autenticado, gestionar el flujo de autenticación
    else {
      // Mostramos la pantalla correspondiente al estado actual del flujo
      switch (_authFlowState) {
        case AuthFlowState.login:
          return LoginScreen(
            onGoToRegister: _goToRegister,
            onGoToForgotPassword: _goToForgotPassword,
          );

        case AuthFlowState.register:
          return RegisterScreen(
            onGoToLogin: _goToLogin,
            onRegistrationSuccess: _goToLogin, // Vuelve a login después de registrarse
          );

        case AuthFlowState.forgotPassword:
          return ForgotPasswordScreen(
            onGoToLogin: _goToLogin,
          );
      }
    }
  }
}