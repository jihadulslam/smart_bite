import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pending_recipes_page.dart';
import 'user_activity_page.dart';
import 'profile_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final Color _primaryColor = const Color(0xFF7A232E);
  final Color _bgColor = const Color(0xFFFAF9F9);

  Future<void> _exitAdminPanel(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitAdminPanel(context);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _exitAdminPanel(context),
          ),
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Log out',
              onPressed: () => _exitAdminPanel(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Live overview of SmartBite.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Live Analytics Row 1: Total Users & Pending Recipes
            Row(
              children: [
                _buildLiveStatCard(
                  title: 'Total Users',
                  icon: Icons.people,
                  color: Colors.blue,
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                ),
                const SizedBox(width: 16),
                _buildLiveStatCard(
                  title: 'Pending',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Analytics Row 2: Approved Recipes & Active Categories
            Row(
              children: [
                _buildLiveStatCard(
                  title: 'Approved',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                ),
                const SizedBox(width: 16),
                _buildUniqueCategoriesCard(),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              'Management Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Action Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(context, 'Pending Recipes', 'Review user posts', Icons.rule_folder, Colors.orange.shade700),
                _buildActionCard(context, 'User Activity', 'Track & manage users', Icons.manage_accounts, Colors.blue.shade700),
                _buildActionCard(context, 'Manage Recipes', 'Edit or delete recipes', Icons.edit_document, Colors.green.shade700),
                _buildActionCard(context, 'Manage Tags', 'Districts & Health tags', Icons.local_offer, Colors.purple.shade700),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  // Firebase StreamBuilder দিয়ে আসল কাউন্ট দেখানোর কার্ড
  Widget _buildLiveStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          String countText = '...';
          if (snapshot.hasData) {
            countText = snapshot.data!.docs.length.toString();
          } else if (snapshot.hasError) {
            countText = '0';
          }
          return _statCardContainer(title, countText, icon, color);
        },
      ),
    );
  }

  // রেসিপিগুলো থেকে মোট কতগুলো ইউনিক ক্যাটাগরি (District/Tag) আছে তা গুনবে
  Widget _buildUniqueCategoriesCard() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (context, snapshot) {
          String countText = '...';
          if (snapshot.hasData) {
            final tags = snapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['tag']?.toString() ?? '')
                .where((tag) => tag.isNotEmpty)
                .toSet();
            countText = tags.length.toString();
          } else if (snapshot.hasError) {
            countText = '0';
          }
          return _statCardContainer('Categories', countText, Icons.category, Colors.purple);
        },
      ),
    );
  }

  Widget _statCardContainer(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor) {
    return InkWell(
      onTap: () {
        if (title == 'Pending Recipes' || title == 'Manage Recipes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PendingRecipesPage()),
          );
        } else if (title == 'User Activity') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserActivityPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to $title...')),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}