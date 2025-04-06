import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/Starting_screen/auth/login/adminlogin.dart';
import 'package:medcave/main/home/presentation/adminhome.dart';

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({Key? key}) : super(key: key);

  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _errorMessage = '';
  int _currentStep = 0;

  // Password strength variables
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;
  bool _hasSpecial = false;
  double _passwordStrength = 0.0;

  @override
  void initState() {
    super.initState();
    // Add listener to password field to update strength indicators
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      
      // Calculate password strength (0.0 to 1.0)
      int strength = 0;
      if (_hasMinLength) strength++;
      if (_hasNumber) strength++;
      if (_hasUppercase) strength++;
      if (_hasSpecial) strength++;
      
      _passwordStrength = strength / 4;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  // Check if verification Code is valid
  Future<bool> _validateVerificationCode(String code) async {
    try {
      // Query Firestore for the verification code
      final codeSnapshot = await _firestore
          .collection('verificationCodes')
          .where('code', isEqualTo: code)
          .where('used', isEqualTo: false) 
          .limit(1)
          .get();

      if (codeSnapshot.docs.isNotEmpty) {
        return true;
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code or code already used';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying code: $e';
      });
      return false;
    }
  }

  // Mark verification code as used
  Future<void> _markCodeAsUsed(String code) async {
    try {
      final codeSnapshot = await _firestore
          .collection('verificationCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (codeSnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('verificationCodes')
            .doc(codeSnapshot.docs.first.id)
            .update({
          'used': true,
          'usedBy': _emailController.text.trim(),
          'usedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking code as used: $e');
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First validate the verification code
      final isCodeValid = await _validateVerificationCode(
          _verificationCodeController.text.trim());

      if (!isCodeValid) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user with email and password in Firebase Auth
      // Firebase Auth automatically handles secure password storage
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Create admin record in Firestore with auto-generated document ID
        final adminRef = _firestore.collection('admins').doc(userCredential.user!.uid);
        
        await adminRef.set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'hospitalName': _hospitalNameController.text.trim(),
          'hospitalAddress': _hospitalAddressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'admin',
          'verificationCode': _verificationCodeController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Mark the verification code as used
        await _markCodeAsUsed(_verificationCodeController.text.trim());

        // Add a reference in adminActivity to log this registration
        await _firestore.collection('adminActivity').add({
          'adminId': adminRef.id,
          'activity': 'Account created',
          'timestamp': FieldValue.serverTimestamp(),
          'ip': null, // Could implement IP tracking in the future
          'device': kIsWeb ? 'web' : 'mobile',
        });

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to MedCave.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminHome()));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';

      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled.';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _verificationCodeController.text.trim().isNotEmpty;
      case 1:
        return _nameController.text.trim().isNotEmpty && 
               _emailController.text.trim().isNotEmpty && 
               _emailController.text.contains('@') && 
               _phoneController.text.trim().isNotEmpty;
      case 2:
        return _hospitalNameController.text.trim().isNotEmpty && 
               _hospitalAddressController.text.trim().isNotEmpty;
      case 3:
        return _passwordController.text.trim().length >= 8 && 
               _confirmPasswordController.text == _passwordController.text && 
               _passwordStrength >= 0.5; // At least medium-strength password
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Text(
                            'Hospital Admin Registration',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 10),
                          
                          Text(
                            'Create an account to manage your hospital resources',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Stepper
                          Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSeed(
                                seedColor: Theme.of(context).primaryColor,
                                primary: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: Stepper(
                              type: StepperType.vertical,
                              currentStep: _currentStep,
                              physics: const ClampingScrollPhysics(),
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : details.onStepContinue,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Theme.of(context).primaryColor,
                                            elevation: 2,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: _isLoading && _currentStep == 3
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 3,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('Processing...'),
                                                  ],
                                                )
                                              : Text(
                                                  _currentStep == 3 ? 'Create Account' : 'Continue',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                        ),
                                      ),
                                      if (_currentStep > 0) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: details.onStepCancel,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Theme.of(context).primaryColor),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Back',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                              onStepContinue: () {
                                if (_currentStep < 3) {
                                  if (_validateCurrentStep()) {
                                    setState(() {
                                      _currentStep += 1;
                                    });
                                  } else {
                                    // Show validation error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill all required fields correctly'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  // Final step - register
                                  _register();
                                }
                              },
                              onStepCancel: () {
                                if (_currentStep > 0) {
                                  setState(() {
                                    _currentStep -= 1;
                                  });
                                }
                              },
                              steps: [
                                // Step 1: Verification Code
                                Step(
                                  title: const Text('Verification'),
                                  subtitle: const Text('Enter your one-time verification code'),
                                  isActive: _currentStep >= 0,
                                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _verificationCodeController,
                                        decoration: InputDecoration(
                                          labelText: 'Verification Code',
                                          hintText: 'Enter the code provided by your administrator',
                                          prefixIcon: const Icon(Icons.verified_user),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your verification code';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.blue[700]),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'This code verifies your authority to register as a hospital administrator.',
                                                style: TextStyle(color: Colors.blue[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Step 2: Personal Details
                                Step(
                                  title: const Text('Personal Information'),
                                  subtitle: const Text('Enter your contact details'),
                                  isActive: _currentStep >= 1,
                                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                                  content: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Full Name',
                                          hintText: 'Enter your full name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email Address',
                                          hintText: 'Enter your professional email address',
                                          prefixIcon: const Icon(Icons.email),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          hintText: 'Enter your contact number',
                                          prefixIcon: const Icon(Icons.phone),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Step 3: Hospital Details
                                Step(
                                  title: const Text('Hospital Details'),
                                  subtitle: const Text('Tell us about your healthcare facility'),
                                  isActive: _currentStep >= 2,
                                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                                  content: Column(
                                    children: [
                                      TextFormField(
                                        controller: _hospitalNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Hospital Name',
                                          hintText: 'Enter the official name of your hospital',
                                          prefixIcon: const Icon(Icons.local_hospital),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter hospital name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _hospitalAddressController,
                                        decoration: InputDecoration(
                                          labelText: 'Hospital Address',
                                          hintText: 'Enter the complete address of your hospital',
                                          prefixIcon: const Icon(Icons.location_on),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter hospital address';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.verified_outlined, color: Colors.green[700]),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Hospital Verification',
                                                    style: TextStyle(
                                                      color: Colors.green[800],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'The information provided will be verified before full system access is granted.',
                                                    style: TextStyle(color: Colors.green[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Step 4: Security
                                Step(
                                  title: const Text('Security Credentials'),
                                  subtitle: const Text('Set a secure password for your account'),
                                  isActive: _currentStep >= 3,
                                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          hintText: 'Create a strong password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _passwordVisible = !_passwordVisible;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        obscureText: !_passwordVisible,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length < 8) {
                                            return 'Password must be at least 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Password strength indicator
                                      if (_passwordController.text.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Password Strength',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: _passwordStrength,
                                                backgroundColor: Colors.grey[300],
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  _passwordStrength < 0.3
                                                      ? Colors.red
                                                      : _passwordStrength < 0.7
                                                          ? Colors.orange
                                                          : Colors.green,
                                                ),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _passwordStrength < 0.3
                                                    ? 'Weak'
                                                    : _passwordStrength < 0.7
                                                        ? 'Medium'
                                                        : 'Strong',
                                                style: TextStyle(
                                                  color: _passwordStrength < 0.3
                                                      ? Colors.red
                                                      : _passwordStrength < 0.7
                                                          ? Colors.orange
                                                          : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Your password should have:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildPasswordRequirement(
                                                'At least 8 characters',
                                                _hasMinLength,
                                              ),
                                              _buildPasswordRequirement(
                                                'Contains numbers',
                                                _hasNumber,
                                              ),
                                              _buildPasswordRequirement(
                                                'Contains uppercase letters',
                                                _hasUppercase,
                                              ),
                                              _buildPasswordRequirement(
                                                'Contains special characters',
                                                _hasSpecial,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          hintText: 'Confirm your password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _confirmPasswordVisible = !_confirmPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        obscureText: !_confirmPasswordVisible,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      if (_errorMessage.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 16),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red.shade700),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage,
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.security, color: Colors.amber[700]),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Security Note',
                                                    style: TextStyle(
                                                      color: Colors.amber[800],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Your password is encrypted and securely stored. Never share your login credentials with anyone.',
                                                    style: TextStyle(color: Colors.amber[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const AdminLoginPage()));
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}