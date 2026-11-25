
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  static const Color _primary = Color(0xFF7A232E);
  static const Color _background = Color(0xFFFAF9F9);

  static const List<String> _dayNames = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  int _selectedDay = 0;
  DateTime _weekStart = _currentWeekStart();

  List<Map<String, dynamic>> _meals = [];

  bool _loading = true;
  bool _saving = false;

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    final daysSinceSaturday = (now.weekday + 1) % 7;

    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysSinceSaturday));
  }

  String get _weekId =>
      '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';

  DocumentReference<Map<String, dynamic>>? get _planRef {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealPlans')
        .doc(_weekId);
  }

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final ref = _planRef;

      if (ref != null) {
        final snapshot = await ref.get();
        final raw = snapshot.data()?['meals'];

        if (raw is List) {
          _meals = raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else {
          _meals = _sampleMeals();
        }
      } else {
        _meals = _sampleMeals();
      }
    } catch (e) {
      _meals = _sampleMeals();

      if (mounted) {
        _showMessage(
          'Meal plan load করা যায়নি। Internet/Firebase check করো।',
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _sampleMeals() => [
    _meal(
      0,
      'Breakfast',
      'Egg & vegetable ruti',
      '8:00 AM',
      20,
      340,
      ['Egg', 'Ruti', 'Vegetables'],
    ),
    _meal(
      0,
      'Lunch',
      'Chicken curry with rice',
      '1:00 PM',
      35,
      520,
      ['Chicken', 'Rice', 'Onion', 'Potato'],
    ),
    _meal(
      0,
      'Dinner',
      'Vegetable khichuri',
      '7:30 PM',
      30,
      390,
      ['Rice', 'Lentils', 'Vegetables'],
    ),
  ];

  Map<String, dynamic> _meal(
      int day,
      String type,
      String title,
      String time,
      int minutes,
      int calories,
      List<String> ingredients,
      ) =>
      {
        'day': day,
        'type': type,
        'title': title,
        'time': time,
        'minutes': minutes,
        'calories': calories,
        'ingredients': ingredients,
      };

  List<Map<String, dynamic>> get _dayMeals {
    final meals = _meals
        .where((meal) => meal['day'] == _selectedDay)
        .toList();

    meals.sort((a, b) {
      final aIndex = _mealTypes.indexOf(a['type'] as String);
      final bIndex = _mealTypes.indexOf(b['type'] as String);
      return aIndex.compareTo(bIndex);
    });

    return meals;
  }

  int get _totalCalories => _dayMeals.fold<int>(
    0,
        (sum, meal) =>
    sum + ((meal['calories'] as num?)?.toInt() ?? 0),
  );

  Future<void> _savePlan() async {
    final ref = _planRef;

    if (ref == null) {
      _showMessage('Cloud-এ save করতে আগে Login করতে হবে।');
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.set({
        'weekStart': Timestamp.fromDate(_weekStart),
        'meals': _meals,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Meal plan Firebase-এ save হয়েছে!');
    } catch (e) {
      _showMessage('Save করা যায়নি: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _dateLabel(int day) {
    final date = _weekStart.add(Duration(days: day));
    return '${date.day}';
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));

    return '${_weekStart.day} ${_month(_weekStart.month)} – '
        '${end.day} ${_month(end.month)} ${end.year}';
  }

  String _month(int month) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month];

  Future<void> _changeWeek(int amount) async {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * amount));
      _selectedDay = 0;
    });

    await _loadPlan();
  }

  Future<void> _openMealEditor({
    Map<String, dynamic>? existing,
  }) async {
    final titleController = TextEditingController(
      text: existing?['title'] as String? ?? '',
    );

    final caloriesController = TextEditingController(
      text: existing?['calories']?.toString() ?? '',
    );

    final minutesController = TextEditingController(
      text: existing?['minutes']?.toString() ?? '20',
    );

    final ingredientsController = TextEditingController(
      text: (existing?['ingredients'] as List?)?.join(', ') ?? '',
    );

    String type = existing?['type'] as String? ?? 'Breakfast';
    String time = existing?['time'] as String? ?? '8:00 AM';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: Text(existing == null ? 'Add meal' : 'Edit meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Meal type',
                  ),
                  items: _mealTypes
                      .map(
                        (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    refreshDialog(() => type = v ?? type);
                  },
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Meal name',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal)',
                  ),
                ),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cooking time (minutes)',
                  ),
                ),
                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients (comma separated)',
                    hintText: 'Rice, egg, onion',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: time,
                  decoration: const InputDecoration(
                    labelText: 'Meal time',
                  ),
                  items: [
                    '7:00 AM',
                    '8:00 AM',
                    '9:00 AM',
                    '12:00 PM',
                    '1:00 PM',
                    '2:00 PM',
                    '6:00 PM',
                    '7:00 PM',
                    '8:00 PM',
                  ]
                      .map(
                        (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    refreshDialog(() => time = v ?? time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final calories =
                int.tryParse(caloriesController.text.trim());
                final minutes =
                int.tryParse(minutesController.text.trim());

                if (title.isEmpty ||
                    calories == null ||
                    calories < 0 ||
                    minutes == null ||
                    minutes < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'সঠিক Meal name, Calories ও time দাও।',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  'day': _selectedDay,
                  'type': type,
                  'title': title,
                  'time': time,
                  'minutes': minutes,
                  'calories': calories,
                  'ingredients': ingredientsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                });
              },
              child: const Text('Save meal'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    caloriesController.dispose();
    minutesController.dispose();
    ingredientsController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (existing == null) {
        _meals.add(result);
      } else {
        final index = _meals.indexOf(existing);
        if (index >= 0) {
          _meals[index] = result;
        }
      }
    });
  }

  void _deleteMeal(Map<String, dynamic> meal) {
    setState(() => _meals.remove(meal));
    _showMessage('Meal remove হয়েছে। Save চাপলে পরিবর্তন স্থায়ী হবে।');
  }

  void _showGroceryList() {
    final items = <String>{};

    for (final meal in _meals) {
      final ingredients = meal['ingredients'];

      if (ingredients is List) {
        items.addAll(ingredients.map((e) => e.toString()));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly grocery list',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text(
                  'Meal-এ ingredients যোগ করলে এখানে দেখা যাবে।',
                )
              else
                ...items.map(
                      (item) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.shopping_basket_outlined,
                      color: _primary,
                    ),
                    title: Text(item),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate =
    _weekStart.add(Duration(days: _selectedDay));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Plan your week',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Save plan',
            onPressed: _saving ? null : _savePlan,
            icon: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.cloud_upload_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: _primary),
      )
          : RefreshIndicator(
        onRefresh: _loadPlan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeWeek(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _weekLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeWeek(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (index) {
                final selected = index == _selectedDay;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = index);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? _primary
                              : Colors.black12,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _dayNames[index].substring(0, 3),
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _dateLabel(index),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Text(
              '${_dayNames[_selectedDay]}’s menu',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${selectedDate.day} ${_month(selectedDate.month)}'
                  ' · ${_dayMeals.length} meals planned',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            if (_dayMeals.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 38,
                      color: _primary,
                    ),
                    SizedBox(height: 8),
                    Text('No meals planned for this day'),
                    Text(
                      'Tap “Add meal” to create your plan.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ..._dayMeals.map(_buildMealCard),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _openMealEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add meal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9EBEC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily meal total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_totalCalories kcal',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Calories are based on the values entered for each meal.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _showGroceryList,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Build weekly grocery list'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              FirebaseAuth.instance.currentUser == null
                  ? 'Login করলে plan Firebase-এ save করতে পারবে।'
                  : 'Save icon চাপলে এই সপ্তাহের plan Firebase-এ save হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _savePlan,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save plan'),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final type = meal['type'] as String? ?? 'Meal';

    final icon = type == 'Breakfast'
        ? Icons.free_breakfast_outlined
        : type == 'Lunch'
        ? Icons.lunch_dining_outlined
        : type == 'Dinner'
        ? Icons.dinner_dining_outlined
        : Icons.local_cafe_outlined;

    final ingredients = (meal['ingredients'] as List? ?? [])
        .map((e) => e.toString())
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF9EBEC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type · ${meal['time'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${meal['minutes'] ?? 0} min · '
                      '${meal['calories'] ?? 0} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (ingredients.isNotEmpty)
                  Text(
                    ingredients,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openMealEditor(existing: meal);
              }

              if (value == 'delete') {
                _deleteMeal(meal);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
