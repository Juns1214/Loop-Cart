import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/waste_classification.dart';

class WasteClassificationPage extends StatefulWidget {
  const WasteClassificationPage({super.key});

  @override
  State<WasteClassificationPage> createState() => _WasteClassificationPageState();
}

class _WasteClassificationPageState extends State<WasteClassificationPage> {
  final ClassificationService _classificationService = ClassificationService();
  
  File? _imageFile;
  ClassificationResult? _result;
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classificationService.loadModel();
      setState(() => _modelLoaded = true);
    } catch (e) {
      _showError('Failed to load AI model. Please restart the app.');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() => _imageFile = File(image.path));
        _classifyImage();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error selecting image",
        backgroundColor: const Color(0xFF2E7D32),
        textColor: Colors.white,
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() => _imageFile = File(image.path));
        _classifyImage();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error taking photo",
        backgroundColor: const Color(0xFF2E7D32),
        textColor: Colors.white,
      );
    }
  }

  Future<void> _classifyImage() async {
    if (_imageFile == null) return;

    setState(() {
      _result = null;
      _isLoading = true;
    });

    if (!_modelLoaded) {
      _showError('Model is still loading. Please wait.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _classificationService.classifyImage(_imageFile!);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to analyze image. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: const Color(0xFF2E7D32),
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
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
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Waste Classification',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildImageSection(),
            if (_isLoading) _buildLoadingSection(),
            if (_result != null && !_isLoading) _buildResultSection(),
            if (_result == null && !_isLoading && _imageFile == null) 
              _buildEmptyState(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2E7D32),
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
      child: Column(
        children: [
          Icon(
            Icons.recycling,
            size: 64,
            color: Colors.white.withOpacity(0.95),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload an image to identify waste category',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Upload Image'),
          const SizedBox(height: 8),
          const Text(
            'Take a photo or choose from gallery',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_imageFile != null)
          Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_imageFile!, fit: BoxFit.cover),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Take Photo',
                icon: Icons.camera_alt,
                onTap: _takePhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Choose Photo',
                icon: Icons.photo_library,
                onTap: _pickImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return _SectionContainer(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyzing waste item...',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Classification Result'),
          const SizedBox(height: 16),
          _buildResultCard(),
          const SizedBox(height: 16),
          _buildRecyclabilityBadge(),
          const SizedBox(height: 16),
          _buildTipsCard(),
          const SizedBox(height: 16),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result!.category,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confidence Level',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _result!.confidence / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_result!.confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclabilityBadge() {
    final isRecyclable = _result!.isRecyclable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isRecyclable ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecyclable ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isRecyclable ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isRecyclable ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRecyclable ? 'Recyclable' : 'Not Recyclable',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isRecyclable ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRecyclable 
                    ? 'This item can be recycled' 
                    : 'Dispose in general waste',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7CB342), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CB342),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recycling Tips',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _result!.tips,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF9A825), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFF57F17),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI classification may not be 100% accurate. Please verify before disposal.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _SectionContainer(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 64,
              color: const Color(0xFF2E7D32).withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start by uploading an image',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our AI will help identify the waste category and provide recycling guidance',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== REUSABLE WIDGETS ====================

class _SectionContainer extends StatelessWidget {
  final Widget child;
  
  const _SectionContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E7D32),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}