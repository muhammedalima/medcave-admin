import 'package:flutter/material.dart';

class HospitalDetailsStep extends StatefulWidget {
  final TextEditingController hospitalNameController;
  final TextEditingController hospitalAddressController;
  final TextEditingController palliativeCareDescriptionController;
  final TextEditingController palliativeCareContactController;

  const HospitalDetailsStep({
    required this.hospitalNameController,
    required this.hospitalAddressController,
    required this.palliativeCareDescriptionController,
    required this.palliativeCareContactController,
    Key? key,
  }) : super(key: key);

  @override
  State<HospitalDetailsStep> createState() => _HospitalDetailsStepState();
}

class _HospitalDetailsStepState extends State<HospitalDetailsStep> {
  bool hasPalliativeCare = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.hospitalNameController,
          decoration: InputDecoration(
            labelText: 'Hospital Name',
            hintText: 'Enter the official name of your hospital',
            prefixIcon: const Icon(Icons.local_hospital),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
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
          controller: widget.hospitalAddressController,
          decoration: InputDecoration(
            labelText: 'Hospital Address',
            hintText: 'Enter the complete address of your hospital',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
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

        // Add palliative care checkbox
        CheckboxListTile(
          title: const Text(
            'Does your hospital provide palliative care services?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          value: hasPalliativeCare,
          activeColor: const Color(0xFF4A90E2),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              hasPalliativeCare = value ?? false;

              // Clear the controllers if the checkbox is unchecked
              if (!hasPalliativeCare) {
                widget.palliativeCareDescriptionController.clear();
                widget.palliativeCareContactController.clear();
              }
            });
          },
        ),

        // Conditionally show palliative care details if checkbox is checked
        if (hasPalliativeCare) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.palliativeCareDescriptionController,
            decoration: InputDecoration(
              labelText: 'Palliative Care Description',
              hintText: 'Please describe the palliative care services offered',
              prefixIcon: const Icon(Icons.medical_services),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            maxLines: 3,
            validator: (value) {
              if (hasPalliativeCare && (value == null || value.isEmpty)) {
                return 'Please provide a description of your palliative care services';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.palliativeCareContactController,
            decoration: InputDecoration(
              labelText: 'Palliative Care Contact Number',
              hintText:
                  'Enter direct contact number for palliative care services',
              prefixIcon: const Icon(Icons.phone),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (hasPalliativeCare && (value == null || value.isEmpty)) {
                return 'Please provide a contact number for palliative care services';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
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
    );
  }
}
