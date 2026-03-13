import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'service.dart';

void main() {
  // Iniciamos flutter
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}
//Manejo de cambio de color de los temas

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Variable para controlar el tema actual
  ThemeMode _themeMode = ThemeMode.light;

  // Función para cambiar de tema
  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clasificador IA',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode, // Aquí le decimos qué tema usar
      theme: ThemeData(
        //tema claro
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      //tema obscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.amber,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // Pantalla principal de la aplicacion
      home: ModelScreen(
        toggleTheme: toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class ModelScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const ModelScreen({
    super.key,
    required this.toggleTheme,
    required this.isDark,
  });

  @override
  ModelScreenState createState() => ModelScreenState();
}

class ModelScreenState extends State<ModelScreen> {
  late TFService tfService;
  List<String> _labels = [];

  File? _image;
  bool _isModelReady = false;
  bool _isAnalyzing = false;

  String _predictedLabel = '';
  double _confidence = 0.0;
  String _errorMessage = '';

  var customLogger = Logger(
    printer: PrettyPrinter(methodCount: 0, lineLength: 80, colors: true),
  );

  @override
  void initState() {
    super.initState();
    tfService = TFService();
    _initTFLite();
    _loadLabels();
  }

  //cargamos el modelo
  Future<void> _initTFLite() async {
    try {
      await tfService.loadModel();
      if (mounted) {
        setState(() {
          _isModelReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el modelo TFLite:\n$e';
        });
      }
    }
  }

  //cargamos las etiquetas
  Future<void> _loadLabels() async {
    try {
      final rawLabels = await rootBundle.loadString('assets/models/labels.txt');
      if (mounted) {
        setState(() {
          _labels = rawLabels.split('\n');
        });
      }
    } catch (e) {
      customLogger.e('Error al cargar labels.txt: $e');
    }
  }

  int _argMax(List<double> values) {
    if (values.isEmpty) return 0;
    int maxIndex = 0;
    double maxValue = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  // funcion para tomar foto y analizarla
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
        _predictedLabel = '';
        _confidence = 0.0;
        _errorMessage = '';
      });
      _runModel();
    }
  }

  // funcion para seleccionar foto de galeria
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
        _predictedLabel = '';
        _confidence = 0.0;
        _errorMessage = '';
      });
      _runModel();
    }
  }

  // funcion para correr el modelo y mostrar resultados
  Future<void> _runModel() async {
    if (!_isModelReady || _image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      List<double> result = await tfService.runModel(_image!);

      if (result.isEmpty) {
        setState(() {
          _errorMessage = 'No se obtuvieron resultados.';
          _isAnalyzing = false;
        });
        return;
      }

      final int predictedIndex = _argMax(result);
      String rawLabel = _labels.isNotEmpty && predictedIndex < _labels.length
          ? _labels[predictedIndex]
          : 'Clase $predictedIndex';
      final String label = rawLabel.isNotEmpty
          ? '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}'
          : rawLabel;

      final double conf = result[predictedIndex];

      setState(() {
        _predictedLabel = label;
        _confidence = conf;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en la inferencia:\n$e';
        _isAnalyzing = false;
      });
      customLogger.e('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escáner Inteligente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Botón para cambiar de tema
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Cambiar tema',
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            bool isPortrait = orientation == Orientation.portrait;

            return Center(
              child: isPortrait
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildUIElements(isPortrait),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildUIElements(isPortrait),
                    ),
            );
          },
        ),
      ),
      floatingActionButton: _isModelReady
          ? FloatingActionButton.extended(
              onPressed: _isAnalyzing ? null : _takePhoto,
              icon: Icon(
                Icons.camera_alt,
                color: widget.isDark ? Colors.black : Colors.white,
              ),
              label: Text(
                'Escanear',
                style: TextStyle(
                  color: widget.isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _isAnalyzing
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Widget> _buildUIElements(bool isPortrait) {
    return [
      Expanded(
        flex: isPortrait ? 5 : 1,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              // El fondo de la caja de imagen se adapta al tema
              color: widget.isDark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark ? Colors.black54 : Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search,
                          size: 80,
                          color: widget.isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isModelReady
                              ? 'Toma una foto para comenzar'
                              : 'Cargando modelo de IA...',
                          style: TextStyle(
                            color: widget.isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
          ),
        ),
      ),

      Expanded(
        flex: isPortrait ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAnalyzing)
                Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Procesando imagen...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )
              else if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                )
              else if (_predictedLabel.isNotEmpty)
                Card(
                  elevation: widget.isDark ? 2 : 4,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Resultado:',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _predictedLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Confianza: ${(_confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              TextButton.icon(
                onPressed: _isAnalyzing ? null : _pickFromGallery,
                icon: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Subir desde galería',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (isPortrait) const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    ];
  }
}
