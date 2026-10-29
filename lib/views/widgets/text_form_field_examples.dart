import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/views/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class TextFormFieldExamples extends StatefulWidget {
  const TextFormFieldExamples({super.key});

  @override
  State<TextFormFieldExamples> createState() => _TextFormFieldExamplesState();
}

class _TextFormFieldExamplesState extends State<TextFormFieldExamples> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController();
  final _noteController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _discountController.dispose();
    _noteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom TextFormField Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Custom TextFormField
              const Text(
                'Basic Custom TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              Spacing.y(2),

              // Name TextFormField
              const Text(
                'Name TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              NameTextFormField(
                controller: _nameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
              Spacing.y(2),

              // Phone TextFormField
              const Text(
                'Phone TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              PhoneTextFormField(
                controller: _phoneController,
                labelText: 'Phone Number',
              ),
              Spacing.y(2),

              // Address TextFormField
              const Text(
                'Address TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              AddressTextFormField(
                controller: _addressController,
                labelText: 'Delivery Address',
              ),
              Spacing.y(2),

              // Number TextFormField with Money Icon
              const Text(
                'Number TextFormField (Money)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              NumberTextFormField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: 'Enter amount in JOD',
                suffixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              Spacing.y(2),

              // Number TextFormField with Percentage Icon
              const Text(
                'Number TextFormField (Percentage)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              NumberTextFormField(
                controller: _discountController,
                labelText: 'Discount Percentage',
                suffixIcon: const Icon(Icons.percent, color: Colors.grey),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final discount = double.tryParse(value);
                    if (discount == null || discount < 0 || discount > 100) {
                      return 'Discount must be between 0 and 100';
                    }
                  }
                  return null;
                },
              ),
              Spacing.y(2),

              // Note TextFormField
              const Text(
                'Note TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              NoteTextFormField(
                controller: _noteController,
                labelText: 'Additional Notes',
              ),
              Spacing.y(2),

              // Password TextFormField
              const Text(
                'Password TextFormField',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacing.y(1),
              CustomTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                obscureText: true,
                suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              Spacing.y(3),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      AppUtils.showSuccessDialog('Form is valid!');
                    }
                  },
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
                  onPressed: () {
                    _formKey.currentState!.reset();
                    _nameController.clear();
                    _phoneController.clear();
                    _emailController.clear();
                    _addressController.clear();
                    _amountController.clear();
                    _discountController.clear();
                    _noteController.clear();
                    _passwordController.clear();
                  },
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
