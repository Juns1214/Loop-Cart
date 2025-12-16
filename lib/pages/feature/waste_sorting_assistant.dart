import 'dart:io';
import 'package:flutter/material.dart';
import '../../widget/section_header.dart';
import '../../widget/section_container.dart';
import '../../widget/image_picker_widget.dart';
import '../../utils/waste_classification.dart';
import '../../widget/result_card.dart';
import '../../widget/loading_widget.dart';

class WasteClassificationPage extends StatefulWidget {
  const WasteClassificationPage({super.key});

  @override
  State<WasteClassificationPage> createState() => _WasteClassificationPageState();
}

class _WasteClassificationPageState extends State<WasteClassificationPage> {
  final ClassificationService _classificationService = ClassificationService();
  
  File? _selectedImage;
  ClassificationResult? _result;
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // Load the TFLite model
  Future<void> _loadModel() async {
    try {
      await _classificationService.loadModel();
      setState(() {
        _modelLoaded = true;
      });
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _showErrorDialog('Failed to load AI model. Please restart the app.');
    }
  }

  // Handle image selection
  Future<void> _onImageSelected(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _result = null;
      _isLoading = true;
    });

    if (!_modelLoaded) {
      _showErrorDialog('Model is still loading. Please wait.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Classify the image
      final result = await _classificationService.classifyImage(imageFile);
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      print('Classification error: $e');
      _showErrorDialog('Failed to analyze image. Please try again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _classificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          'Waste Classification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with icon
            Container(
              width: double.infinity,
              color: const Color(0xFF4CAF50),
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.recycling,
                    size: 60,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload an image to identify waste category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Image picker section
            SectionContainer(
              backgroundColor: const Color(0xFFF5F5F5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Upload Image',
                    subtitle: 'Take a photo or choose from gallery',
                  ),
                  ImagePickerWidget(
                    imageFile: _selectedImage,
                    onImageSelected: _onImageSelected,
                    label: 'Upload waste item',
                  ),
                ],
              ),
            ),

            // Loading or Result section
            if (_isLoading)
              SectionContainer(
                backgroundColor: const Color(0xFFF5F5F5),
                child: const LoadingWidget(),
              ),

            if (_result != null && !_isLoading)
              SectionContainer(
                backgroundColor: const Color(0xFFF5F5F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Classification Result',
                    ),
                    ResultCard(result: _result!),
                    
                    // Disclaimer
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'AI classification may not be 100% accurate. Please verify before disposal.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Placeholder for future content
            if (_result == null && !_isLoading && _selectedImage == null)
              SectionContainer(
                backgroundColor: const Color(0xFFF5F5F5),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 60,
                        color: const Color(0xFF4CAF50).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Start by uploading an image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our AI will help identify the waste category and provide recycling guidance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}