import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final Color _primaryColor = const Color(0xFF7A232E);
  final Color _bgColor = const Color(0xFFFAF9F9);
  final String _adminEmail = "admin1@gmail.com";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  String _selectedRegion = 'Dhaka';
  final List<String> _regions = [
    'Dhaka',
    'Sylhet',
    'Chattogram',
    'Khulna',
    'Rajshahi',
    'Barishal',
    'Rangpur',
  ];

  final List<String> _availableHealthTags = [
    'Diabetic Friendly',
    'Low Sugar',
    'High Protein',
    'Quick Meal',
    'Low Carb',
  ];
  final List<String> _selectedHealthTags = [];

  bool _isLoading = false;

  Future<void> _submitRecipe() async {
    if (_titleController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _ingredientsController.text.trim().isEmpty ||
        _stepsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String recipeStatus =
          (currentUser != null && currentUser.email == _adminEmail)
              ? 'approved'
              : 'pending';

      // প্রতি লাইনের টেক্সটকে আলাদা লিস্ট আইটেমে রূপান্তর
      final List<String> ingredientsList = _ingredientsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final List<String> stepsList = _stepsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final String imageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500';

      await FirebaseFirestore.instance.collection('recipes').add({
        'title': _titleController.text.trim(),
        'imageUrl': imageUrl,
        'time': _timeController.text.trim(),
        'calories': _caloriesController.text.trim().isNotEmpty
            ? _caloriesController.text.trim()
            : '250 kcal',
        'tag': _selectedRegion,
        'healthTags': _selectedHealthTags,
        'ingredients': ingredientsList,
        'steps': stepsList,
        'status': recipeStatus,
        'authorId': currentUser?.uid ?? 'unknown',
        'authorEmail': currentUser?.email ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recipeStatus == 'approved'
                  ? 'Recipe published live!'
                  : 'Recipe submitted for admin approval!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _timeController.dispose();
    _caloriesController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add a Recipe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Recipe Title *'),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g., Sylheti Lemon Chicken',
              icon: Icons.restaurant_menu,
            ),
            const SizedBox(height: 16),

            _buildLabel('Image URL (Optional)'),
            _buildTextField(
              controller: _imageUrlController,
              hint: 'https://example.com/food.jpg',
              icon: Icons.image_outlined,
            ),
            const SizedBox(height: 16),

            // Time & Calories Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Cooking Time *'),
                      _buildTextField(
                        controller: _timeController,
                        hint: 'e.g., 30 min',
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Calories'),
                      _buildTextField(
                        controller: _caloriesController,
                        hint: 'e.g., 320 kcal',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Region Dropdown
            _buildLabel('Region / District'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRegion,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
                  items: _regions.map((region) {
                    return DropdownMenuItem(value: region, child: Text(region));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRegion = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Health Tags Chips
            _buildLabel('Health Tags (Select applicable)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableHealthTags.map((tag) {
                final bool isSelected = _selectedHealthTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEAF5EC),
                  checkmarkColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedHealthTags.add(tag);
                      } else {
                        _selectedHealthTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Ingredients
            _buildLabel('Ingredients * (One per line)'),
            _buildMultilineField(
              controller: _ingredientsController,
              hint: '500g Chicken\n2 tbsp Lemon juice\n1 tsp Turmeric...',
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Cooking Steps
            _buildLabel('Cooking Steps * (One step per line)'),
            _buildMultilineField(
              controller: _stepsController,
              hint: '1. Marinate chicken with spices for 20 min.\n2. Heat oil and fry onions...',
              maxLines: 5,
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitRecipe,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Recipe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: _primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}