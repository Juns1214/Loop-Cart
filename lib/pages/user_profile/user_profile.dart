import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: userData?['profileImageURL'] != null && 
                                              userData!['profileImageURL'].isNotEmpty
                                  ? NetworkImage(userData!['profileImageURL'])
                                  : AssetImage('assets/images/icon/LogoIcon.png') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white, size: 20),
                                  onPressed: () {
                                    // Navigate to edit profile page
                                    Navigator.pushNamed(context, '/edit-profile');
                                  },
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        // User Name
                        Text(
                          userData?['name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // User Email
                        Text(
                          userData?['email'] ?? 'No Email',
                          style: TextStyle(
                            fontSize: 16, 
                            color: Colors.grey[600],
                            fontFamily: 'Manrope',
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                        // Phone Number
                        if (userData?['phoneNumber'] != null && userData!['phoneNumber'].isNotEmpty)
                          Text(
                            '+60 ${userData!['phoneNumber']}',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey[500],
                              fontFamily: 'Manrope',
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // History Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFF388E3C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined, 
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          title: Text(
                            'Purchase History',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Navigate to Purchase History
                          },
                        ),
                        
                        Divider(height: 8),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.monetization_on_outlined, 
                              color: Colors.amber[700],
                            ),
                          ),
                          title: Text(
                            'Green Coins History',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Navigate to Green Coins History
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Quick Actions Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.data_thresholding_rounded, 
                              color: Colors.blue[700],
                            ),
                          ),
                          title: Text(
                            'Sustainability Dashboard',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Navigate to Sustainability Dashboard
                          },
                        ),
                        
                        Divider(height: 8),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.support_agent_rounded, 
                              color: Colors.purple[700],
                            ),
                          ),
                          title: Text(
                            'Support ChatBot',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Implement ChatBot functionality
                          },
                        ),
                        
                        Divider(height: 8),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.store_rounded, 
                              color: Colors.orange[700],
                            ),
                          ),
                          title: Text(
                            'My Secondary Hand Store',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Navigate to My Secondary Hand Store
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Activity Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.logout_rounded, 
                              color: Colors.red,
                            ),
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                          onTap: () async {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Logout'),
                                content: Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Implement logout functionality
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pushNamedAndRemoveUntil(
                                        context, 
                                        '/login', 
                                        (route) => false,
                                      );
                                    },
                                    child: Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}