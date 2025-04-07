import 'package:flutter/material.dart';

class VerificationStep extends StatelessWidget {
  final TextEditingController verificationCodeController;
  final String errorMessage;

  const VerificationStep({
    required this.verificationCodeController,
    required this.errorMessage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: verificationCodeController,
          decoration: InputDecoration(
            labelText: 'Verification Code',
            hintText: 'Enter the code provided by your administrator',
            prefixIcon: const Icon(Icons.verified_user),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
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
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(errorMessage, style: TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}