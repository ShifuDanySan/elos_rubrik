import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar Firebase
import 'package:flutter/services.dart'; // Para el método de simulación

import 'package:elos_rubrik/main.dart'; // Asegúrate que la ruta sea correcta

// --- INICIALIZACIÓN DE FIREBASE SIMULADA PARA PRUEBAS ---
// Simula la inicialización de Firebase Core para que las pruebas no fallen
// si tu main.dart es asíncrono.
void setupFirebaseEmulator() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Simular el manejo de canales de método para Firebase Core.
  // Esto evita que Flutter intente comunicarse con Firebase en un entorno que no lo soporta.
  MethodChannel('plugins.flutter.io/firebase_core').setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'test-api-key',
            'appId': 'test-app-id',
            'messagingSenderId': 'test-sender-id',
            'projectId': 'test-project-id',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return {'name': methodCall.arguments['appName'], 'options': methodCall.arguments['options']};
    }
    return null;
  });
}
// -------------------------------------------------------------

void main() {
  // Configura Firebase antes de ejecutar cualquier prueba
  setupFirebaseEmulator();

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Aquí usamos const MyApp() con el constructor corregido de main.dart
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}