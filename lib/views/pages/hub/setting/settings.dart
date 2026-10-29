import 'dart:async';
import 'dart:io';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/password_policy.dart';
import 'package:blockatie/views/pages/location_picker/location_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _ownerNameFocus = FocusNode();
  final _storeNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = true;
  File? _selectedImage;
  double? _selectedLatitude;
  double? _selectedLongitude;
  ClientInfo? _profile;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _storeNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownerNameFocus.dispose();
    _storeNameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final provider = context.read<ProfileProvider>();
    final profile = provider.profileInfo ??
        await provider.fetchClientProfile(
          silent: true,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _ownerNameController.text = profile?.nclient ?? '';
      _storeNameController.text = profile?.nstore ?? '';
      _phoneController.text = profile?.phclient ?? '';
      _locationController.text = profile?.lclient ?? '';
      _selectedLatitude = profile?.latitude;
      _selectedLongitude = profile?.longitude;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) {
      return;
    }

    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _openLocationPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          onLocationSelected: (latitude, longitude, address) {
            _selectedLatitude = latitude;
            _selectedLongitude = longitude;
            _locationController.text = address;
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save(ProfileProvider provider) async {
    if (provider.isUpdating) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await provider.updateClientProfile(
      clientName: _ownerNameController.text,
      storeName: _storeNameController.text,
      locationText: _locationController.text,
      password: _passwordController.text,
      imageFile: _selectedImage,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      await _loadProfile();
      setState(() => _selectedImage = null);
      _showSnack(result.message);
      return;
    }

    _showSnack(result.message, isError: true);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? const Color(0xffDC2626) : const Color(0xff16A06D),
        ),
      );
  }

  String _copy(String en, String ar) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              title: _copy('Edit Information', 'تعديل المعلومات'),
              subtitle: _copy(
                'Update the supported store details safely',
                'تحديث بيانات المتجر المدعومة بشكل آمن',
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const _LoadingState()
                  : _profile == null
                      ? _ErrorState(
                          message: provider.profileError ??
                              _copy(
                                'Unable to load profile data. Please try again.',
                                'تعذر تحميل بيانات الحساب. حاول مرة أخرى.',
                              ),
                          buttonLabel: _copy('Try again', 'حاول مرة أخرى'),
                          onRetry: _loadProfile,
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LogoCard(
                                  profile: _profile!,
                                  selectedImage: _selectedImage,
                                  onPickImage: () {
                                    unawaited(_pickImage());
                                  },
                                  copy: _copy,
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: _copy(
                                    'Store Information',
                                    'معلومات المتجر',
                                  ),
                                  subtitle: _copy(
                                    'Edit only the fields supported by your account.',
                                    'قم بتعديل الحقول المدعومة فقط في حسابك.',
                                  ),
                                  children: [
                                    _AppField(
                                      controller: _ownerNameController,
                                      focusNode: _ownerNameFocus,
                                      label: _copy('Owner Name', 'اسم المالك'),
                                      icon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.length < 2) {
                                          return _copy(
                                            'Enter a valid owner name.',
                                            'أدخل اسم مالك صحيحاً.',
                                          );
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _storeNameFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 12),
                                    _AppField(
                                      controller: _storeNameController,
                                      focusNode: _storeNameFocus,
                                      label: _copy('Store Name', 'اسم المتجر'),
                                      icon: Icons.storefront_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.length < 2) {
                                          return _copy(
                                            'Enter a valid store name.',
                                            'أدخل اسم متجر صحيحاً.',
                                          );
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 12),
                                    _AppField(
                                      controller: _phoneController,
                                      label:
                                          _copy('Phone Number', 'رقم الهاتف'),
                                      icon: Icons.phone_outlined,
                                      readOnly: true,
                                      helperText: _copy(
                                        'Phone number is managed through support.',
                                        'يتم تعديل رقم الهاتف من خلال الدعم.',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _AppField(
                                            controller: _locationController,
                                            label: _copy('Location', 'الموقع'),
                                            icon: Icons.location_on_outlined,
                                            readOnly: true,
                                            maxLines: 2,
                                            helperText: _copy(
                                              'You can update the store location from the map.',
                                              'يمكنك تحديث موقع المتجر من الخريطة.',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _MapButton(
                                          onTap: () {
                                            unawaited(_openLocationPicker());
                                          },
                                          label: _copy('Map', 'الخريطة'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: _copy('Security', 'الأمان'),
                                  subtitle: _copy(
                                    'Password change is optional.',
                                    'تغيير كلمة المرور اختياري.',
                                  ),
                                  children: [
                                    _AppField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      label: _copy(
                                          'New Password', 'كلمة مرور جديدة'),
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: true,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        final text = value ?? '';
                                        if (text.trim().isEmpty) {
                                          return null;
                                        }
                                        return PasswordPolicy.message(
                                          text,
                                          isArabic: _copy('en', 'ar') == 'ar',
                                        );
                                      },
                                      onFieldSubmitted: (_) =>
                                          _confirmPasswordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 12),
                                    _AppField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocus,
                                      label: _copy(
                                        'Confirm Password',
                                        'تأكيد كلمة المرور',
                                      ),
                                      icon: Icons.lock_reset_rounded,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      validator: (value) {
                                        final password =
                                            _passwordController.text;
                                        final confirm = value ?? '';
                                        if (password.trim().isEmpty &&
                                            confirm.trim().isEmpty) {
                                          return null;
                                        }
                                        if (password != confirm) {
                                          return _copy(
                                            'Passwords do not match.',
                                            'كلمتا المرور غير متطابقتين.',
                                          );
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) {
                                        unawaited(_save(provider));
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton.icon(
                                    onPressed: provider.isUpdating
                                        ? null
                                        : () {
                                            unawaited(_save(provider));
                                          },
                                    icon: provider.isUpdating
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save_rounded),
                                    label: Text(
                                      provider.isUpdating
                                          ? _copy('Saving...', 'جارٍ الحفظ...')
                                          : _copy(
                                              'Save Changes',
                                              'حفظ التغييرات',
                                            ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppColors.primary
                                          .withValues(alpha: 0.65),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: Nav.back,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.profile,
    required this.selectedImage,
    required this.onPickImage,
    required this.copy,
  });

  final ClientInfo profile;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final String Function(String en, String ar) copy;

  @override
  Widget build(BuildContext context) {
    final logoPath = profile.loshop.trim();
    final logoUrl = logoPath.isEmpty
        ? ''
        : logoPath.startsWith('http')
            ? logoPath
            : 'https://dashboard.blockatie.com$logoPath';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: selectedImage != null
                ? Image.file(selectedImage!, fit: BoxFit.cover)
                : logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy('Store Logo', 'شعار المتجر'),
                  style: const TextStyle(
                    color: Color(0xff0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy(
                    'JPG, PNG, GIF, or WebP image.',
                    'صورة JPG أو PNG أو GIF أو WebP.',
                  ),
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.image_outlined, size: 17),
                  label: Text(copy('Choose Logo', 'اختيار الشعار')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon:
            readOnly ? const Icon(Icons.lock_outline_rounded, size: 18) : null,
        filled: true,
        fillColor: readOnly ? const Color(0xffF8FAFC) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.onTap,
    required this.label,
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppColors.primary));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.buttonLabel,
    required this.onRetry,
  });

  final String message;
  final String buttonLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 140, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  unawaited(onRetry());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xffE1E8F2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
