import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/driver_rating_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class DriverRatingBottomSheetResult {
  const DriverRatingBottomSheetResult({
    required this.rating,
    required this.message,
    this.driverId,
    this.shipmentId,
  });

  final int rating;
  final String message;
  final int? driverId;
  final int? shipmentId;
}

class DriverRatingBottomSheet extends StatefulWidget {
  const DriverRatingBottomSheet({
    super.key,
    required this.driverName,
    required this.driverAvatar,
    required this.onSubmit,
  });

  final String driverName;
  final String? driverAvatar;
  final Future<DriverRatingSubmissionResult> Function(int rating, String comment)
      onSubmit;

  @override
  State<DriverRatingBottomSheet> createState() =>
      _DriverRatingBottomSheetState();
}

class _DriverRatingBottomSheetState extends State<DriverRatingBottomSheet> {
  static const Map<int, (String, String)> _ratingLabels = {
    1: ('Poor', 'سيئ'),
    2: ('Unsatisfied', 'غير مرضٍ'),
    3: ('Good', 'جيد'),
    4: ('Very good', 'جيد جداً'),
    5: ('Excellent', 'ممتاز'),
  };

  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final driverName = widget.driverName.trim().isEmpty
        ? (isRtl ? 'السائق' : 'Driver')
        : widget.driverName.trim();
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isRtl
                        ? 'كيف كانت تجربتك مع السائق؟'
                        : 'How was your experience with the driver?',
                    style: const TextStyle(
                      color: Color(0xff0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        _DriverAvatar(
                          avatar: widget.driverAvatar,
                          fallbackLabel: driverName,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff0F172A),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isRtl
                                    ? 'اختر التقييم المناسب لتجربتك مع السائق'
                                    : 'Choose the rating that matches your experience',
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
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: List<Widget>.generate(
                        5,
                        (index) => IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRating = index + 1;
                                    _errorMessage = null;
                                  });
                                },
                          iconSize: 34,
                          splashRadius: 24,
                          icon: Icon(
                            index < _selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: index < _selectedRating
                                ? const Color(0xffF59E0B)
                                : const Color(0xffCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _selectedRating == 0
                          ? (isRtl
                              ? 'اختر عدد النجوم أولاً'
                              : 'Select a star rating first')
                          : _labelForRating(_selectedRating, isRtl),
                      style: TextStyle(
                        color: _selectedRating == 0
                            ? const Color(0xff64748B)
                            : AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    maxLength: 500,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: isRtl ? 'تعليق اختياري' : 'Optional comment',
                      hintText: isRtl
                          ? 'اكتب ملاحظتك إن رغبت'
                          : 'Share any note if you want',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xffE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xffE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffFECACA)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xffB91C1C),
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed:
                          (_selectedRating == 0 || _isSubmitting) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isRtl ? 'إرسال التقييم' : 'Submit Rating',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedRating <= 0 || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await widget.onSubmit(
      _selectedRating,
      _commentController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.message;
      });
      return;
    }

    Navigator.of(context).pop(
      DriverRatingBottomSheetResult(
        rating: result.rating ?? _selectedRating,
        message: result.message,
        driverId: result.driverId,
        shipmentId: result.shipmentId,
      ),
    );
  }

  String _labelForRating(int rating, bool isRtl) {
    final label = _ratingLabels[rating];
    if (label == null) {
      return '';
    }
    return isRtl ? label.$2 : label.$1;
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.avatar,
    required this.fallbackLabel,
  });

  final String? avatar;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final imagePath = avatar?.trim() ?? '';
    final initials = fallbackLabel.isNotEmpty ? fallbackLabel[0] : 'D';
    final imageUrl = imagePath.isEmpty
        ? ''
        : imagePath.startsWith('http')
            ? imagePath
            : 'https://dashboard.blockatie.com/${imagePath.replaceFirst(RegExp(r"^/+"), "")}';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FallbackAvatar(initials: initials),
            )
          : _FallbackAvatar(initials: initials),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
