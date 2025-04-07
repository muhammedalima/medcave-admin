import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import)

import 'package:medcave/common/service/firebase_register.dart';

class PalliativeCareTab extends StatelessWidget {
  final Function(String) logActivity;
  final FirebaseRegister _firebaseRegister =
      FirebaseRegister(); // Instance of FirebaseRegister

  PalliativeCareTab({required this.logActivity, super.key});

  static void showEditDialog(
      BuildContext context, Function(String) logActivity) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Handle case where user isn't logged in

    FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get()
        .then((doc) {
      final data = doc.data() ?? {};
      final descriptionController =
          TextEditingController(text: data['palliativeCareDescription'] ?? '');
      final contactNumberController =
          TextEditingController(text: data['palliativeCareContact'] ?? '');
      bool isAvailable = data['hasPalliativeCare'] ?? false;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Palliative Care Information'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            hintText:
                                'Describe the palliative care services offered'),
                        maxLines: 5),
                    const SizedBox(height: 16),
                    TextField(
                        controller: contactNumberController,
                        decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            hintText: 'e.g., +91 98765 43210'),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    SwitchListTile(
                        title: const Text('Service Available'),
                        subtitle: const Text(
                            'Toggle to show/hide palliative care services'),
                        value: isAvailable,
                        onChanged: (value) =>
                            setState(() => isAvailable = value)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('admins')
                        .doc(user.uid)
                        .update({
                      'palliativeCareDescription':
                          descriptionController.text.trim(),
                      'palliativeCareContact':
                          contactNumberController.text.trim(),
                      'hasPalliativeCare': isAvailable,
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });
                    logActivity('Updated palliative care information');
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    }).catchError((error) {
      final descriptionController = TextEditingController();
      final contactNumberController = TextEditingController();
      bool isAvailable = false;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Palliative Care Information'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            hintText:
                                'Describe the palliative care services offered'),
                        maxLines: 5),
                    const SizedBox(height: 16),
                    TextField(
                        controller: contactNumberController,
                        decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            hintText: 'e.g., +91 98765 43210'),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    SwitchListTile(
                        title: const Text('Service Available'),
                        subtitle: const Text(
                            'Toggle to show/hide palliative care services'),
                        value: isAvailable,
                        onChanged: (value) =>
                            setState(() => isAvailable = value)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('admins')
                        .doc(user.uid)
                        .set({
                      'palliativeCareDescription':
                          descriptionController.text.trim(),
                      'palliativeCareContact':
                          contactNumberController.text.trim(),
                      'hasPalliativeCare': isAvailable,
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastUpdated': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    logActivity('Created palliative care information');
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
          child: Text('Please log in to view this information'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final description = data['palliativeCareDescription'] as String? ?? '';
        final contactNumber = data['palliativeCareContact'] as String? ?? '';
        final isAvailable = data['hasPalliativeCare'] as bool? ?? false;
        final timestamp = data['lastUpdated'] as Timestamp?;
        final lastUpdatedText = timestamp != null
            ? 'Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())}'
            : '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Palliative Care Unit',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              isAvailable ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: isAvailable
                                ? Colors.green[100]
                                : Colors.red[100],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty) ...[
                            const Text(
                              'Description:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(description),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (contactNumber.isNotEmpty) ...[
                            const Text(
                              'Contact Number:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    contactNumber,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (lastUpdatedText.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                lastUpdatedText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Palliative Care Information'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () => showEditDialog(context, logActivity),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
