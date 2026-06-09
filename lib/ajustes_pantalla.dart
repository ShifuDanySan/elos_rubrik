import 'package:flutter/material.dart';

class AjustesPantalla with WidgetsBindingObserver {
  static final AjustesPantalla _instance = AjustesPantalla._internal();
  factory AjustesPantalla() => _instance;
  AjustesPantalla._internal();

  VoidCallback? _onResizeCallback;
  bool _isObserverAdded = false;

  void configurarEscucha({
    required BuildContext context,
    required VoidCallback onResize,
  }) {
    _onResizeCallback = onResize;
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }
  }

  @override
  void didChangeMetrics() {
    if (_onResizeCallback != null) {
      _onResizeCallback!();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isObserverAdded = false;
  }
}