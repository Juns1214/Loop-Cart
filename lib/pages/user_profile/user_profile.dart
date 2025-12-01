import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import '../../utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/user-profile",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

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
    loadUserProfile();
  }
  
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_profile')
            .doc(user.uid)
            .get();
        
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error loading profile: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(context, '/edit-profile');
    if (result == true) {
      // Reload profile data after edit
      loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Manrope',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF388E3C),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Enhanced Profile Header Section
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF388E3C).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image with Enhanced Shadow
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: userData?['profileImageURL'] != null && 
                                                userData!['profileImageURL'].isNotEmpty
                                    ? MemoryImage(base64Decode(userData!['profileImageURL']))
                                    : AssetImage('assets/images/icon/LogoIcon.png') as ImageProvider,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit_rounded, color: Color(0xFF388E3C), size: 22),
                                  onPressed: _navigateToEditProfile,
                                  padding: EdgeInsets.all(10),
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // User Name
                        Text(
                          userData?['name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 26, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 8),
                        
                        // User Email
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                userData?['email'] ?? 'No Email',
                                style: TextStyle(
                                  fontSize: 15, 
                                  color: Colors.white,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Phone Number with +60 prefix
                        if (userData?['phoneNumber'] != null && userData!['phoneNumber'].isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  userData!['phoneNumber'],
                                  style: TextStyle(
                                    fontSize: 15, 
                                    color: Colors.white,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 16),

                        // Green Coins Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on, color: Colors.amber[700], size: 24),
                              SizedBox(width: 8),
                              Text(
                                '${userData?['greenCoins'] ?? 0} Green Coins',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Manrope',
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Profile Details Card
                  if (userData != null) ...[
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.person_outline, color: Colors.blue[700], size: 22),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Profile Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Date of Birth
                          if (userData!['dateOfBirth'] != null && userData!['dateOfBirth'].isNotEmpty)
                            _buildDetailRow(
                              icon: Icons.cake_rounded,
                              iconColor: Colors.pink[400]!,
                              label: 'Date of Birth',
                              value: userData!['dateOfBirth'],
                            ),

                          // Address
                          if (userData!['address'] != null && userData!['address'] is Map)
                            _buildAddressSection(userData!['address'] as Map<String, dynamic>),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // History Section
                  _buildSection(
                    title: 'History',
                    icon: Icons.history_rounded,
                    iconColor: Colors.purple,
                    items: [
                      _buildListItem(
                        icon: Icons.shopping_bag_rounded,
                        iconColor: Color(0xFF388E3C),
                        title: 'Purchase History',
                        subtitle: 'View your orders',
                        onTap: () {},
                      ),
                      Divider(height: 1, thickness: 1),
                      _buildListItem(
                        icon: Icons.monetization_on_rounded,
                        iconColor: Colors.amber[700]!,
                        title: 'Green Coins History',
                        subtitle: 'Track your rewards',
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Quick Actions Section
                  _buildSection(
                    title: 'Quick Actions',
                    icon: Icons.rocket_launch_rounded,
                    iconColor: Colors.blue,
                    items: [
                      _buildListItem(
                        icon: Icons.pie_chart_rounded,
                        iconColor: Colors.blue[700]!,
                        title: 'Sustainability Dashboard',
                        subtitle: 'View your impact',
                        onTap: () {},
                      ),
                      Divider(height: 1, thickness: 1),
                      _buildListItem(
                        icon: Icons.support_agent_rounded,
                        iconColor: Colors.purple[700]!,
                        title: 'Support ChatBot',
                        subtitle: 'Get instant help',
                        onTap: () {},
                      ),
                      Divider(height: 1, thickness: 1),
                      _buildListItem(
                        icon: Icons.store_rounded,
                        iconColor: Colors.orange[700]!,
                        title: 'My Secondary Hand Store',
                        subtitle: 'Manage your listings',
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Activity Section
                  _buildSection(
                    title: 'Activity',
                    icon: Icons.settings_rounded,
                    iconColor: Colors.grey,
                    items: [
                      _buildListItem(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        titleColor: Colors.red,
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.logout_rounded, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text(
                                    'Logout',
                                    style: TextStyle(fontFamily: 'Manrope'),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to logout?',
                                style: TextStyle(fontFamily: 'Manrope'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushNamedAndRemoveUntil(
                                      context, 
                                      '/login', 
                                      (route) => false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // --- NEW METHODS ADDED HERE ---

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Manrope',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> address) {
    // Combine address parts safely
    List<String> addressParts = [];
    
    // Check for common address fields
    if (address['line1'] != null && address['line1'].toString().isNotEmpty) addressParts.add(address['line1']);
    if (address['line2'] != null && address['line2'].toString().isNotEmpty) addressParts.add(address['line2']);
    if (address['city'] != null && address['city'].toString().isNotEmpty) addressParts.add(address['city']);
    if (address['state'] != null && address['state'].toString().isNotEmpty) addressParts.add(address['state']);
    if (address['postcode'] != null && address['postcode'].toString().isNotEmpty) addressParts.add(address['postcode']);

    String formattedAddress = addressParts.join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: _buildDetailRow(
        icon: Icons.location_on_rounded,
        iconColor: Colors.orange[700]!,
        label: 'Address',
        value: formattedAddress.isNotEmpty ? formattedAddress : 'Address incomplete',
      ),
    );
  }

  // --- END NEW METHODS ---

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Manrope',
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 18,
        color: titleColor ?? Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}