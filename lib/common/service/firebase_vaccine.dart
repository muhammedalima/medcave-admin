import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseVaccineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a new vaccine
  Future<void> addVaccine({
    required String name,
    required String description,
    required String ageGroup,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final vaccineData = {
      'name': name,
      'description': description,
      'ageGroup': ageGroup,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('vaccinedetails')
        .add(vaccineData);
  }

  // Update an existing vaccine
  Future<void> updateVaccine({
    required String vaccineId,
    required String name,
    required String description,
    required String ageGroup,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final vaccineData = {
      'name': name,
      'description': description,
      'ageGroup': ageGroup,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('vaccinedetails')
        .doc(vaccineId)
        .update(vaccineData);
  }

  // Delete a vaccine
  Future<void> deleteVaccine(String vaccineId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('vaccinedetails')
        .doc(vaccineId)
        .delete();
  }

  // Get stream of vaccines
  Stream<QuerySnapshot> getVaccinesStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('vaccinedetails')
        .snapshots();
  }
}
