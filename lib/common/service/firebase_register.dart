import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseRegister {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate verification code (example logic, replace with your own)
  Future<bool> validateVerificationCode(String code) async {
    try {
      // Simulate a check against a valid code (e.g., from Firestore or a server)
      final QuerySnapshot snapshot = await _firestore
          .collection('verificationCodes')
          .where('code', isEqualTo: code)
          .where('used', isEqualTo: false)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating code: $e');
      }
      return false;
    }
  }

  // Register admin with Firebase Authentication and Firestore
  Future<String?> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String hospitalName,
    required String hospitalAddress,
    required String phone,
    required String verificationCode,
    // Added palliative care parameters
    bool hasPalliativeCare = false,
    String palliativeCareDescription = '',
    String palliativeCareContact = '',
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional admin data in Firestore
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'hospitalName': hospitalName,
        'hospitalAddress': hospitalAddress,
        'phone': phone,
        'verificationCode': verificationCode,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false, // Verification pending
        // Added palliative care fields
        'hasPalliativeCare': hasPalliativeCare,
        'palliativeCareDescription': palliativeCareDescription,
        'palliativeCareContact': palliativeCareContact,
      });

      // Mark verification code as used (example)
      final QuerySnapshot codeSnapshot = await _firestore
          .collection('verificationCodes')
          .where('code', isEqualTo: verificationCode)
          .limit(1)
          .get();
      if (codeSnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('verificationCodes')
            .doc(codeSnapshot.docs.first.id)
            .update({'used': true});
      }

      return null; // Success
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return e.toString();
    }
  }
}
