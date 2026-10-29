import 'dart:math' as math;

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cardChild,
    this.footer,
    this.headerAction,
  });

  final String title;
  final String subtitle;
  final Widget cardChild;
  final Widget? footer;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoWidth = math.min(size.width * 0.38, 150.0);
    final headerHeight = math.max(size.height * 0.43, 360.0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF3F7FC),
        body: Stack(
          children: [
            _BackgroundBand(height: headerHeight),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: AppLocalizations.isArabic
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: headerAction ?? const SizedBox(height: 36),
                          ),
                          const SizedBox(height: 18),
                          Image.asset(
                            AppImages.logo,
                            width: logoWidth,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 70,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .8),
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: math.max(size.height * 0.055, 34.0),
                          ),
                          _AuthCard(child: cardChild),
                          if (footer != null) ...[
                            const SizedBox(height: 18),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.isPassword = false,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool isPassword;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.isPassword && _obscureText,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: const TextStyle(
        color: Color(0xFF10233F),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF6F9FD),
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8390A4),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: widget.prefix ??
            Icon(
              widget.icon,
              color: AppColors.primary,
              size: 20,
            ),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: AppLocalizations.isArabic
                    ? (_obscureText ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور')
                    : (_obscureText ? 'Show password' : 'Hide password'),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF7C8BA0),
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE7F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE55353)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE55353), width: 1.2),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: .62),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthHeaderAction extends StatelessWidget {
  const AuthHeaderAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_back_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5B).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackgroundBand extends StatelessWidget {
  const _BackgroundBand({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradient1,
            AppColors.gradient2,
            AppColors.gradient2,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -56,
            child: _GlowCircle(
              size: 190,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 16,
            left: -80,
            child: _GlowCircle(
              size: 170,
              color: AppColors.secondary.withValues(alpha: 0.13),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
