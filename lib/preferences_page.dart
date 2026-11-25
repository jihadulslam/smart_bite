cimport 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final Color _primaryColor = const Color(0xFF7A232E);
  final Color _chipInactiveBg = const Color(0xFFF9EBEC);
  final Color _greenText = const Color(0xFF2E7D32);
  final Color _greenBg = const Color(0xFFE8F5E9);

  final Set<String> _selectedFoodPrefs = {
    'Fish & chicken',
    'Local flavours',
    'Quick meals',
  };
  final Set<String> _selectedHealthConds = {'Diabetes'};
  final Set<String> _selectedDietTags = {'Diabetic Friendly', 'Low Sugar'};
  final Set<String> _selectedRoutines = {'Early start', 'Cook in 30 min'};

  String _selectedProfession = 'School teacher';
  final List<String> _professions = [
    'School teacher',
    'Doctor',
    'Engineer',
    'Student',
    'Other',
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data['foodPreferences'] is List) {
          _selectedFoodPrefs
            ..clear()
            ..addAll(List<String>.from(data['foodPreferences']));
        }
        if (data['selectedHealthConds'] is List) {
          _selectedHealthConds
            ..clear()
            ..addAll(List<String>.from(data['selectedHealthConds']));
        }
        if (data['selectedDietTags'] is List) {
          _selectedDietTags
            ..clear()
            ..addAll(List<String>.from(data['selectedDietTags']));
        }
        if (data['dailyRoutines'] is List) {
          _selectedRoutines
            ..clear()
            ..addAll(List<String>.from(data['dailyRoutines']));
        }
        if (data['profession'] is String &&
            _professions.contains(data['profession'])) {
          _selectedProfession = data['profession'];
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to save your preferences.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Profile-এর Made for you কার্ডে দেখানোর জন্য হেলথ ট্যাগ লিস্ট তৈরি
      final List<String> displayHealthTags = {
        ..._selectedDietTags,
        ..._selectedHealthConds.where((c) => c != 'None'),
      }.toList();

      // Food preferences ও Routine থেকে সংক্ষিপ্ত নোট তৈরি
      final List<String> summaryParts = [
        ..._selectedFoodPrefs,
        ..._selectedRoutines,
      ];
      final String mealNote = summaryParts.isEmpty
          ? 'Quick meals for your busy weekdays.'
          : summaryParts.take(3).join(' · ');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'foodPreferences': _selectedFoodPrefs.toList(),
        'selectedHealthConds': _selectedHealthConds.toList(),
        'selectedDietTags': _selectedDietTags.toList(),
        'dailyRoutines': _selectedRoutines.toList(),
        'healthConditions': displayHealthTags,
        'profession': _selectedProfession,
        'mealNote': mealNote,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated!'),
            backgroundColor: Colors.green,
          ),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFAF9F9),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          elevation: 0,
          title: const Text(
            'Made for you',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () {},
            ),
          ],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
              'YOUR KITCHEN • STEP 2 OF 2',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 😎,
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Good food, your way.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 😎,
                Text(
                  'Tell us what fits your taste and everyday life.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Food preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Fish & chicken', _selectedFoodPrefs),
                    _buildChip('Vegetarian', _selectedFoodPrefs),
                    _buildChip('Mild spice', _selectedFoodPrefs),
                    _buildChip('Local flavours', _selectedFoodPrefs),
                    _buildChip('Quick meals', _selectedFoodPrefs),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health conditions • optional',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHealthChip('Diabetes'),
                          _buildHealthChip('Hypertension'),
                          _buildHealthChip('None'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildGreenChip('Diabetic Friendly', _selectedDietTags),
                          _buildGreenChip('Low Sugar', _selectedDietTags),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preferences guide recipe suggestions, not medical advice. You can skip or change these anytime.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Profession',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProfession,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _professions.map((String profession) {
                    return DropdownMenuItem<String>(
                      value: profession,
                      child: Text(
                        profession,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedProfession = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'Daily routine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Early start', _selectedRoutines),
                    _buildChip('Desk-based', _selectedRoutines),
                    _buildChip('Active day', _selectedRoutines),
                    _buildChip('Cook in 30 min', _selectedRoutines),
                    _buildChip('Weekend prep', _selectedRoutines),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Only you can see your health preferences.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F9),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isLoading || _isSaving) ? null : _savePreferences,
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Personalize my kitchen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }

  Widget _buildHealthChip(String label) {
    final isSelected = _selectedHealthConds.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'None') {
            if (isSelected) {
              _selectedHealthConds.remove('None');
            } else {
              _selectedHealthConds
                ..clear()
                ..add('None');
            }
          } else {
            _selectedHealthConds.remove('None');
            if (isSelected) {
              _selectedHealthConds.remove(label);
            } else {
              _selectedHealthConds.add(label);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _chipInactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Set<String> selectedSet) {
    final isSelected = selectedSet.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? selectedSet.remove(label) : selectedSet.add(label);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _chipInactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGreenChip(String label, Set<String> selectedSet) {
    final isSelected = selectedSet.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? selectedSet.remove(label) : selectedSet.add(label);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _greenBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _greenText : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}