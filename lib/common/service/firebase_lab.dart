import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseComponentService2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a new lab test
  Future<void> addLabTest({
    required String name,
    required double price,
    required String prerequisites,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final labTestData = {
      'name': name,
      'price': price,
      'prerequisites': prerequisites,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('labdetails')
        .add(labTestData);
  }

  // Update an existing lab test
  Future<void> updateLabTest({
    required String labTestId,
    required String name,
    required double price,
    required String prerequisites,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final labTestData = {
      'name': name,
      'price': price,
      'prerequisites': prerequisites,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('labdetails')
        .doc(labTestId)
        .update(labTestData);
  }

  // Delete a lab test
  Future<void> deleteLabTest(String labTestId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('labdetails')
        .doc(labTestId)
        .delete();
  }

  // Get stream of lab tests
  Stream<QuerySnapshot> getLabTestsStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('labdetails')
        .snapshots();
  }
}