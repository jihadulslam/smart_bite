import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cooking_mode_page.dart';
import 'nutrition_page.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final Color _primaryColor = const Color(0xFF7A232E);
  bool isBookmarked = true;

  Future<void> _toggleSaveRecipe({
    required String recipeId,
    required String title,
    required String time,
    required String region,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save recipes.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .doc(recipeId);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved recipes')),
        );
      }
    } else {
      await docRef.set({
        'recipeId': recipeId,
        'title': title,
        'time': time,
        'region': region,
        'imageUrl': imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Ingredients Data
  final List<Map<String, String>> ingredients = [
    {'name': 'Chicken breast', 'amount': '300 g'},
    {'name': 'Lemon', 'amount': '1 medium'},
    {'name': 'Onion', 'amount': '1 medium'},
    {'name': 'Plain yogurt', 'amount': '60 g'},
    {'name': 'Ginger-garlic paste', 'amount': '1 tbsp'},
    {'name': 'Turmeric', 'amount': '½ tsp'},
    {'name': 'Mustard oil', 'amount': '2 tsp'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7A232E),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CookingModePage()));
        },
        icon: const Icon(Icons.restaurant_menu, color: Colors.white),
        label: const Text('Start Cooking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Back & Bookmark Buttons
            Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=800',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Top Action Buttons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: Icon(Icons.arrow_back, color: _primaryColor),
                          ),
                        ),
                        // Bookmark Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isBookmarked = !isBookmarked;
                            });
                            // Call the save logic here
                            // Assume we receive these details through constructor normally.
                            // For now, using placeholders to demonstrate.
                            _toggleSaveRecipe(
                              recipeId: 'demo_recipe_id',
                              title: 'Sylheti Lemon Chicken',
                              time: '30 min',
                              region: 'Sylhet',
                              imageUrl: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500',
                            );
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Location Tag Overlay
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Sylhet',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Recipe Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  const Text(
                    'Sylheti lemon chicken',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A lighter take on a zesty Sylheti favourite.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Health Tags
                  Row(
                    children: [
                      _buildTag('Diabetic Friendly'),
                      const SizedBox(width: 8),
                      _buildTag('High Protein'),
                      const SizedBox(width: 8),
                      _buildTag('Low Sugar'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meta Data (Time, Calories, Servings)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaInfo(Icons.access_time, '30 min'),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NutritionPage()));
                        },
                        child: _buildMetaInfo(Icons.local_fire_department_outlined, '285 kcal'),
                      ),
                      _buildMetaInfo(Icons.people_outline, '2 servings'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200, thickness: 1),
                  const SizedBox(height: 16),

                  // Ingredients Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'For 2 servings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ingredients List
                  ...ingredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ingredient['name']!,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                        Text(
                          ingredient['amount']!,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 16),

                  // Footer Note
                  Text(
                    'Nutrition is estimated per serving. Adjust portions to your personal health needs.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Button for Grocery List
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, // Maroon color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Grocery List!')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shopping_basket_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add to Grocery List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for Tags
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper Widget for Meta Info (Time, Calories, Servings)
  Widget _buildMetaInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
