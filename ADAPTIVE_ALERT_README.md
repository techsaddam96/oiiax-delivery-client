# Adaptive Alert Dialog System

This document explains how to use the new adaptive alert dialog system that replaces traditional SnackBars with more prominent and user-friendly alert dialogs.

## Overview

The adaptive alert dialog system provides:
- **Better Visual Hierarchy**: Icons, titles, and structured content
- **Automatic Dismissal**: Configurable timeouts for different message types
- **Consistent Styling**: Unified design across the entire app
- **Better Accessibility**: Clear visual indicators and proper contrast
- **No Context Required**: Most methods work without passing BuildContext

## Available Methods

### 1. Success Dialogs
```dart
// Basic success message
AppUtils.showSuccessDialog("Operation completed successfully");

// With custom title
AppUtils.showSuccessDialog(
  "Profile updated successfully",
  title: "Update Complete"
);
```

### 2. Error Dialogs
```dart
// Basic error message
AppUtils.showErrorDialog("Something went wrong");

// With custom title
AppUtils.showErrorDialog(
  "Failed to connect to server",
  title: "Connection Error"
);
```

### 3. Warning Dialogs
```dart
// Basic warning message
AppUtils.showWarningDialog("Please check your internet connection");

// With custom title
AppUtils.showWarningDialog(
  "Password is too short",
  title: "Validation Warning"
);
```

### 4. Info Dialogs
```dart
// Basic info message
AppUtils.showInfoDialog("Your data has been synced");

// With custom title
AppUtils.showInfoDialog(
  "New features available",
  title: "App Update"
);
```

### 5. Confirmation Dialogs
```dart
AppUtils.showConfirmationDialog(
  message: "Are you sure you want to delete this item?",
  title: "Confirm Delete",
  confirmText: "Delete",
  cancelText: "Cancel",
  onConfirm: () {
    // Handle confirmation
    print("Item deleted");
  },
  onCancel: () {
    // Handle cancellation
    print("Delete cancelled");
  },
);
```

### 6. Success Dialog without Buttons (Auto-dismiss)
```dart
AppUtils.showSuccessNoButton("Operation completed successfully");
```

## Migration Guide: Converting from SnackBars

### Before (SnackBar)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Profile updated successfully"),
    backgroundColor: Colors.green,
  ),
);
```

### After (Adaptive Alert Dialog)
```dart
AppUtils.showSuccessDialog("Profile updated successfully");
```

### Before (Error SnackBar)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Failed to save data"),
    backgroundColor: Colors.red,
  ),
);
```

### After (Error Alert Dialog)
```dart
AppUtils.showErrorDialog("Failed to save data");
```

### Before (Confirmation with SnackBar)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Are you sure?"),
    action: SnackBarAction(
      label: 'Yes',
      onPressed: () => handleAction(),
    ),
  ),
);
```

### After (Confirmation Dialog)
```dart
AppUtils.showConfirmationDialog(
  message: "Are you sure?",
  onConfirm: () => handleAction(),
);
```

## Auto-Dismissal Times

Different dialog types have different auto-dismissal times:

- **Success Dialogs**: 3 seconds
- **Error Dialogs**: 4 seconds  
- **Warning Dialogs**: 3.5 seconds
- **Info Dialogs**: 3 seconds
- **Success No Button**: 2.5 seconds

## Benefits Over SnackBars

1. **Better Visibility**: Dialogs are more prominent than bottom-positioned snackbars
2. **Clearer Hierarchy**: Icons and titles make the message type immediately clear
3. **Consistent Styling**: All dialogs follow the same design pattern
4. **No Context Dependency**: Most methods work without passing BuildContext
5. **Better UX**: Users can't accidentally dismiss important messages
6. **Accessibility**: Better contrast and clearer visual indicators
7. **Mobile-Friendly**: Better suited for mobile interfaces

## Usage Examples

### API Error Handling
```dart
try {
  final response = await apiCall();
  if (response.statusCode == 200) {
    AppUtils.showSuccessDialog("Data saved successfully");
  } else {
    AppUtils.showErrorDialog("Failed to save data");
  }
} catch (e) {
  AppUtils.showErrorDialog("Network error occurred");
}
```

### Form Validation
```dart
if (email.isEmpty) {
  AppUtils.showErrorDialog("Email is required");
  return;
}

if (password.length < 6) {
  AppUtils.showWarningDialog("Password must be at least 6 characters");
  return;
}

AppUtils.showSuccessDialog("Form is valid");
```

### User Action Confirmation
```dart
AppUtils.showConfirmationDialog(
  message: "Are you sure you want to logout?",
  title: "Confirm Logout",
  confirmText: "Yes, logout",
  cancelText: "Cancel",
  onConfirm: () {
    // Handle logout
    logout();
  },
);
```

## Legacy Support

For backward compatibility, the following methods are also available:

```dart
AppUtils.showSuccessSnackbar("Success message");  // Redirects to showSuccessDialog
AppUtils.showErrorSnackbar("Error message");      // Redirects to showErrorDialog
AppUtils.showWarningSnackbar("Warning message");  // Redirects to showWarningDialog
AppUtils.showInfoSnackbar("Info message");        // Redirects to showInfoDialog
```

## Customization

The alert dialogs use the existing `CustomAlertDialog` widget, which can be customized by modifying:

- `lib/views/widgets/custom_alert_dialog.dart` - Main dialog widget
- `lib/constants/colors.dart` - Color scheme
- `lib/utils/app_utils.dart` - Utility methods

## Best Practices

1. **Use Appropriate Types**: Choose the right dialog type for your message
2. **Keep Messages Concise**: Short, clear messages work best
3. **Use Custom Titles**: Add context with custom titles when helpful
4. **Handle Confirmations**: Always provide clear actions for confirmation dialogs
5. **Test on Different Devices**: Ensure dialogs work well on various screen sizes

## Migration Checklist

- [ ] Replace `ScaffoldMessenger.of(context).showSnackBar()` with appropriate `AppUtils` methods
- [ ] Update error handling to use `AppUtils.showErrorDialog()`
- [ ] Update success messages to use `AppUtils.showSuccessDialog()`
- [ ] Replace confirmation snackbars with `AppUtils.showConfirmationDialog()`
- [ ] Test all dialog interactions
- [ ] Verify auto-dismissal works correctly
- [ ] Check accessibility on different devices 