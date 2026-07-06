import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAkG1hdauVlL9b8nHM5o2B25yPQ6IANci4',
            appId: '1:212430902387:web:149c933fd3d29aa5014606',
            messagingSenderId: '212430902387',
            projectId: 'bharatheeyam-app',
            authDomain: 'bharatheeyam-app.firebaseapp.com',
            storageBucket: 'bharatheeyam-app.firebasestorage.app',
            measurementId: 'G-BNTGY2WSLZ',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      
      _initialized = true;
      debugPrint('FirebaseService: Initialized successfully.');
    } catch (e) {
      debugPrint('FirebaseService: Failed to initialize: $e');
    }
  }
}
