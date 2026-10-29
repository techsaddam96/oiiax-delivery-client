# Custom TextFormField Components

This document describes the reusable TextFormField components that provide consistent styling and validation across the Blockatie app.

## Overview

The custom TextFormField components are designed to:
- Maintain consistent styling across the app
- Reduce code duplication
- Provide built-in validation for common field types
- Make form creation easier and more maintainable

## Available Components

### 1. CustomTextFormField (Base Component)

The base component that all other specialized components extend from.

```dart
CustomTextFormField(
  controller: _controller,
  labelText: 'Field Label',
  hintText: 'Enter your text here',
  keyboardType: TextInputType.text,
  maxLines: 1,
  suffixIcon: Icon(Icons.help),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  },
  enabled: true,
  obscureText: false,
  onTap: () => print('Field tapped'),
  readOnly: false,
  textInputAction: TextInputAction.next,
  focusNode: _focusNode,
  onChanged: (value) => print('Value changed: $value'),
  onFieldSubmitted: (value) => print('Field submitted: $value'),
)
```

### 2. NameTextFormField

Specialized for name input fields with built-in validation.

```dart
NameTextFormField(
  controller: _nameController,
  labelText: 'Full Name',
  hintText: 'Enter your full name',
  validator: (value) {
    // Custom validation logic
    return null;
  },
  enabled: true,
  onChanged: (value) => print('Name changed: $value'),
)
```

**Features:**
- Keyboard type: `TextInputType.name`
- Text input action: `TextInputAction.next`
- Built-in validation for empty values
- Default error message: "Please enter recipient name"

### 3. PhoneTextFormField

Specialized for phone number input with phone keyboard.

```dart
PhoneTextFormField(
  controller: _phoneController,
  labelText: 'Phone Number',
  validator: (value) {
    // Custom phone validation logic
    return null;
  },
  enabled: true,
  onChanged: (value) => print('Phone changed: $value'),
)
```

**Features:**
- Keyboard type: `TextInputType.phone`
- Built-in validation for empty values
- Default error message: "Please enter recipient phone"

### 4. AddressTextFormField

Specialized for address input with multiple lines.

```dart
AddressTextFormField(
  controller: _addressController,
  labelText: 'Delivery Address',
  validator: (value) {
    // Custom address validation logic
    return null;
  },
  enabled: true,
  onChanged: (value) => print('Address changed: $value'),
)
```

**Features:**
- Multiple lines (3 lines by default)
- Built-in validation for empty values
- Default error message: "Please enter delivery address"

### 5. NumberTextFormField

Specialized for numeric input with number validation.

```dart
NumberTextFormField(
  controller: _amountController,
  labelText: 'Amount',
  hintText: 'Enter amount in JOD',
  suffixIcon: Icon(Icons.attach_money, color: Colors.grey),
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
  enabled: true,
  onChanged: (value) => print('Amount changed: $value'),
)
```

**Features:**
- Keyboard type: `TextInputType.number`
- Built-in number validation
- Support for suffix icons (money, percentage, etc.)
- Default validation for numeric values

### 6. NoteTextFormField

Specialized for notes and comments with multiple lines.

```dart
NoteTextFormField(
  controller: _noteController,
  labelText: 'Additional Notes',
  validator: (value) {
    // Custom note validation logic
    return null;
  },
  enabled: true,
  onChanged: (value) => print('Note changed: $value'),
)
```

**Features:**
- Multiple lines (5 lines by default)
- No built-in validation (optional field)
- Perfect for comments and notes

## Styling Features

All components share consistent styling:

### Visual Design
- **Border Radius**: 10px rounded corners
- **Fill Color**: White background
- **Border Colors**:
  - Normal: Grey (#E0E0E0)
  - Focused: Blue (#2196F3) with 2px width
  - Error: Red (#F44336)
  - Focused Error: Red (#D32F2F) with 2px width

### Typography
- **Label Style**: 14px, grey color
- **Hint Style**: 12px, grey color
- **Content Padding**: 16px horizontal, 16px vertical

### Spacing
- **Field Spacing**: Automatic 8px spacing between single-line fields
- **Multi-line Fields**: No automatic spacing (handled manually)

## Usage Examples

### Basic Form Implementation

```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            NameTextFormField(
              controller: _nameController,
              labelText: 'Customer Name',
            ),
            
            PhoneTextFormField(
              controller: _phoneController,
              labelText: 'Phone Number',
            ),
            
            AddressTextFormField(
              controller: _addressController,
              labelText: 'Delivery Address',
            ),
            
            NumberTextFormField(
              controller: _amountController,
              labelText: 'Order Amount',
              suffixIcon: Icon(Icons.attach_money, color: Colors.grey),
            ),
            
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Form is valid, proceed with submission
                  print('Form submitted successfully');
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Advanced Usage with Custom Validation

```dart
CustomTextFormField(
  controller: _emailController,
  labelText: 'Email Address',
  hintText: 'Enter your email address',
  keyboardType: TextInputType.emailAddress,
  suffixIcon: Icon(Icons.email, color: Colors.grey),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  },
  onChanged: (value) {
    // Real-time validation or processing
    print('Email changed: $value');
  },
)
```

### Password Field with Toggle Visibility

```dart
class PasswordField extends StatefulWidget {
  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: _passwordController,
      labelText: 'Password',
      hintText: 'Enter your password',
      obscureText: _obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}
```

## Best Practices

1. **Controller Management**: Always dispose of TextEditingController in the dispose method
2. **Validation**: Use built-in validators when possible, customize only when needed
3. **Accessibility**: The components include proper accessibility features
4. **Consistency**: Use the same component type for similar fields across the app
5. **Error Handling**: Provide clear, user-friendly error messages

## Migration Guide

To migrate existing TextFormField widgets to use these custom components:

### Before (Original TextFormField)
```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Name',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }
    return null;
  },
)
```

### After (Custom Component)
```dart
NameTextFormField(
  controller: _nameController,
  labelText: 'Name',
)
```

## Benefits

1. **Consistency**: All forms will have the same look and feel
2. **Maintainability**: Style changes can be made in one place
3. **Productivity**: Less code to write for common field types
4. **Validation**: Built-in validation reduces errors
5. **Accessibility**: Proper accessibility features included
6. **Testing**: Easier to test with standardized components

## Future Enhancements

Potential improvements for future versions:
- Input masking for phone numbers and credit cards
- Auto-complete functionality
- Character count indicators
- Rich text formatting for notes
- File attachment support
- Voice input support 