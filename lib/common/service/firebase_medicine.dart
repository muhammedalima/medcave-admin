import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseMedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a new medicine
  Future<void> addMedicine({
    required String name,
    required String description,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final medicineData = {
      'name': name,
      'description': description,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('medicinedetails')
        .add(medicineData);
  }

  // Update an existing medicine
  Future<void> updateMedicine({
    required String medicineId,
    required String name,
    required String description,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final medicineData = {
      'name': name,
      'description': description,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('medicinedetails')
        .doc(medicineId)
        .update(medicineData);
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('medicinedetails')
        .doc(medicineId)
        .delete();
  }

  // Get stream of medicines
  Stream<QuerySnapshot> getMedicinesStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('medicinedetails')
        .snapshots();
  }
}
