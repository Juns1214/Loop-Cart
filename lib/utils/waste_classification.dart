import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationResult {
  final String category;
  final double confidence;
  final bool isRecyclable;
  final String tips;

  ClassificationResult({
    required this.category,
    required this.confidence,
    required this.isRecyclable,
    required this.tips,
  });
}

class ClassificationService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  // Load model and labels
  Future<void> loadModel() async {
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((line) {
        // Remove numbers like "0 Trash" -> "Trash"
        return line.replaceFirst(RegExp(r'^\d+\s*'), '').trim();
      }).where((label) => label.isNotEmpty).toList();
      
      print('Model loaded successfully with ${_labels?.length} categories');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  // Classify image
  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    // Preprocess image
    final inputImage = await _preprocessImage(imageFile);
    
    // Prepare output buffer
    final output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
    
    // Run inference
    _interpreter!.run(inputImage, output);
    
    // Get results
    final results = output[0] as List<double>;
    
    // Find highest confidence
    double maxConfidence = results[0];
    int maxIndex = 0;
    for (int i = 1; i < results.length; i++) {
      if (results[i] > maxConfidence) {
        maxConfidence = results[i];
        maxIndex = i;
      }
    }
    
    final category = _labels![maxIndex];
    final confidence = maxConfidence * 100; // Convert to percentage
    
    return ClassificationResult(
      category: category,
      confidence: confidence,
      isRecyclable: _isRecyclable(category),
      tips: _getRecyclingTips(category),
    );
  }

  // Preprocess image to model input format (224x224)
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to 224x224 (Teachable Machine default)
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    
    // Convert to normalized float array [1, 224, 224, 3]
    var input = List.generate(
      1,
      (b) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0, // Normalize to 0-1
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  // Determine if category is recyclable
  bool _isRecyclable(String category) {
    final nonRecyclable = ['Trash', 'Food Waste', 'Shoes', 'Clothes'];
    return !nonRecyclable.contains(category);
  }

  // Get recycling tips for each category
  String _getRecyclingTips(String category) {
    // TODO: Load from JSON file
    final tips = {
      'Plastic': 'Remove caps and labels. Rinse containers to remove food residue. Check the recycling number (1-7) on the bottom.',
      'Paper': 'Keep paper clean and dry. Remove any plastic windows or tape. Flatten cardboard boxes to save space.',
      'Metal': 'Rinse cans and remove labels if possible. Crush aluminum cans to save space. Steel and aluminum are highly recyclable.',
      'Glass': 'Rinse bottles and jars. Remove metal lids. Do not include broken glass, mirrors, or ceramics.',
      'Cardboard': 'Flatten boxes completely. Keep cardboard dry and free from food contamination. Remove any tape or labels.',
      'E-Waste': 'Never throw electronics in regular trash. Take to designated e-waste collection centers. Remove batteries if possible.',
      'Food Waste': 'Not recyclable. Consider composting at home or check for local composting programs. Keep separate from recyclables.',
      'Trash': 'Not recyclable. Dispose in general waste bin. Try to reduce waste by choosing reusable alternatives.',
      'Shoes': 'Not typically recyclable. Consider donating if still wearable. Some brands have take-back programs.',
      'Clothes': 'Not recyclable in recycling bins. Donate to charity, sell, or look for textile recycling programs.',
    };
    
    return tips[category] ?? 'Check with your local recycling center for specific guidelines.';
  }

  // Clean up resources
  void dispose() {
    _interpreter?.close();
  }
}