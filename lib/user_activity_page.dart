import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivityPage extends StatelessWidget {
  const UserActivityPage({super.key});

  final Color _primaryColor = const Color(0xFF7A232E);
  final Color _bgColor = const Color(0xFFFAF9F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'User Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final userDocs = snapshot.data?.docs ?? [];

          if (userDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No users found yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userDoc = userDocs[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final String uid = userDoc.id;
              final String email = userData['email'] ?? 'No email';
              final String fullName = userData['fullName'] ??
                  (email.contains('@') ? email.split('@')[0] : 'SmartBite User');
              final String? profilePic = userData['profilePic'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF3EAEB),
                      backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                          ? NetworkImage(profilePic)
                          : null,
                      child: (profilePic == null || profilePic.isEmpty)
                          ? const Text('👨🏻', style: TextStyle(fontSize: 26))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          // ওই ইউজারের সাবমিট করা রেসিপির লাইভ কাউন্ট
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('recipes')
                                .where('authorId', isEqualTo: uid)
                                .snapshots(),
                            builder: (context, recipeSnapshot) {
                              if (!recipeSnapshot.hasData) {
                                return Text(
                                  'Loading recipes...',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                );
                              }

                              final recipes = recipeSnapshot.data!.docs;
                              final int total = recipes.length;
                              final int approved = recipes
                                  .where((r) => (r.data() as Map<String, dynamic>)['status'] == 'approved')
                                  .length;
                              final int pending = total - approved;

                              return Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildBadge('Total: $total', _primaryColor, const Color(0xFFF3EAEB)),
                                  _buildBadge('Approved: $approved', Colors.green.shade800, Colors.green.shade50),
                                  if (pending > 0)
                                    _buildBadge('Pending: $pending', Colors.orange.shade800, Colors.orange.shade50),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}