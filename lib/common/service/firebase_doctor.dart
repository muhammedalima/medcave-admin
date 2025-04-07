import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseComponentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a new doctor
  Future<void> addDoctor({
    required String firstName,
    required String lastName,
    required String specialization,
    required int experience,
    required List<String> timeslots,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doctorData = {
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
      'experience': experience,
      'timeslots': timeslots,
      'available': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('doctorsdetails')
        .add(doctorData);
  }

  // Update an existing doctor
  Future<void> updateDoctor({
    required String doctorId,
    required String firstName,
    required String lastName,
    required String specialization,
    required int experience,
    required List<String> timeslots,
    required bool isAvailable,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doctorData = {
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
      'experience': experience,
      'timeslots': timeslots,
      'available': isAvailable,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('doctorsdetails')
        .doc(doctorId)
        .update(doctorData);
  }

  // Delete a doctor
  Future<void> deleteDoctor(String doctorId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('doctorsdetails')
        .doc(doctorId)
        .delete();
  }

  // Get stream of doctors
  Stream<QuerySnapshot> getDoctorsStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('HospitalData')
        .doc(currentUserId)
        .collection('doctorsdetails')
        .snapshots();
  }
}