import 'package:flutter/material.dart';
import 'package:medcave/common/service/firebase_register.dart';
import 'package:medcave/main/Starting_screen/auth/register/components/hospital_details.dart';
import 'package:medcave/main/Starting_screen/auth/register/components/personal_information.dart';
import 'package:medcave/main/Starting_screen/auth/register/components/security_credentials.dart';
import 'package:medcave/main/Starting_screen/auth/register/components/verification.dart';
import 'package:medcave/main/home/presentation/adminhome.dart';
import 'package:medcave/main/Starting_screen/auth/login/adminlogin.dart';

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({Key? key}) : super(key: key);

  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseRegister = FirebaseRegister();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  // New controllers for palliative care
  final _palliativeCareDescriptionController = TextEditingController();
  final _palliativeCareContactController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  int _currentStep = 0;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isCodeValid = await _firebaseRegister
        .validateVerificationCode(_verificationCodeController.text.trim());

    if (!isCodeValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or used verification code';
      });
      return;
    }

    final result = await _firebaseRegister.registerAdmin(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      hospitalName: _hospitalNameController.text.trim(),
      hospitalAddress: _hospitalAddressController.text.trim(),
      phone: _phoneController.text.trim(),
      verificationCode: _verificationCodeController.text.trim(),
      // Add palliative care data
      hasPalliativeCare: _palliativeCareDescriptionController.text.isNotEmpty,
      palliativeCareDescription: _palliativeCareDescriptionController.text.trim(),
      palliativeCareContact: _palliativeCareContactController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (result != null) {
        _errorMessage = result;
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const AdminHome()));
      }
    });
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
      case
      3:
        return _passwordController.text.trim().length >= 8 &&
            _confirmPasswordController.text == _passwordController.text;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield,
                            size: 60, color: Color(0xFF4A90E2)),
                        const SizedBox(height: 16),
                        const Text(
                          'Hospital Admin Registration',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create an account to manage your hospital resources',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: _buildStepIndicator(
                                      0, 'Verification Code')),
                              _buildConnector(),
                              Expanded(
                                  child:
                                      _buildStepIndicator(1, 'Personal Info')),
                              _buildConnector(),
                              Expanded(
                                  child: _buildStepIndicator(
                                      2, 'Hospital Details')),
                              _buildConnector(),
                              Expanded(
                                  child: _buildStepIndicator(3, 'Credentials')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStepContent(),
                        const SizedBox(height: 16),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_currentStep >
                              0)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _currentStep -= 1),
                                child: const Text('Back'),
                              ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_currentStep < 3) {
                                        if (_validateCurrentStep()) {
                                          setState(() => _currentStep += 1);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please fill all required fields')),
                                          );
                                        }
                                      } else {
                                        _register();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    )
                                  : const Text('Next'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminLoginPage()));
                              },
                              child: const Text('Sign In',
                                  style: TextStyle(color: Color(0xFF4A90E2))),
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
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF4A90E2)
                : isCompleted
                    ? Colors.green
                    : Colors.grey[300],
          ),
          child: Text(
            '${step + 1}',
            style: TextStyle(
              color: isActive || isCompleted ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF4A90E2) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 20, // Adjusted width to prevent overflow
      height: 2,
      color: Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return VerificationStep(
          verificationCodeController: _verificationCodeController,
          errorMessage: _errorMessage,
        );
      case 1:
        return PersonalInformationStep(
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
        );
      case 2:
        return HospitalDetailsStep(
          hospitalNameController: _hospitalNameController,
          hospitalAddressController: _hospitalAddressController,
          palliativeCareDescriptionController: _palliativeCareDescriptionController,
          palliativeCareContactController: _palliativeCareContactController,
        );
      case 3:
        return SecurityCredentialsStep(
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          errorMessage: _errorMessage,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}