import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('user_profile').doc(user.uid).get();
        if (mounted) setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
        debugPrint('Error loading profile: $e');
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(context, '/edit-profile');
    if (result == true) _loadUserProfile();
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF212121))),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF212121), fontWeight: FontWeight.w700, fontSize: 15))),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFFD32F2F), fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFFD32F2F))),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF212121), fontWeight: FontWeight.w700, fontSize: 15))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion requested', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700)), backgroundColor: Color(0xFFD32F2F)));
            },
            child: const Text('Delete', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFFD32F2F), fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF1F8F4), body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3)));
    }

    final greenCoins = userData?['greenCoins'] ?? 0;
    final name = userData?['name'] ?? 'User';
    final email = userData?['email'] ?? '';
    final phone = userData?['phoneNumber']?.toString() ?? '';
    final dob = userData?['dateOfBirth'] ?? '';
    final profileImage = userData?['profileImageURL'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 22), onPressed: () => Navigator.pop(context)),
        title: const Text('Profile', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF212121))),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Color(0xFF2E7D32), size: 26), onPressed: _navigateToEditProfile, tooltip: 'Edit Profile'),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
              child: Column(
                children: [
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: profileImage == null ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]) : null,
                      boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ClipOval(
                      child: profileImage != null
                          ? Image.memory(base64Decode(profileImage), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar(name))
                          : _buildDefaultAvatar(name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontFamily: 'Roboto', fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF66BB6A), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Image.asset( 'assets/images/icon/Green Coin.png', width: 24, height: 24),
                        ),
                        const SizedBox(width: 12),
                        Text('$greenCoins Green Coins', style: const TextStyle(fontFamily: 'Roboto', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Personal Information',
              children: [
                _InfoTile(icon: Icons.person, label: 'Full Name', value: name),
                _InfoTile(icon: Icons.email, label: 'Email', value: email),
                _InfoTile(icon: Icons.phone, label: 'Phone', value: phone.isEmpty ? 'Not provided' : phone),
                _InfoTile(icon: Icons.cake, label: 'Date of Birth', value: dob.isEmpty ? 'Not provided' : dob),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'History',
              children: [
                _MenuTile(icon: Icons.shopping_bag, iconColor: const Color(0xFF2E7D32), title: 'My Activity', onTap: () => Navigator.pushNamed(context, '/my-activity')),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Quick Actions',
              children: [
                _MenuTile(icon: Icons.chat_bubble, iconColor: const Color(0xFF2E7D32), title: 'AI ChatBot', onTap: () => Navigator.pushNamed(context, '/chatbot')),
                _MenuTile(icon: Icons.dashboard, iconColor: const Color(0xFF1976D2), title: 'Sustainability Dashboard', onTap: () => Navigator.pushNamed(context, '/sustainability-dashboard')),
                _MenuTile(icon: Icons.build, iconColor: const Color(0xFFFF6F00), title: 'Repair Service', onTap: () => Navigator.pushNamed(context, '/repair-service')),
                _MenuTile(icon: Icons.recycling, iconColor: const Color(0xFF00897B), title: 'Schedule Recycle Pickup', onTap: () => Navigator.pushNamed(context, '/recycling-pickup')),
                _MenuTile(icon: Icons.sell, iconColor: const Color(0xFF7B1FA2), title: 'Sell Second-hand Product', onTap: () => Navigator.pushNamed(context, '/sell-second-hand-product')),
                _MenuTile(icon: Icons.shopping_basket, iconColor: const Color(0xFF1976D2), title: 'Buy Pre-owned Product', onTap: () => Navigator.pushNamed(context, '/preowned-main-page')),
                _MenuTile(icon: Icons.delete_outline, iconColor: const Color(0xFF388E3C), title: 'Waste Sorting Assistant', onTap: () => Navigator.pushNamed(context, '/waste-sorting-assistant')),
                _MenuTile(icon: Icons.quiz, iconColor: const Color(0xFFFFA726), title: 'Daily Quiz', onTap: () => Navigator.pushNamed(context, '/quiz-start-page')),  // ← ADD THIS LINE

              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Account Settings',
              children: [
                _MenuTile(icon: Icons.logout, iconColor: const Color(0xFFD32F2F), title: 'Logout', onTap: _handleLogout),
                _MenuTile(icon: Icons.delete_forever, iconColor: const Color(0xFFD32F2F), title: 'Delete Account', onTap: _handleDeleteAccount),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontFamily: 'Roboto', fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white))),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF424242))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.iconColor, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF212121)))),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF212121)),
          ],
        ),
      ),
    );
  }
}