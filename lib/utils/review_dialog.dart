import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ReviewDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final String orderId;

  const ReviewDialog({
    super.key,
    required this.product,
    required this.orderId,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  int _rating = 0;
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.take(3).map((x) => File(x.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick images'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) return _showSnack('Please select a rating', Colors.orange);
    if (_reviewController.text.trim().isEmpty) return _showSnack('Please write a review', Colors.orange);
    if (currentUser == null) return _showSnack('Please login first', Colors.red);

    setState(() => _isSubmitting = true);

    try {
      // 1. Get User Info
      final userDoc = await FirebaseFirestore.instance.collection('user_profile').doc(currentUser!.uid).get();
      final userData = userDoc.data() ?? {};
      
      String reviewId = 'REV${DateTime.now().millisecondsSinceEpoch}';

      // 2. Prepare Data
      final reviewData = {
        'reviewId': reviewId,
        'productId': widget.product['productId'] ?? '',
        'orderId': widget.orderId,
        'userId': currentUser!.uid,
        'userName': userData['name'] ?? 'Anonymous',
        'userProfileUrl': userData['profileImage'] ?? '',
        'rating': _rating,
        'reviewTitle': _titleController.text.trim(),
        'reviewText': _reviewController.text.trim(),
        'reviewDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        if (_selectedImages.isNotEmpty) ...{
          'hasImages': true,
          'imageCount': _selectedImages.length,
          // 'imageUrls': [] // TODO: Upload images to Storage and add URLs here
        }
      };

      // 3. Batch Writes for Atomicity
      final batch = FirebaseFirestore.instance.batch();
      
      // Save Review
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc(reviewId);
      batch.set(reviewRef, reviewData);

      // Update Order Items
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      
      // We manually update the array to avoid race conditions with complex objects
      // Ideally, just mark the order as "reviewed" or specific item ID as reviewed
      batch.update(orderRef, {
         'items': FieldValue.arrayRemove([widget.product])
      });
      
      final updatedProduct = Map<String, dynamic>.from(widget.product);
      updatedProduct['isReviewed'] = true;
      
      batch.update(orderRef, {
        'items': FieldValue.arrayUnion([updatedProduct])
      });

      await batch.commit();

      if (mounted) {
        _showSnack('Review submitted successfully!', const Color(0xFF388E3C));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to submit review: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRatingSection(),
                            const SizedBox(height: 24),
                            _buildTextField(
                              label: 'Review Title (Optional)',
                              controller: _titleController,
                              hint: 'Summarize your review',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Your Review *',
                              controller: _reviewController,
                              hint: 'Share your experience...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),
                            _buildImageUploadSection(),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF388E3C)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Write a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50, height: 50, color: Colors.white,
                  child: widget.product['imageUrl'] != null 
                    ? Image.asset(widget.product['imageUrl'], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)) 
                    : const Icon(Icons.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.product['productName'] ?? 'Product',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        const Text('Rate this product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => GestureDetector(
            onTap: () => setState(() => _rating = index + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Photos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_,__) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImages[index], width: 80, height: 80, fit: BoxFit.cover)),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                      child: Container(padding: const EdgeInsets.all(2), color: Colors.red, child: const Icon(Icons.close, color: Colors.white, size: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_selectedImages.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Upload Image'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF388E3C), side: const BorderSide(color: Color(0xFF388E3C))),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF388E3C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isSubmitting 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}