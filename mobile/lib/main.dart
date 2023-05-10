import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pathfinding/core/grid.dart';
import 'package:pathfinding/finders/astar.dart';
import 'models/indoor_map.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Indoor Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Offset startPoint = const Offset(200, 620);
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  List<double>? _magnetometerValues;
  double lowPassFactor = 0.9;
  List<double> previousAccelerometerValues = [0, 0, 0];
  double stepThreshold = 10;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  late Grid grid;
  List<List<int>> gridData = [];
  List<Gondola> gondolas = [
    Gondola(name: 'frutas', position: const Offset(300, 220), color: Colors.orange),
    Gondola(name: 'juguetes', position: const Offset(300, 1100), color: Colors.purple),
    Gondola(name: 'carnes', position: const Offset(1500, 220), color: Colors.indigo),
  ];

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

  }

  Future<void> _speakWelcomeMessage(gondolas) async {
    await flutterTts.setLanguage("es-MX");
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    List<String> gondolaNames = gondolas.map((gondola) => gondola.name)
        .toList()
        .cast<String>();
    String gondolasString = gondolaNames.join(', ');
    String mensaje = "Bienvenido al supermercado. Estas son las góndolas disponibles: "
        "$gondolasString. "
        "Por favor, di el nombre de la góndola a la que quieres ir.";
    await flutterTts.speak(mensaje);

    // Espera a que termine de hablar antes de comenzar a escuchar
    int segundosParaEscuchar = (mensaje.length / 15).ceil();
    Future.delayed(Duration(seconds: segundosParaEscuchar), () {
      _startListening(gondolaNames);
    });
  }

  void _startListening(List<String>gondolaNames) async {
    bool available = await _speech.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    if (available) {
      _speech.listen(
        onResult: (val) async {
          String gondolaName = val.recognizedWords;
          print('Nombre de la góndola: $gondolaName');
          await handleGondolaSelection(gondolaNames, gondolaName);
        },
      );
    } else {
      print("El reconocimiento de voz no está disponible");
    }
  }

  List<List> _findPathToGondola(Offset startPoint, Offset gondolaPosition) {
    print("Start: $startPoint");
    print("Gondola: $gondolaPosition");

    var astar = AStarFinder();

    List<List> path = astar.findPath(
      startPoint.dx.toInt(),
      startPoint.dy.toInt(),
      gondolaPosition.dx.toInt(),
      gondolaPosition.dy.toInt(),
      grid.clone(),
    );
    
    print("Leyendo la ruta solicitada ...");

    return path;
  }

  Gondola? _getGondolaByName(String name) {
    for (Gondola gondola in gondolas) {
      if (gondola.name.toLowerCase() == name.toLowerCase()) {
        return gondola;
      }
    }
    return null;
  }

  List<String> _pathToInstructions(List<List> path) {
    List<String> instructions = [];

    // Define una constante para el factor de escala (píxeles por paso humano).
    const double scaleFactor = 5;

    int steps = 1;
    String currentDirection = "";

    for (int i = 0; i < path.length - 1; i++) {
      int dx = path[i + 1][0] - path[i][0];
      int dy = path[i + 1][1] - path[i][1];

      String newDirection = "";

      if (dx > 0) {
        newDirection = 'derecha';
      } else if (dx < 0) {
        newDirection = 'izquierda';
      } else if (dy > 0) {
        newDirection = 'abajo';
      } else if (dy < 0) {
        newDirection = 'arriba';
      }

      if (newDirection == currentDirection) {
        // Si estamos yendo en la misma dirección, incrementa el contador de pasos.
        steps++;
      } else {
        // Si la dirección ha cambiado, añade la instrucción acumulada y reinicia el contador de pasos.
        if (currentDirection != "") {
          // Convierte los píxeles en pasos humanos dividiendo por el factor de escala.
          int humanSteps = (steps / scaleFactor).round();

          // Solo añade la instrucción si hay al menos 5 pasos humanos.
          if (humanSteps >= 5) {
            instructions.add('Moverse $humanSteps pasos a la $currentDirection');
          }
        }
        currentDirection = newDirection;
        steps = 1;
      }
    }

    // No olvides añadir la última instrucción si es suficientemente grande.
    int lastHumanSteps = (steps / scaleFactor).round();
    if (lastHumanSteps >= 10) {
      instructions.add('Moverse $lastHumanSteps pasos a la $currentDirection');
    }

    return instructions;
  }

  Future<void> handleGondolaSelection(List<String>gondolaNames,
      String selectedGondola) async {
    bool gondolaExists = gondolaNames.contains(selectedGondola);
    await Future.delayed(const Duration(seconds: 3));

    if (gondolaExists) {
      await flutterTts.speak(
          "La góndola $selectedGondola existe. Calculando ruta...");
      Offset? gondolaPosition = _getGondolaByName(selectedGondola)?.position;
      List<List> path = _findPathToGondola(startPoint, gondolaPosition!);
      List<String> instructions = _pathToInstructions(path);
      await Future.delayed(const Duration(seconds: 3));

      String instructionsText = instructions.join('. Luego, ');
      instructionsText += '.';
      await flutterTts.speak(instructionsText);
    } else {
      await flutterTts.speak(
          "Buscando góndola $selectedGondola ..... Dame unos segundos,"
              "Por favor, intenta de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supermarket Indoor Map'),
      ),
      body: FutureBuilder<List<List<int>>>(
        future: loadGridDataJson(),
        builder: (BuildContext context, AsyncSnapshot<List<List<int>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            gridData = snapshot.data!;
            _speakWelcomeMessage(gondolas);
            return CustomPaint(
              size: const Size(1215.0, 1756.0), // size of your area
              painter: GridPainter(gridData, gondolas),
            );
          }
        },
      ),
    );
  }


  Future<List<List<int>>> loadGridDataJson() async {
    try {
      String jsonString = await rootBundle.loadString('assets/output.json');
      print("Leyendo el archivo ...");
      List<dynamic> jsonRaw = jsonDecode(jsonString);

      List<List<int>> gridData = jsonRaw.map<List<int>>((dynamic row) {
        return row.cast<int>();
      }).toList();

      print("Tamaño del arreglo: ${gridData.length}");

      var height = 1215;
      var width = 1756;

      // Obtén las dimensiones de tu matriz.
      int rows = gridData.length;
      int cols = gridData[0].length;

      // Asegúrate de que la matriz tiene las dimensiones correctas.
      if (rows != height || cols != width) {
        throw Exception('Matrix size does not fit');
      }

      // Crea un nuevo objeto Grid usando esas dimensiones y tus datos.
      grid = Grid(width, height, gridData);

      return gridData;
    } catch (e) {
      print("Error loading grid data: $e");
      throw Exception("Error loading grid data: $e");
    }
  }

}

class GridPainter extends CustomPainter {
  List<List<int>> gridData;
  List<Gondola> gondolas;

  GridPainter(this.gridData, this.gondolas);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    double scaleX = size.width / gridData[0].length;
    double scaleY = size.height / gridData.length;
    double scale = min(scaleX, scaleY);

    for (int i = 0; i < gridData.length; i++) {
      for (int j = 0; j < gridData[i].length; j++) {
        paint.color = gridData[i][j] == 0 ? Colors.white : Colors.black;
        canvas.drawRect(
            Rect.fromLTWH(j * scale, i * scale, scale, scale),
            paint
        );
      }
    }

// Dibujar el punto de inicio en una ubicación específica
    double startPointX = scale * 1550;
    double startPointY = scale * 1100;
    double radius = scale;
    // Establecer un tamaño mínimo para el radio del círculo
    double minRadius = 1; // puedes ajustar este valor según tus necesidades
    if (radius < minRadius) {
      radius = minRadius;
    }

    // Aumentar el tamaño del círculo y cambiar su color a amarillo brillante
    paint.color = Colors.green;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 15.0; // Asegurarse de que el estilo esté configurado en "fill" antes de dibujar el círculo relleno
    canvas.drawCircle(Offset(startPointX, startPointY), radius, paint);

    // Agregar un contorno negro al círculo para resaltarlo
    paint.color = Colors.greenAccent;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 15.0;
    canvas.drawCircle(Offset(startPointX, startPointY), radius, paint);

    // Dibujar los puntos de las góndolas
    List<Offset> gondolaPoints = [
      Offset(scale * 300, scale * 220),
      Offset(scale * 300, scale * 1100),
      Offset(scale * 1500, scale * 220),
    ];

    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;

    var i=0;
    for (Offset gondola in gondolaPoints) {
      canvas.drawCircle(gondola, radius, paint);
      // Agregar un contorno negro a los círculos para resaltarlos
      paint.color = gondolas[i].color;
      paint.style = PaintingStyle.stroke;
      canvas.drawCircle(gondola, radius, paint);
      // Cambiar el color de vuelta a rojo para el relleno del siguiente círculo
      paint.color = gondolas[i].color;
      paint.style = PaintingStyle.fill;
      i++;
    }

  }


  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
