import 'package:flutter/material.dart';

class FormatoTutorial {
  static Widget contenidoAjustado({
    required String paso,
    required String titulo,
    required String mensaje,
    required VoidCallback onSkip,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 12,
              child: Text(
                paso,
                style: const TextStyle(color: Color(0xFF5E35B1), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Divider(color: Colors.white70),
        ),
        Text(
          mensaje,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}