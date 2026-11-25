import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppLang {
  // পুরো অ্যাপের বর্তমান ভাষা ধরে রাখবে
  static final ValueNotifier<String> current = ValueNotifier<String>('English');

  // অ্যাপ চালু হলে Firestore থেকে সেভ করা ভাষা লোড করবে
  static Future<void> loadSavedLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final savedLang = doc.data()?['language'];
      if (savedLang is String && savedLang.isNotEmpty) {
        current.value = savedLang;
      }
    } catch (_) {}
  }

  static void setLanguage(String lang) {
    current.value = lang;
  }

  // অনুবাদের তালিকা
  static const Map<String, Map<String, String>> _translations = {
    'English': {
      'my_kitchen': 'My kitchen',
      'edit_profile': 'Edit profile',
      'made_for_you': 'Made for you',
      'health_condition': 'Health condition',
      'profession': 'Profession',
      'saved_recipes': 'Saved recipes',
      'view_all': 'View all',
      'submit_recipe': 'Submit a Recipe',
      'notifications': 'Notifications',
      'language': 'Language',
      'help_support': 'Help & support',
      'log_out': 'Log out',
      'home': 'Home',
      'explore': 'Explore',
      'grocery': 'Grocery',
      'saved': 'Saved',
      'profile': 'Profile',
      'recommended': 'Recommended for you',
      'popular_recipes': 'Popular recipes',
    },
    'বাংলা': {
      'my_kitchen': 'আমার রান্নাঘর',
      'edit_profile': 'প্রোফাইল এডিট করুন',
      'made_for_you': 'আপনার জন্য তৈরি',
      'health_condition': 'স্বাস্থ্য অবস্থা',
      'profession': 'পেশা',
      'saved_recipes': 'সেভ করা রেসিপি',
      'view_all': 'সব দেখুন',
      'submit_recipe': 'রেসিপি যোগ করুন',
      'notifications': 'নোটিফিকেশন',
      'language': 'ভাষা',
      'help_support': 'সাহায্য ও সাপোর্ট',
      'log_out': 'লগ আউট',
      'home': 'হোম',
      'explore': 'এক্সপ্লোর',
      'grocery': 'বাজার',
      'saved': 'সেভড',
      'profile': 'প্রোফাইল',
      'recommended': 'আপনার জন্য বাছাইকৃত',
      'popular_recipes': 'জনপ্রিয় রেসিপি',
    },
  };

  // যেকোনো পেজে টেক্সট দেখানোর শর্টকাট: AppLang.t('my_kitchen')
  static String t(String key) {
    final langMap = _translations[current.value] ?? _translations['English']!;
    return langMap[key] ?? _translations['English']![key] ?? key;
  }
}