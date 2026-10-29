import 'package:flutter/material.dart';
import 'package:blockatie/utils/spacing.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool obscureText;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.onTap,
    this.readOnly = false,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          textInputAction: textInputAction,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            labelStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
        if (maxLines == 1) Spacing.y(2),
      ],
    );
  }
}

// Specialized TextFormField for phone numbers
class PhoneTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;

  const PhoneTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      keyboardType: TextInputType.phone,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter recipient phone';
            }
            // Add phone number validation if needed
            return null;
          },
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

// Specialized TextFormField for addresses
class AddressTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;

  const AddressTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      maxLines: 3,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter delivery address';
            }
            return null;
          },
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

// Specialized TextFormField for numbers/money
class NumberTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  const NumberTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.number,
      suffixIcon: suffixIcon,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

// Specialized TextFormField for notes/comments
class NoteTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;

  const NoteTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      maxLines: 2,
      validator: validator,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

// Specialized TextFormField for names
class NameTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;

  const NameTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter recipient name';
            }
            return null;
          },
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
