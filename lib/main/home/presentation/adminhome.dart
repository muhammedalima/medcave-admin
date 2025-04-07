import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medcave/main/Starting_screen/auth/login/adminlogin.dart';
import 'package:medcave/main/home/presentation/features/doctors/doctor.dart';
import 'package:medcave/main/home/presentation/features/lab/lab.dart';
import 'package:medcave/main/home/presentation/features/medicine/medicine.dart';
import 'package:medcave/main/home/presentation/features/paliativecare/paliative.dart';
import 'package:medcave/main/home/presentation/features/vaccine/vaccine.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _hospitalName = 'Hospital Dashboard';
  String _lastEditedTime = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchHospitalDetails();
  }
  
  Future<void> _fetchHospitalDetails() async {
    try {
      setState(() => _isLoading = true);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('uid', isEqualTo: userId)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            _hospitalName = data['hospitalName'] ?? 'Hospital Dashboard';
            _isLoading = false;
          });
        } else {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('admins')
              .doc(userId)
              .get();
              
          if (docSnapshot.exists) {
            final data = docSnapshot.data() ?? {};
            setState(() {
              _hospitalName = data['hospitalName'] ?? 'Hospital Dashboard';
              _isLoading = false;
            });
          } else {
            setState(() {
              _hospitalName = 'Hospital Dashboard';
              _isLoading = false;
            });
          }
        }
      }
      
      final lastEditDoc = await FirebaseFirestore.instance
          .collection('adminActivity')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
          
      if (lastEditDoc.docs.isNotEmpty) {
        final timestamp = lastEditDoc.docs.first['timestamp'] as Timestamp;
        setState(() {
          _lastEditedTime = 'Last edited: ${_formatDateTime(timestamp.toDate())}';
        });
      }
    } catch (e) {
      setState(() {
        _hospitalName = 'Hospital Dashboard';
        _isLoading = false;
      });
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _logActivity(String activity) {
    FirebaseFirestore.instance.collection('adminActivity').add({
      'adminId': FirebaseAuth.instance.currentUser?.uid,
      'activity': activity,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      _lastEditedTime = 'Last edited: ${_formatDateTime(DateTime.now())}';
    });
  }
  
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
        (route) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _hospitalName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
            if (_lastEditedTime.isNotEmpty)
              Text(
                _lastEditedTime,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Lab Tests"),
            Tab(text: "Medicines"),
            Tab(text: "Vaccines"),
            Tab(text: "Doctors"),
            Tab(text: "Palliative Care"),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LabTestsTab(searchQuery: _searchQuery, logActivity: _logActivity),
                MedicinesTab(searchQuery: _searchQuery, logActivity: _logActivity),
                VaccinesTab(searchQuery: _searchQuery, logActivity: _logActivity),
                DoctorsTab(searchQuery: _searchQuery, logActivity: _logActivity),
                PalliativeCareTab(logActivity: _logActivity),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              LabTestsTab.showAddDialog(context, _logActivity);
              break;
            case 1:
              MedicinesTab.showAddDialog(context, _logActivity);
              break;
            case 2:
              VaccinesTab.showAddDialog(context, _logActivity);
              break;
            case 3:
              DoctorsTab.showAddDialog(context, _logActivity);
              break;
            case 4:
              PalliativeCareTab.showEditDialog(context, _logActivity);
              break;
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add new item',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Dashboard Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Use tabs to navigate between different sections'),
              Text('• Search bar allows filtering items'),
              Text('• Use + button to add new items'),
              Text('• Edit icon modifies existing items'),
              Text('• Delete icon removes items'),
              SizedBox(height: 8),
              Text('• For palliative care: add description and contact info'),
              Text('• Toggle availability to show/hide services'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}