import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LabTestsTab extends StatelessWidget {
  final String searchQuery;
  final Function(String) logActivity;

  const LabTestsTab({required this.searchQuery, required this.logActivity, super.key});

  static void showAddDialog(BuildContext context, Function(String) logActivity) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final prerequisitesController = TextEditingController();
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Lab Test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Test Name*', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (₹)*', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: prerequisitesController, decoration: const InputDecoration(labelText: 'Prerequisites', border: OutlineInputBorder(), hintText: 'E.g., Fasting for 8 hours'), maxLines: 3),
                  const SizedBox(height: 16),
                  SwitchListTile(title: const Text('Available'), value: isAvailable, onChanged: (value) => setState(() => isAvailable = value)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  FirebaseFirestore.instance.collection('labTests').add({
                    'name': nameController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'prerequisites': prerequisitesController.text.trim(),
                    'available': isAvailable,
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  logActivity('Added lab test: ${nameController.text.trim()}');
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
    final nameController = TextEditingController(text: data['name']);
    final priceController = TextEditingController(text: data['price'].toString());
    final prerequisitesController = TextEditingController(text: data['prerequisites']);
    bool isAvailable = data['available'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Lab Test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Test Name*', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (₹)*', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: prerequisitesController, decoration: const InputDecoration(labelText: 'Prerequisites', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 16),
                  SwitchListTile(title: const Text('Available'), value: isAvailable, onChanged: (value) => setState(() => isAvailable = value)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  FirebaseFirestore.instance.collection('labTests').doc(docId).update({
                    'name': nameController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'prerequisites': prerequisitesController.text.trim(),
                    'available': isAvailable,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                  logActivity('Updated lab test: ${nameController.text.trim()}');
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
              FirebaseFirestore.instance.collection('labTests').doc(docId).delete();
              logActivity('Deleted lab test: $itemName');
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
      stream: FirebaseFirestore.instance.collection('labTests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No lab tests available', 'Add a new lab test using the + button');
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState('No matching lab tests', 'Try a different search term');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['lastUpdated'] as Timestamp?;
            final lastUpdatedText = timestamp != null ? 'Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())}' : '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(data['name'] ?? 'Unnamed Test', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Price: ₹${data['price'] ?? 0}'),
                        if (data['prerequisites'] != null && data['prerequisites'].toString().isNotEmpty)
                          Text('Prerequisites: ${data['prerequisites']}'),
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
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(context, doc.id, data['name'])),
                      ],
                    ),
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