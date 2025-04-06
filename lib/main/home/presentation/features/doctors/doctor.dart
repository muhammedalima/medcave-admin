import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorsTab extends StatelessWidget {
  final String searchQuery;
  final Function(String) logActivity;

  const DoctorsTab({required this.searchQuery, required this.logActivity, super.key});

  static void showAddDialog(BuildContext context, Function(String) logActivity) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final specializationController = TextEditingController();
    final experienceController = TextEditingController();
    bool isAvailable = true;
    List<String> timeslots = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Doctor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name*', border: OutlineInputBorder()))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name*', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: specializationController, decoration: const InputDecoration(labelText: 'Specialization*', border: OutlineInputBorder(), hintText: 'E.g., Cardiology, Pediatrics')),
                  const SizedBox(height: 16),
                  TextField(controller: experienceController, decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text('Time Slots:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (String slot in timeslots)
                        Chip(label: Text(slot), onDeleted: () => setState(() => timeslots.remove(slot))),
                      ActionChip(
                        label: const Text('Add Time Slot'),
                        avatar: const Icon(Icons.add),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) {
                            setState(() {
                              final String formattedTime = DateFormat('h:mm a').format(DateTime(2022, 1, 1, time.hour, time.minute));
                              if (!timeslots.contains(formattedTime)) timeslots.add(formattedTime);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(title: const Text('Available'), value: isAvailable, onChanged: (value) => setState(() => isAvailable = value)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty || specializationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  FirebaseFirestore.instance.collection('doctors').add({
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'specialization': specializationController.text.trim(),
                    'experience': int.tryParse(experienceController.text) ?? 0,
                    'timeslots': timeslots,
                    'available': isAvailable,
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  logActivity('Added doctor: Dr. ${firstNameController.text.trim()} ${lastNameController.text.trim()}');
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final firstNameController = TextEditingController(text: data['firstName']);
    final lastNameController = TextEditingController(text: data['lastName']);
    final specializationController = TextEditingController(text: data['specialization']);
    final experienceController = TextEditingController(text: data['experience']?.toString() ?? '');
    bool isAvailable = data['available'] ?? false;
    List<String> timeslots = List<String>.from(data['timeslots'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Doctor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name*', border: OutlineInputBorder()))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name*', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: specializationController, decoration: const InputDecoration(labelText: 'Specialization*', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: experienceController, decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text('Time Slots:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (String slot in timeslots)
                        Chip(label: Text(slot), onDeleted: () => setState(() => timeslots.remove(slot))),
                      ActionChip(
                        label: const Text('Add Time'),
                        avatar: const Icon(Icons.add),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) {
                            setState(() {
                              final String formattedTime = DateFormat('h:mm a').format(DateTime(2022, 1, 1, time.hour, time.minute));
                              if (!timeslots.contains(formattedTime)) timeslots.add(formattedTime);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(title: const Text('Available'), value: isAvailable, onChanged: (value) => setState(() => isAvailable = value)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty || specializationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  FirebaseFirestore.instance.collection('doctors').doc(docId).update({
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'specialization': specializationController.text.trim(),
                    'experience': int.tryParse(experienceController.text) ?? 0,
                    'timeslots': timeslots,
                    'available': isAvailable,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  logActivity('Updated doctor: Dr. ${firstNameController.text.trim()} ${lastNameController.text.trim()}');
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$itemName"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('doctors').doc(docId).delete();
              logActivity('Deleted doctor: $itemName');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemName has been deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No doctors available', 'Add a new doctor using the + button');
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
          final String specialization = data['specialization'] ?? '';
          return fullName.toLowerCase().contains(searchQuery.toLowerCase()) || specialization.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState('No matching doctors', 'Try a different search term');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
            final timestamp = data['lastUpdated'] as Timestamp?;
            final lastUpdatedText = timestamp != null ? 'Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())}' : '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ExpansionTile(
                    tilePadding: const EdgeInsets.all(16),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text("Dr. $fullName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(data['specialization'] ?? 'General Physician', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            data['available'] == true ? 'Available' : 'Unavailable',
                            style: TextStyle(color: data['available'] == true ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: data['available'] == true ? Colors.green[100] : Colors.red[100],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(context, doc.id, data)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(context, doc.id, "Dr. $fullName")),
                      ],
                    ),
                    children: [
                      if (data['timeslots'] != null && (data['timeslots'] as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available Time Slots:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (data['timeslots'] as List).map((slot) => Chip(label: Text(slot.toString()), backgroundColor: Theme.of(context).colorScheme.primaryContainer)).toList(),
                            ),
                          ],
                        ),
                      if (data['experience'] != null)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text('Experience: ${data['experience']} years')),
                    ],
                  ),
                  if (lastUpdatedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(lastUpdatedText, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}