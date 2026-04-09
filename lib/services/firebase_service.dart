import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import 'google_auth_service.dart';
import 'appointment_service.dart';

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

  /// Start listening for new appointment requests from Firestore.
  /// Call this AFTER the user has signed in.
  static void listenForAppointments() {
    final email = GoogleAuthService.userEmail;
    if (email == null || email.isEmpty) {
      debugPrint('FirebaseService: No email found, cannot listen for appointments.');
      return;
    }

    debugPrint('FirebaseService: Listening for new appointments for $email...');

    FirebaseFirestore.instance
        .collection('appointments')
        .doc(email)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          debugPrint('FirebaseService: New appointment request received: $data');

          try {
            // Add it to our local calendar
            final clientName = data['clientName'] ?? 'Unknown Client';
            final clientPhone = data['clientPhone'] ?? '';
            final dateTimeStr = data['dateTime'] ?? ''; // e.g. "2026-03-28T10:00:00"
            final start = DateTime.tryParse(dateTimeStr) ?? DateTime.now();
            final end = start.add(const Duration(minutes: 60));

            // Format times to HH:mm
            final startStr = '${start.hour.toString().padLeft(2,'0')}:${start.minute.toString().padLeft(2,'0')}';
            final endStr = '${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}';

            // Create locally
            await AppointmentService.addAppointment(
              date: start,
              startTime: startStr,
              endTime: endStr,
              clientName: clientName,
              clientPhone: clientPhone,
              notes: 'Website Booking (Auto-Synced)',
            );

            // Mark as processed in Firestore so we don't process it again
            await change.doc.reference.update({'status': 'processed'});

            debugPrint('FirebaseService: Appointment processed and saved locally.');

            // Show an in-app push notification
            if (navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text('📅 ಹೊಸ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್: $clientName @ $startStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  backgroundColor: Colors.teal,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                ),
              );
            }
          } catch (e) {
            debugPrint('FirebaseService: Error processing appointment: $e');
          }
        }
      }
    });
  }
}
