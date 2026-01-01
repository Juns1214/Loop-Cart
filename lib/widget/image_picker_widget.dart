import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  
  // Support both callback styles for backward compatibility
  final VoidCallback? onTap; // Old style (for existing code)
  final Function(File)? onImageSelected; // New style (for classification page)
  
  final String label;

  const ImagePickerWidget({
    super.key,
    required this.imageFile,
    this.onTap,
    this.onImageSelected,
    this.label = "Tap to upload image",
  });

  // Show bottom sheet to choose camera or gallery
  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Camera option
              _buildSourceOption(
                context,
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              const SizedBox(height: 12),
              // Gallery option
              _buildSourceOption(
                context,
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build each option button
  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024, // Optimize image size
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Use new callback if provided, otherwise do nothing
      // (old code will handle it through their own logic)
      if (onImageSelected != null) {
        onImageSelected!(File(pickedFile.path));
      }
    }
  }

  // Handle tap - prioritize new style if provided
  void _handleTap(BuildContext context) {
    if (onImageSelected != null) {
      // New style - show options
      _showImageSourceOptions(context);
    } else if (onTap != null) {
      // Old style - use existing callback
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: onImageSelected != null 
                ? const Color(0xFF4CAF50) // Green for classification page
                : Colors.black, // Gray for other pages
            width: onImageSelected != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (onImageSelected != null 
                  ? const Color(0xFF4CAF50) 
                  : Colors.black).withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(onImageSelected != null ? 20 : 0),
                    decoration: onImageSelected != null
                        ? BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 50,
                      color: onImageSelected != null 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2E5BFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (onImageSelected != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Camera or Gallery',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile!, fit: BoxFit.cover),
                    // Edit overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: onImageSelected != null 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2E5BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}