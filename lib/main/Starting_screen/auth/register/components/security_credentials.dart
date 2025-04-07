import 'package:flutter/material.dart';

class SecurityCredentialsStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String errorMessage;

  const SecurityCredentialsStep({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.errorMessage,
    Key? key,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SecurityCredentialsStepState createState() =>
      _SecurityCredentialsStepState();
}

class _SecurityCredentialsStepState extends State<SecurityCredentialsStep> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;
  bool _hasSpecial = false;
  double _passwordStrength = 0.0;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = widget.passwordController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

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
    widget.passwordController.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.passwordController,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
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
        if (widget.passwordController.text.isNotEmpty) ...[
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
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          obscureText: !_confirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != widget.passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        if (widget.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(widget.errorMessage, style: TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
