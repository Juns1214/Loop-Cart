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
          // Limit to 3 images
          _selectedImages = images
              .take(3)
              .map((xFile) => File(xFile.path))
              .toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  String _generateReviewId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'REV$timestamp$random';
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
    return null;
  }

  Future<void> _submitReview() async {
    // Validation
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to submit review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user profile
      Map<String, dynamic>? userProfile = await _getUserProfile();
      String userName = userProfile?['name'] ?? 'Anonymous';
      String userProfileUrl = userProfile?['profileImage'] ?? '';

      String reviewId = _generateReviewId();
      String productId = widget.product['productId'] ?? '';

      // Create review document
      Map<String, dynamic> reviewData = {
        'reviewId': reviewId,
        'productId': productId,
        'orderId': widget.orderId,
        'userId': currentUser!.uid,
        'userName': userName,
        'userProfileUrl': userProfileUrl,
        'rating': _rating,
        'reviewTitle': _titleController.text.trim(),
        'reviewText': _reviewController.text.trim(),
        'reviewDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Note: Image upload would require Firebase Storage setup
      // For now, we'll store image paths if selected
      if (_selectedImages.isNotEmpty) {
        reviewData['hasImages'] = true;
        reviewData['imageCount'] = _selectedImages.length;
        // In production, upload to Firebase Storage and store URLs
        // reviewData['imageUrls'] = uploadedUrls;
      }

      // Save review to Firestore
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .set(reviewData);

      // Mark product as reviewed in order
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'items': FieldValue.arrayRemove([widget.product]),
      });

      // Update product with reviewed flag
      Map<String, dynamic> updatedProduct = Map.from(widget.product);
      updatedProduct['isReviewed'] = true;

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'items': FieldValue.arrayUnion([updatedProduct]),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate review submitted

    } catch (e) {
      print('Error submitting review: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        // Dialog content (2/3 of screen)
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
              vertical: MediaQuery.of(context).size.height * 0.15,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Write a Review',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Product info
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: widget.product['imageUrl'] != null &&
                                          widget.product['imageUrl'].isNotEmpty
                                      ? Image.asset(
                                          widget.product['imageUrl'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.white,
                                              child: Icon(Icons.image),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.white,
                                          child: Icon(Icons.image),
                                        ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.product['productName'] ?? 'Product',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating
                            Text(
                              'Rate this product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildStarRating(),
                            if (_rating > 0)
                              Center(
                                child: Text(
                                  '$_rating out of 5',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                            SizedBox(height: 24),

                            // Review Title
                            Text(
                              'Review Title (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Summarize your review',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF388E3C),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Review Text
                            Text(
                              'Your Review *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _reviewController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Share your experience with this product...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF388E3C),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Image Upload Section
                            Text(
                              'Add Photos (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            // Selected images preview
                            if (_selectedImages.isNotEmpty)
                              Container(
                                height: 100,
                                margin: EdgeInsets.only(bottom: 12),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              _selectedImages[index],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                            // Upload button
                            if (_selectedImages.length < 3)
                              OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: Icon(Icons.add_photo_alternate),
                                label: Text('Add Photos (Max 3)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Color(0xFF388E3C),
                                  side: BorderSide(color: Color(0xFF388E3C)),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                            SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF388E3C),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Submit Review',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
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
}