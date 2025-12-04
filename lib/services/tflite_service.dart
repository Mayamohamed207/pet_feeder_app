import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io' show File;
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'tflite_stub.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:http/http.dart' as http;

class TFLiteService {
  static Interpreter? _interpreter;
  static const int IMG_SIZE = 224;
  static bool _isInitialized = false;
  
  static const String API_BASE = 'http://localhost:8000';
  static const String PREDICT_ENDPOINT = '$API_BASE/predict';
  static const String GET_PREDICTION_ENDPOINT = '$API_BASE/get-prediction';
  static const String STATUS_ENDPOINT = '$API_BASE/status';
  static const String ANALYZE_LIVE_ENDPOINT = '$API_BASE/analyze-live';  

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    _isInitialized = true;
  }

  static Future<List<List<List<List<double>>>>> _preprocessImageFromAsset(
    String assetPath,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    return _preprocessImageFromBytes(data.buffer.asUint8List());
  }

  static Future<List<List<List<List<double>>>>> _preprocessImageFromFile(
    String filePath,
  ) async {
    final File file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    return _preprocessImageFromBytes(bytes);
  }

  static Future<List<List<List<List<double>>>>> _preprocessImageFromBytes(
    Uint8List bytes,
  ) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    img.Image resized = img.copyResize(
      image,
      width: IMG_SIZE,
      height: IMG_SIZE,
    );
    var input = List.generate(
      1,
      (b) => List.generate(
        IMG_SIZE,
        (y) => List.generate(IMG_SIZE, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );
    return input;
  }

  static Future<Map<String, dynamic>> _predictViaAPI(
    Uint8List imageBytes,
  ) async {
    String base64Image = base64Encode(imageBytes);
    final response = await http.post(
      Uri.parse(PREDICT_ENDPOINT),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': base64Image}),
    );
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }
    final result = jsonDecode(response.body);
    return {
      'isCat': result['isCat'],
      'confidence': result['confidence'],
      'catProbability': result['catProbability'],
      'notCatProbability': result['notCatProbability'],
    };
  }

  static Future<Map<String, dynamic>> analyzeLiveFromESP32() async {
    if (!_isInitialized) await initialize();
    
    try {
      print(' Calling /analyze-live endpoint...');
      
      final response = await http.get(
        Uri.parse(ANALYZE_LIVE_ENDPOINT),
      ).timeout(
        Duration(seconds: 15),  
        onTimeout: () {
          throw Exception('Request timed out. Check if ESP32 and API server are online.');
        },
      );
      
      print(' Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print(' Live analysis result: $result');
        
        return {
          'isCat': result['prediction']['isCat'],
          'confidence': result['prediction']['confidence'],
          'catProbability': result['prediction']['catProbability'],
          'notCatProbability': result['prediction']['notCatProbability'],
          'source': result['source'],
          'size_bytes': result['size_bytes'],
        };
      } else if (response.statusCode == 502) {
        throw Exception('Cannot connect to ESP32. Please check if ESP32 is online.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in analyzeLiveFromESP32: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPredictionFromServer() async {
    if (!_isInitialized) await initialize();
    
    try {
      final response = await http.get(Uri.parse(GET_PREDICTION_ENDPOINT));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'isCat': result['isCat'],
          'confidence': result['confidence'],
          'catProbability': result['catProbability'],
          'notCatProbability': result['notCatProbability'],
        };
      } else if (response.statusCode == 404) {
        throw Exception('No image available. ESP32 needs to upload an image first.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting prediction: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(STATUS_ENDPOINT));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check server status');
      }
    } catch (e) {
      print('Error checking status: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _predictLocal(
    List<List<List<List<double>>>> input,
  ) async {
    if (_interpreter == null) {
      throw Exception("TFLite interpreter not initialized");
    }
    var output = List.filled(
      1,
      List.filled(2, 0.0),
    ).map((e) => List<double>.from(e)).toList();
    
    _interpreter!.run(input, output);
    double notCatProb = output[0][0];
    double catProb = output[0][1];
    bool isCat = catProb > notCatProb;
    double confidence = isCat ? catProb : notCatProb;
    
    return {
      'isCat': isCat,
      'confidence': confidence,
      'catProbability': catProb,
      'notCatProbability': notCatProb,
    };
  }

  static Future<Map<String, dynamic>> predictFromAsset(String assetPath) async {
    if (!_isInitialized) await initialize();
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    if (kIsWeb) return await _predictViaAPI(bytes);
    var input = await _preprocessImageFromBytes(bytes);
    return await _predictLocal(input);
  }

  static Future<Map<String, dynamic>> predictFromFile(String filePath) async {
    if (!_isInitialized) await initialize();
    if (kIsWeb) {
      throw Exception(
        'File system not available on web. Use predictFromBytes instead.',
      );
    }
    var input = await _preprocessImageFromFile(filePath);
    return await _predictLocal(input);
  }

  static Future<Map<String, dynamic>> predictFromBytes(Uint8List bytes) async {
    if (!_isInitialized) await initialize();
    if (kIsWeb) return await _predictViaAPI(bytes);
    var input = await _preprocessImageFromBytes(bytes);
    return await _predictLocal(input);
  }

  static void dispose() {
    if (kIsWeb) return;
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}