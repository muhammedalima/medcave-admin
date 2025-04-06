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
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  
  double? _latitude;
  double? _longitude;
  String _address = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchHospitalDetails();
  }
  
  Future<void> _fetchHospitalDetails() async {
    // Same implementation as original
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
            _latitude = data['latitude'] as double?;
            _longitude = data['longitude'] as double?;
            _address = data['address'] as String? ?? '';
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
              _latitude = data['latitude'] as double?;
              _longitude = data['longitude'] as double?;
              _address = data['address'] as String? ?? '';
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
    // Same implementation as original
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

  Future<void> _openGoogleMaps() async {
    // Same implementation as original
    if (_latitude != null && _longitude != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not set for this hospital')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Same implementation as original
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
            Tab(text: "Location"),
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
                _buildLocationTab(),
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
            case 5:
              _showUpdateLocationDialog(context);
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

  Widget _buildLocationTab() {
    // Same implementation as original
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hospital Location',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_latitude != null && _longitude != null) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_latitude!, _longitude!),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('hospital'),
                              position: LatLng(_latitude!, _longitude!),
                              infoWindow: InfoWindow(title: _hospitalName),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red, size: 30),
                      title: const Text('Address'),
                      subtitle: Text(_address.isNotEmpty ? _address : 'No address provided'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                      title: const Text('Coordinates'),
                      subtitle: Text('Lat: $_latitude, Lng: $_longitude'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Google Maps'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _openGoogleMaps,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.location_off, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No location set for this hospital',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_location),
                            label: const Text('Set Hospital Location'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () => _showUpdateLocationDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Why set your hospital location?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.directions, color: Colors.green),
                    title: Text('Easier Navigation'),
                    subtitle: Text('Help patients find your facility with accurate directions'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(Icons.local_hospital, color: Colors.red),
                    title: Text('Emergency Access'),
                    subtitle: Text('Critical in emergency situations when every minute counts'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(Icons.visibility, color: Colors.blue),
                    title: Text('Enhanced Visibility'),
                    subtitle: Text('Improve your hospital\'s online presence and searchability'),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateLocationDialog(BuildContext context) {
    // Same implementation as original
    final latitudeController = TextEditingController(text: _latitude?.toString() ?? '');
    final longitudeController = TextEditingController(text: _longitude?.toString() ?? '');
    final addressController = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Hospital Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the coordinates of your hospital location:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude*',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 28.6139',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude*',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 77.2090',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  hintText: 'Full address of the hospital',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tip: You can find your coordinates by searching your hospital in Google Maps, right-clicking on the location, and selecting "What\'s here?"',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Find on Google Maps'),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),
            onPressed: () async {
              final url = 'https://www.google.com/maps';
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open maps application')),
                );
              }
            },
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latitudeController.text.trim());
              final lng = double.tryParse(longitudeController.text.trim());
              
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid coordinates')),
                );
                return;
              }
              
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                FirebaseFirestore.instance.collection('admins').where('uid', isEqualTo: userId).get().then((querySnapshot) {
                  if (querySnapshot.docs.isNotEmpty) {
                    querySnapshot.docs.first.reference.update({
                      'latitude': lat,
                      'longitude': lng,
                      'address': addressController.text.trim(),
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });
                  } else {
                    FirebaseFirestore.instance.collection('admins').doc(userId).update({
                      'latitude': lat,
                      'longitude': lng,
                      'address': addressController.text.trim(),
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });
                  }
                });
                
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  _address = addressController.text.trim();
                });
                
                _logActivity('Updated hospital location');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hospital location updated successfully')),
                );
              }
            },
            child: const Text('Save Location'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    // Same implementation as original
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
              SizedBox(height: 8),
              Text('• Set hospital location coordinates in the Location tab'),
              Text('• Use "Find on Google Maps" to locate your hospital'),
              Text('• The location will be visible to patients for navigation'),
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

