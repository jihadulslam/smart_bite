import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'grocery_page.dart';
import 'saved_page.dart';
import 'login_page.dart';
import 'admin_dashboard.dart';
import 'add_recipe_page.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'preferences_page.dart';
import 'notification_service.dart';
import 'app_language.dart';
import 'help_support_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color _primaryColor = const Color(0xFF7A232E);
  final Color _bgColor = const Color(0xFFFAF9F9);
  final int _currentIndex = 4;

  final String userLocation = "Dhaka, Bangladesh";
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: _primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveProfilePic(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: _primaryColor),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveProfilePic(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppLang.t('language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption('English', user, sheetContext),
                _buildLanguageOption('বাংলা', user, sheetContext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String langName, User user, BuildContext sheetContext) {
    final bool isSelected = AppLang.current.value == langName;

    return ListTile(
      onTap: () async {
        AppLang.setLanguage(langName);
        Navigator.pop(sheetContext);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'language': langName,
        }, SetOptions(merge: true));
      },
      leading: Icon(
        Icons.language,
        color: isSelected ? _primaryColor : Colors.grey,
      ),
      title: Text(
        langName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? _primaryColor : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: _primaryColor)
          : null,
    );
  }

  void _showNotificationSheet(User user, bool initialEnabled) {
    bool isEnabled = initialEnabled;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: _primaryColor,
                      title: const Text(
                        'Daily Meal & Recipe Alerts',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Get personalized recipe reminders on your phone',
                      ),
                      value: isEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final granted =
                              await NotificationService.requestPermission();
                          if (!granted) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification permission denied from phone settings.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            return;
                          }
                          await NotificationService.scheduleDailyReminder();
                          await NotificationService.showNotification(
                            title: 'SmartBite Notifications On 🔔',
                            body: 'You will now receive daily recipe suggestions!',
                          );
                        } else {
                          await NotificationService.cancelAll();
                        }

                        setSheetState(() => isEnabled = value);

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'notificationsEnabled': value,
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.notifications_active, color: _primaryColor),
                        label: Text(
                          'Send Test Notification',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: !isEnabled
                            ? null
                            : () async {
                                await NotificationService.requestPermission();
                                await NotificationService.showNotification(
                                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                                  title: 'SmartBite Recipe Alert 🍛',
                                  body: 'New healthy recipes matching your preferences are waiting!',
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndSaveProfilePic(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final Uint8List imageBytes = await pickedFile.readAsBytes();

      if (imageBytes.lengthInBytes > 500 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ছবির সাইজ বেশি বড়, অনুগ্রহ করে অন্য ছবি দিন।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profilePicBase64': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  ImageProvider? _getProfileImage(String? base64String, String? url) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (_) {}
    }
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLang.t('my_kitchen'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          final User? user = snapshot.data;

          if (user == null) {
            return _buildGuestView();
          }

          return _buildLoggedInView(user);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ExplorePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GroceryPage()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SavedPage()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: AppLang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore), label: AppLang.t('explore')),
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_basket_outlined), activeIcon: const Icon(Icons.shopping_basket), label: AppLang.t('grocery')),
          BottomNavigationBarItem(icon: const Icon(Icons.bookmark_border), activeIcon: const Icon(Icons.bookmark), label: AppLang.t('saved')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: AppLang.t('profile')),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFF3EAEB),
              child: Text('👨🏻', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to SmartBite',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in to view your profile, health preferences, and saved recipes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Log In Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic>? data;
              if (snapshot.hasData && snapshot.data!.exists) {
                data = snapshot.data!.data() as Map<String, dynamic>?;
              }

              final String displayName = data?['fullName'] ??
                  user.displayName ??
                  (user.email != null ? user.email!.split('@')[0] : 'SmartBite User');

              final ImageProvider? profileImage = _getProfileImage(
                data?['profilePicBase64'],
                data?['profilePic'] ?? user.photoURL,
              );

              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _showImagePickerOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFFF3EAEB),
                            backgroundImage: profileImage,
                            child: _isUploadingPhoto
                                ? CircularProgressIndicator(
                                    color: _primaryColor,
                                    strokeWidth: 2.5,
                                  )
                                : (profileImage == null
                                    ? const Text('👨🏻', style: TextStyle(fontSize: 40))
                                    : null),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userLocation,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfilePage()),
                              );
                            },
                            child: Text(
                              AppLang.t('edit_profile'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLang.t('made_for_you'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferencesPage()),
                        );
                      },
                      child: Icon(Icons.edit_outlined, color: _primaryColor, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  AppLang.t('health_condition'),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGreenChip('Diabetic Friendly'),
                    const SizedBox(width: 8),
                    _buildGreenChip('Low Sugar'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLang.t('profession'),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const Text(
                      'School teacher',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Quick meals for your busy weekdays.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('saved_recipes')
                .orderBy('savedAt', descending: true)
                .snapshots(),
            builder: (context, savedSnapshot) {
              final docs = savedSnapshot.data?.docs ?? [];
              final int savedCount = docs.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLang.t('saved_recipes'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SavedPage()),
                          );
                        },
                        child: Text(
                          '${AppLang.t('view_all')} · $savedCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExplorePage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'No saved recipes yet. Tap to explore recipes.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final data = docs.first.data() as Map<String, dynamic>;
                        final String title = data['title'] ?? 'Saved Recipe';
                        final String time = data['time'] ?? '30 min';
                        final String region = data['region'] ?? 'Bangladesh';
                        final String imageUrl = data['imageUrl'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SavedPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 75,
                                            height: 75,
                                            color: const Color(0xFFF3EAEB),
                                            child: Icon(Icons.restaurant, color: _primaryColor),
                                          ),
                                        )
                                      : Container(
                                          width: 75,
                                          height: 75,
                                          color: const Color(0xFFF3EAEB),
                                          child: Icon(Icons.restaurant, color: _primaryColor),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$time · $region',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (user.email == 'admin1@gmail.com') ...[
                  _buildOptionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Dashboard',
                    trailingText: 'Admin',
                    iconColor: _primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboard()),
                      );
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                ],

                _buildOptionTile(
                  icon: Icons.add_circle_outline,
                  title: AppLang.t('submit_recipe'),
                  trailingText: '',
                  iconColor: _primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddRecipePage()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade100),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final bool isNotifOn = data?['notificationsEnabled'] ?? true;

                    return _buildOptionTile(
                      icon: isNotifOn
                          ? Icons.notifications_none
                          : Icons.notifications_off_outlined,
                      title: AppLang.t('notifications'),
                      trailingText: isNotifOn ? 'On' : 'Off',
                      iconColor: _primaryColor,
                      onTap: () => _showNotificationSheet(user, isNotifOn),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildOptionTile(
                  icon: Icons.translate,
                  title: AppLang.t('language'),
                  trailingText: AppLang.current.value,
                  iconColor: _primaryColor,
                  onTap: () => _showLanguageSheet(user),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildOptionTile(
                  icon: Icons.help_outline,
                  title: AppLang.t('help_support'),
                  trailingText: '',
                  iconColor: _primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildOptionTile(
                  icon: Icons.logout,
                  title: AppLang.t('log_out'),
                  trailingText: '',
                  iconColor: Colors.grey.shade600,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGreenChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String trailingText,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Text(
              trailingText,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}