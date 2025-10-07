// lib/config/app_config.dart

class AppConfig {
  // Asegúrate de usar la IP de tu red local si estás probando en un emulador
  // y tu API está corriendo en tu máquina (ej: 192.168.1.X)
  // O usa http://10.0.2.2:PORT si usas un emulador de Android (para localhost).
  // ¡CAMBIA ESTA URL POR LA TUYA!
  static const String _baseUrl = 'http://192.168.1.100:8080/api/v1';

  static String get baseUrl => _baseUrl;

  /// Método de inicialización (simplemente una llamada de conveniencia)
  static void initialize() {
    // Aquí puedes añadir lógica de configuración si la necesitas en el futuro.
    // Por ahora, solo asegura que la clase ha sido importada correctamente.
    print('AppConfig inicializada. Base URL: $_baseUrl');
  }
}