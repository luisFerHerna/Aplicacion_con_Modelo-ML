import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

class TFService {
  Interpreter? _interpreter;

  var customLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v1_1.0_224.tflite',
      );
      customLogger.i('Modelo cargado exitosamente a nivel nativo');

      if (_interpreter != null) {
        var inputShape = _interpreter!.getInputTensor(0).shape;
        var outputShape = _interpreter!.getOutputTensor(0).shape;
        customLogger.i('Input shape: $inputShape');
        customLogger.i('Output shape: $outputShape');
      }
    } catch (e) {
      customLogger.e('Error cargando el modelo: $e');
      // Es vital lanzar el error para que main.dart lo atrape y te lo muestre en pantalla
      throw Exception('Fallo al cargar el modelo TFLite: $e');
    }
  }

  void close() {
    _interpreter?.close();
    customLogger.i('Interpreter cerrado');
  }

  Future<List<double>> runModel(File imageFile) async {
    if (_interpreter == null) {
      customLogger.e('El interprete no está inicializado.');
      return [];
    }

    // 1. Decodificar y redimensionar la imagen a 224x224
    img.Image? imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resizedImage = img.copyResize(
      imageInput,
      width: 224,
      height: 224,
    );

    // 2. Preparar el tensor de entrada: [1, 224, 224, 3]
    var input = List.generate(
      1 * 224 * 224 * 3,
      (index) => 0.0,
    ).reshape([1, 224, 224, 3]);

    // 3. Extraer RGB y normalizar (0.0 a 1.0)
    for (var y = 0; y < resizedImage.height; y++) {
      for (var x = 0; x < resizedImage.width; x++) {
        var pixel = resizedImage.getPixel(x, y);
        var r = pixel.r / 255.0;
        var g = pixel.g / 255.0;
        var b = pixel.b / 255.0;

        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
      }
    }

    // 4. Preparar el tensor de salida: [1, 1001]
    var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);

    try {
      // 5. Ejecutar inferencia
      _interpreter!.run(input, output);
      customLogger.i('Inferencia del modelo completada');

      // 6. Devolver la lista plana de 1001 probabilidades
      return List<double>.from(output[0] as List);
    } catch (e) {
      customLogger.e('ERROR durante la inferencia: $e');
      return [];
    }
  }
}
