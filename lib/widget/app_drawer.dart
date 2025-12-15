import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/icon/LogoIcon.png'),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Loop Cart',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF388E3C),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildExpansionTile(
            context,
            title: 'Shop',
            iconPath: 'assets/images/icon/shopicon.png',
            children: [
              _buildDrawerItem(context, 'Explore', () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(context, 'Second Hand Items', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/preowned-main-page');
              }),
            ],
          ),
          _buildExpansionTile(
            context,
            title: 'Service',
            iconPath: 'assets/images/icon/serviceicon.png',
            children: [
              _buildDrawerItem(context, 'Repair Service', () {
                Navigator.pop(context);
                onNavigate(0);
              }),
              _buildDrawerItem(context, 'Schedule Recycling Pickup', () {
                Navigator.pop(context);
                onNavigate(1);
              }),
              _buildDrawerItem(context, 'Basket of Hope', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/donation');
              }),
            ],
          ),
          _buildExpansionTile(
            context,
            title: 'Sustainability & Impact',
            iconPath: 'assets/images/icon/SustainabilityIcon.png',
            children: [
              _buildDrawerItem(context, 'Green Coin', () {Navigator.pop(context);
                Navigator.pushNamed(context, '/green-coin');}),
              _buildDrawerItem(context, 'Analytics Dashboard', () {
                Navigator.pop(context);
                onNavigate(3);
              }),
            ],
          ),
          _buildListTile(
            context,
            'ChatBot',
            'assets/images/icon/ChatBotIcon.png',
            () {
              Navigator.pop(context);
              onNavigate(4);
            },
          ),
          _buildListTile(
            context,
            'User Profile',
            'assets/images/icon/UserProfileIcon.png',
            () {
              Navigator.pop(context);
              onNavigate(5);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(BuildContext context,
      {required String title,
      required String iconPath,
      required List<Widget> children}) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      leading: Image.asset(iconPath, fit: BoxFit.fill, width: 40, height: 40),
      children: children.map((child) => Column(children: [const Divider(height: 1), child])).toList(),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildListTile(BuildContext context, String title, String iconPath, VoidCallback onTap) {
    return ListTile(
      leading: Image.asset(iconPath, fit: BoxFit.fill, width: 40, height: 40),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      onTap: onTap,
    );
  }
}