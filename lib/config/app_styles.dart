// lib/config/app_styles.dart
import 'package:flutter/material.dart';

class AppStyles {
  // Colores
  static const Color primaryColor = Color(0xFF1E88E5); // Azul medio
  static const Color secondaryColor = Color(0xFFFFC107); // Amarillo
  static const Color accentColor = Color(0xFFD32F2F); // Rojo para acentos
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkText = Color(0xFF212121);
  static const Color lightText = Color(0xFFFFFFFF);

  // Espaciado
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Tipografía
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: darkText,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: darkText,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: darkText,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: lightText,
  );
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: errorColor,
  );

  // Estilo de Botones
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: lightText,
    padding: const EdgeInsets.symmetric(vertical: 14.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    textStyle: buttonText,
    elevation: 5,
  );

  // Tema general de la aplicación
  static ThemeData get lightTheme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: lightText,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: darkText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      labelStyle: const TextStyle(color: darkText),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: const MaterialColor(0xFF1E88E5, <int, Color>{
        50: Color(0xFFE3F2FD), 100: Color(0xFFBBDEFB), 200: Color(0xFF90CAF9),
        300: Color(0xFF64B5F6), 400: Color(0xFF42A5F5), 500: Color(0xFF2196F3),
        600: Color(0xFF1E88E5), 700: Color(0xFF1976D2), 800: Color(0xFF1565C0),
        900: Color(0xFF0D47A1),
      }),
    ).copyWith(secondary: secondaryColor, error: errorColor),
  );
}