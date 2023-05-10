import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';



class MotionHandler {
  final Function(Offset) onPositionChanged;
  late StreamSubscription<UserAccelerometerEvent> _streamSubscription;
  Offset _position;

  MotionHandler({required this.onPositionChanged, required Offset initialPosition})
      : _position = initialPosition {
    _streamSubscription = userAccelerometerEvents.listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    // Ajusta este valor según la sensibilidad que desees para los movimientos
    double sensitivity = 0.1;

    // Actualiza la posición en función de los valores del evento del acelerómetro
    _position = Offset(
      _position.dx + event.x * sensitivity,
      _position.dy + event.y * sensitivity,
    );

    // Llama a la función de devolución de llamada para informar sobre la posición actualizada
    onPositionChanged(_position);
  }

  void dispose() {
    _streamSubscription.cancel();
  }
}
