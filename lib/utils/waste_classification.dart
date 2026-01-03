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
  
  static const String _modelPath = 'assets/models/model_unquant.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _imageSize = 224;
  
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((line) => line.replaceFirst(RegExp(r'^\d+\s*'), '').trim())
          .where((label) => label.isNotEmpty)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    final inputImage = await _preprocessImage(imageFile);
    final output = List.filled(1 * _labels!.length, 0.0)
        .reshape([1, _labels!.length]);
    
    _interpreter!.run(inputImage, output);
    
    final results = output[0] as List<double>;
    final maxIndex = _getMaxConfidenceIndex(results);
    final category = _labels![maxIndex];
    final confidence = results[maxIndex] * 100;
    
    return ClassificationResult(
      category: category,
      confidence: confidence,
      isRecyclable: _isRecyclable(category),
      tips: _getRecyclingTips(category),
    );
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    final resizedImage = img.copyResize(
      image,
      width: _imageSize,
      height: _imageSize,
    );
    
    return List.generate(
      1,
      (b) => List.generate(
        _imageSize,
        (y) => List.generate(
          _imageSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  int _getMaxConfidenceIndex(List<double> results) {
    double maxConfidence = results[0];
    int maxIndex = 0;
    
    for (int i = 1; i < results.length; i++) {
      if (results[i] > maxConfidence) {
        maxConfidence = results[i];
        maxIndex = i;
      }
    }
    
    return maxIndex;
  }

  bool _isRecyclable(String category) {
    const nonRecyclable = ['Trash', 'Food Waste', 'Shoes', 'Clothes'];
    return !nonRecyclable.contains(category);
  }

  String _getRecyclingTips(String category) {
    return _recyclingTipsMap[category] ?? 
        'Check with your local recycling center for specific guidelines.';
  }

  static const Map<String, String> _recyclingTipsMap = {
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

  void dispose() {
    _interpreter?.close();
  }
}