import 'package:flutter/material.dart';
import 'package:blockatie/views/widgets/custom_dropdown_field.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/utils/app_utils.dart';

class DropdownFieldExamples extends StatefulWidget {
  const DropdownFieldExamples({super.key});

  @override
  State<DropdownFieldExamples> createState() => _DropdownFieldExamplesState();
}

class _DropdownFieldExamplesState extends State<DropdownFieldExamples> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedGovernorate;
  int? _selectedProductType;
  int? _selectedDeliveryType;
  String? _selectedCustomOption;
  bool _isFormEnabled = true;

  // Custom options for generic dropdown
  final List<String> _customOptions = [
    'Option 1',
    'Option 2',
    'Option 3',
    'Option 4',
    'Option 5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Dropdown Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFormEnabled ? Icons.lock_open : Icons.lock),
            onPressed: () {
              setState(() {
                _isFormEnabled = !_isFormEnabled;
              });
            },
            tooltip: _isFormEnabled ? 'Disable Form' : 'Enable Form',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Governorate Dropdown
              const Text(
                'Governorate Dropdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              GovernorateDropdown(
                value: _selectedGovernorate,
                onChanged: (value) {
                  setState(() {
                    _selectedGovernorate = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a governorate';
                  }
                  return null;
                },
                enabled: _isFormEnabled,
              ),
              Spacing.y(2),

              // Product Type Dropdown
              const Text(
                'Product Type Dropdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              ProductTypeDropdown(
                value: _selectedProductType,
                onChanged: (value) {
                  setState(() {
                    _selectedProductType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a product type';
                  }
                  return null;
                },
                enabled: _isFormEnabled,
              ),
              Spacing.y(2),

              // Delivery Type Dropdown
              const Text(
                'Delivery Type Dropdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              DeliveryTypeDropdown(
                value: _selectedDeliveryType,
                onChanged: (value) {
                  setState(() {
                    _selectedDeliveryType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a delivery type';
                  }
                  return null;
                },
                enabled: _isFormEnabled,
              ),
              Spacing.y(2),

              // Generic Dropdown
              const Text(
                'Generic Dropdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              GenericDropdown<String>(
                value: _selectedCustomOption,
                labelText: 'Custom Options',
                hintText: 'Select an option',
                items: _customOptions,
                itemLabel: (item) => item,
                itemValue: (item) => item,
                onChanged: (value) {
                  setState(() {
                    _selectedCustomOption = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an option';
                  }
                  return null;
                },
                enabled: _isFormEnabled,
              ),
              Spacing.y(2),

              // Custom Dropdown with Custom Styling
              const Text(
                'Custom Dropdown with Custom Styling',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              CustomDropdownField<String>(
                value: _selectedCustomOption,
                labelText: 'Custom Styled Dropdown',
                hintText: 'Choose an option',
                items: _customOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _selectedCustomOption == option
                              ? Colors.green
                              : Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(option),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomOption = value;
                  });
                },
                suffixIcon:
                    const Icon(Icons.arrow_drop_down, color: Colors.blue),
                enabled: _isFormEnabled,
              ),
              Spacing.y(3),

              // Current Selections Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Selections:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacing.y(1),
                    Text(
                        'Governorate: ${_selectedGovernorate ?? 'Not selected'}'),
                    Text(
                        'Product Type: ${_selectedProductType ?? 'Not selected'}'),
                    Text(
                        'Delivery Type: ${_selectedDeliveryType ?? 'Not selected'}'),
                    Text(
                        'Custom Option: ${_selectedCustomOption ?? 'Not selected'}'),
                  ],
                ),
              ),
              Spacing.y(3),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormEnabled
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            AppUtils.showSuccessDialog('Form is valid!');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Validate Form',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Spacing.y(2),

              // Clear Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isFormEnabled
                      ? () {
                          _formKey.currentState!.reset();
                          setState(() {
                            _selectedGovernorate = null;
                            _selectedProductType = null;
                            _selectedDeliveryType = null;
                            _selectedCustomOption = null;
                          });
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Clear Form',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
