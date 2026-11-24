import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_page.dart';
import 'explore_page.dart';
import 'grocery_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'app_language.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color _primaryColor = const Color(0xFF7A232E);

  String userName = "User";
  bool isLoading = true;
  int _currentIndex = 0;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Use authStateChanges to automatically update UI on login/logout
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData(user);
      } else {
        if (mounted) {
          setState(() {
            userName = "User";
            isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData(User currentUser) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          userName = userDoc.get('fullName') ?? "User";
          isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<String> _getMatchedTags(
    Map<String, dynamic> recipe,
    List<String> userTags,
    List<String> dailyRoutines,
  ) {
    final List<String> matched = [];

    // রেসিপির ট্যাগ, ক্যাটাগরি ও টাইটেল একসাথে ছোট হাতের অক্ষরে নেওয়া
    final List<String> recipeTags = recipe['tags'] is List
        ? List<String>.from(recipe['tags']).map((e) => e.toLowerCase()).toList()
        : [];
    final String searchableText = [
      recipe['title']?.toString() ?? '',
      recipe['category']?.toString() ?? '',
      recipe['description']?.toString() ?? '',
      ...recipeTags,
    ].join(' ').toLowerCase();

    for (final tag in userTags) {
      final lowerTag = tag.toLowerCase();
      // সরাসরি ট্যাগ বা কীওয়ার্ড মিললে লিস্টে যোগ করবে
      if (recipeTags.contains(lowerTag) || searchableText.contains(lowerTag)) {
        matched.add(tag);
      } else if (lowerTag == 'fish & chicken' &&
          (searchableText.contains('fish') || searchableText.contains('chicken'))) {
        matched.add(tag);
      } else if (lowerTag == 'diabetic friendly' &&
          searchableText.contains('diabetic')) {
        matched.add(tag);
      }
    }

    // ইউজারের রুটিনে 'Cook in 30 min' থাকলে ৩০ মিনিট বা তার কম সময়ের রেসিপি ম্যাচ করবে
    if (dailyRoutines.contains('Cook in 30 min')) {
      final timeStr = recipe['time']?.toString() ?? '';
      final minutesMatch = RegExp(r'\d+').firstMatch(timeStr);
      if (minutesMatch != null) {
        final int minutes = int.tryParse(minutesMatch.group(0)!) ?? 99;
        if (minutes <= 30) {
          matched.add('Under 30 min');
        }
      }
    }

    return matched;
  }

  Widget _buildRecommendedSection() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // ইউজার লগইন না থাকলে সরাসরি সাধারণ রেসিপি দেখাবে
    if (currentUser == null) {
      return _buildRecipesList(
        healthConditions: const [],
        foodPreferences: const [],
        dailyRoutines: const [],
        isLoggedIn: false,
      );
    }

    // ইউজার লগইন থাকলে তার Made for you ডেটা লাইভ পড়বে
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        List<String> healthConditions = [];
        List<String> foodPreferences = [];
        List<String> dailyRoutines = [];

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData?['healthConditions'] is List) {
            healthConditions = List<String>.from(userData!['healthConditions']);
          }
          if (userData?['foodPreferences'] is List) {
            foodPreferences = List<String>.from(userData!['foodPreferences']);
          }
          if (userData?['dailyRoutines'] is List) {
            dailyRoutines = List<String>.from(userData!['dailyRoutines']);
          }
        }

        return _buildRecipesList(
          healthConditions: healthConditions,
          foodPreferences: foodPreferences,
          dailyRoutines: dailyRoutines,
          isLoggedIn: true,
        );
      },
    );
  }

  Widget _buildRecipesList({
    required List<String> healthConditions,
    required List<String> foodPreferences,
    required List<String> dailyRoutines,
    required bool isLoggedIn,
  }) {
    final List<String> allUserTags = [...healthConditions, ...foodPreferences];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLoggedIn && allUserTags.isNotEmpty
                    ? AppLang.t('recommended')
                    : AppLang.t('popular_recipes'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (healthConditions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    healthConditions.first,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 235,
          child: StreamBuilder<QuerySnapshot>(
            // আপনার Firestore কালেকশনের নাম আলাদা হলে 'recipes' পরিবর্তন করবেন
            stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
            builder: (context, recipeSnapshot) {
              if (recipeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7A232E)),
                );
              }

              if (!recipeSnapshot.hasData || recipeSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No recipes available yet.'));
              }

              // প্রতিটি রেসিপির সাথে কতগুলো ট্যাগ মিলছে তা হিসাব করা
              final List<Map<String, dynamic>> scoredRecipes =
                  recipeSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final matched = _getMatchedTags(data, allUserTags, dailyRoutines);
                return {
                  'id': doc.id,
                  'data': data,
                  'matchedTags': matched,
                  'score': matched.length,
                };
              }).toList();

              // যেগুলোর ম্যাচিং স্কোর বেশি সেগুলো সবার আগে দেখাবে
              scoredRecipes.sort(
                (a, b) => (b['score'] as int).compareTo(a['score'] as int),
              );

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scoredRecipes.length,
                itemBuilder: (context, index) {
                  final item = scoredRecipes[index];
                  final data = item['data'] as Map<String, dynamic>;
                  final matchedTags = item['matchedTags'] as List<String>;

                  final String title = data['title'] ?? 'Untitled Recipe';
                  final String time = data['time'] ?? '30 min';
                  final String imageUrl = data['imageUrl'] ?? data['image'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      // এখানে আপনার RecipeDetailPage-এ পাঠাবেন
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeDetailPage()));
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 14, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 115,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 115,
                                      color: const Color(0xFFF3EAEB),
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Color(0xFF7A232E),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 115,
                                    width: double.infinity,
                                    color: const Color(0xFFF3EAEB),
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Color(0xFF7A232E),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (matchedTags.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF5EC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '✓ ${matchedTags.first}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F9),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 28.0),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "What's cooking today?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search recipes, ingredients...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: _primaryColor),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.black54),
                          onPressed: () {},
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'District-wise categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryItem('Dhaka', Icons.location_city),
                          _buildCategoryItem('Sylhet', Icons.landscape),
                          _buildCategoryItem('Chattogram', Icons.waves),
                          _buildCategoryItem('Rajshahi', Icons.wb_sunny),
                          _buildCategoryItem('Khulna', Icons.nature),
                          _buildCategoryItem('Barishal', Icons.directions_boat),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    _buildRecommendedSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExplorePage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GroceryPage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPage()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_outlined),
            activeIcon: Icon(Icons.shopping_basket),
            label: 'Grocery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primaryColor, size: 26),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard({
    required String title,
    required String tag,
    required String time,
    required String calories,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecipeDetailPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    radius: 16,
                    child: Icon(Icons.bookmark_border, color: _primaryColor, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$time • $calories',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}