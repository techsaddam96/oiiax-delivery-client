import 'dart:async';

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/productsType_model.dart';
import 'package:blockatie/provider/add_shipment_provider.dart';
import 'package:blockatie/provider/profile.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:blockatie/provider/shipment_instant.dart';
import 'package:blockatie/services/regions_service.dart';
import 'package:blockatie/services/shipment_services.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/nav.dart';
import 'package:blockatie/utils/time/jordan_time.dart';
import 'package:blockatie/views/pages/add_shipment/add_shipment_reference_data.dart';
import 'package:blockatie/views/pages/location_picker/location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

part 'add_shipment_widgets.dart';

/// The guided steps of the one Add Shipment screen, in order.
enum ShipmentStep { recipient, location, shipment, payment, review }

/// Guided shipment creation: Recipient → Location → Shipment → Payment →
/// Review, as progressive sections of one screen.
///
/// Keyboard: the page's own Scaffold resizes for the keyboard - the only place
/// the keyboard inset is applied. The scroll view carries no keyboard padding,
/// and the app shell's floating nav bar (behind the keyboard while it is up)
/// stops reserving bottom space while the keyboard is open.
class AddShipmentPage extends StatefulWidget {
  const AddShipmentPage({
    super.key,
    this.referenceData = const ServiceAddShipmentReferenceData(),
    this.quoteLoader,
  });

  final AddShipmentReferenceData referenceData;
  final DeliveryQuoteLoader? quoteLoader;

  @override
  State<AddShipmentPage> createState() => _AddShipmentPageState();
}

/// The first problem a step has, and where to take the user for it.
class _StepIssue {
  const _StepIssue(
      {this.focusNode, this.anchor, this.expandsMoreDetails = false});

  final FocusNode? focusNode;
  final GlobalKey? anchor;
  final bool expandsMoreDetails;
}

class _AddShipmentPageState extends State<AddShipmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeSectionKey = GlobalKey();
  final GlobalKey _areaKey = GlobalKey();
  final GlobalKey _pinKey = GlobalKey();
  final GlobalKey _deliveryTypeKey = GlobalKey();
  final GlobalKey _productTypeKey = GlobalKey();
  final GlobalKey _scheduleKey = GlobalKey();

  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _recipientPhoneController =
      TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _shipmentCostController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _piecesCountController = TextEditingController();
  final TextEditingController _shipmentNoteController = TextEditingController();

  final FocusNode _recipientNameFocus = FocusNode();
  final FocusNode _recipientPhoneFocus = FocusNode();
  final FocusNode _deliveryAddressFocus = FocusNode();
  final FocusNode _shipmentCostFocus = FocusNode();
  final FocusNode _referenceFocus = FocusNode();
  final FocusNode _piecesCountFocus = FocusNode();
  final FocusNode _shipmentNoteFocus = FocusNode();

  DateTime _scheduledAt = JordanTime.now().add(const Duration(minutes: 10));
  int? _selectedRegionId;
  int? _selectedProductTypeId;
  int? _selectedDeliveryTypeId;
  String _paymentType = 'cod';
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedMapAddress = '';

  ShipmentStep _step = ShipmentStep.recipient;
  ShipmentStep _furthestStep = ShipmentStep.recipient;
  final Set<ShipmentStep> _attemptedSteps = <ShipmentStep>{};
  bool _showMoreDetails = false;
  String? _scheduleError;
  String? _deliveryTypeError;
  String? _submitError;
  final GlobalKey _submitErrorKey = GlobalKey();

  DeliveryQuote? _deliveryQuote;
  bool _isLoadingDeliveryQuote = false;
  String? _deliveryQuoteError;
  int _deliveryQuoteRevision = 0;

  bool _isInitializing = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReferenceData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _deliveryAddressController.dispose();
    _shipmentCostController.dispose();
    _referenceController.dispose();
    _piecesCountController.dispose();
    _shipmentNoteController.dispose();
    _recipientNameFocus.dispose();
    _recipientPhoneFocus.dispose();
    _deliveryAddressFocus.dispose();
    _shipmentCostFocus.dispose();
    _referenceFocus.dispose();
    _piecesCountFocus.dispose();
    _shipmentNoteFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- reference data

  Future<void> _initializeReferenceData({bool force = false}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    final provider = context.read<AddShipmentProvider>();

    try {
      final loadedProducts = await provider.getProductTypes(force: force);
      await widget.referenceData.load(force: force);

      final productTypes = provider.productsType?.productsTypes ?? const [];
      final deliveryTypes = _availableDeliveryTypes();

      if (!loadedProducts ||
          productTypes.isEmpty ||
          deliveryTypes.isEmpty ||
          widget.referenceData.regions.isEmpty) {
        throw Exception('REFERENCE_DATA_UNAVAILABLE');
      }

      if (_selectedProductTypeId == null) {
        _selectedProductTypeId = int.tryParse(productTypes.first.id);
        provider.setProductTypeSelected(_selectedProductTypeId != null);
      }

      if (_selectedDeliveryTypeId == null) {
        _selectedDeliveryTypeId =
            int.tryParse(deliveryTypes.first['id'].toString());
        provider.setDeliveryTypeSelected(_selectedDeliveryTypeId != null);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _initializationError = _text(
          'Unable to prepare shipment options right now. Please try again.',
          'تعذر تجهيز خيارات الشحنة حالياً. حاول مرة أخرى.',
        );
      });
    }
  }

  List<Map<String, dynamic>> _availableDeliveryTypes() {
    final deliveryTypes = widget.referenceData.deliveryTypes;
    if (_hasInstantAccess) {
      return deliveryTypes;
    }

    return deliveryTypes
        .where((type) => int.tryParse(type['id'].toString()) == 2)
        .toList();
  }

  bool get _hasInstantAccess =>
      context.read<ProfileProvider>().profileInfo?.subscription == 1;

  tz.TZDateTime _jordanWallClock(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    return tz.TZDateTime(JordanTime.location, year, month, day, hour, minute);
  }

  // ---------------------------------------------------------------- pickers

  Future<void> _selectDate() async {
    final now = JordanTime.now();
    final firstDate = _jordanWallClock(now.year, now.month, now.day, 0, 0);
    final initialDate =
        _scheduledAt.isBefore(firstDate) ? firstDate : _scheduledAt;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = _jordanWallClock(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
      _scheduleError = null;
    });
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = _jordanWallClock(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      _scheduleError = null;
    });
  }

  Future<void> _openLocationPicker() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocationPickerPage(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          onLocationSelected: (latitude, longitude, address) {
            if (!mounted) {
              return;
            }

            setState(() {
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
              _selectedMapAddress = address.trim();
            });

            if (_deliveryAddressController.text.trim().isEmpty &&
                address.trim().isNotEmpty) {
              _deliveryAddressController.text = address.trim();
              context.read<AddShipmentProvider>().validateDeliveryAddress(
                    _deliveryAddressController.text,
                  );
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickArea() async {
    FocusScope.of(context).unfocus();
    final regions = widget.referenceData.regions;
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AreaPickerSheet(
        regions: regions,
        selectedId: _selectedRegionId,
        title: _text('Delivery area', 'منطقة التوصيل'),
        searchHint: _text('Search areas', 'ابحث عن منطقة'),
        emptyLabel: _text('No matching area', 'لا توجد منطقة مطابقة'),
        arabic: AppLocalizations.isArabic,
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedRegionId = picked;
    });
    context.read<AddShipmentProvider>().setRegionSelected(true);
    unawaited(_refreshDeliveryQuote());
  }

  bool get _hasCurrentDeliveryQuote {
    final quote = _deliveryQuote;
    return !_isLoadingDeliveryQuote &&
        _deliveryQuoteError == null &&
        quote != null &&
        quote.regionId == _selectedRegionId &&
        quote.deliveryTypeId == _selectedDeliveryTypeId;
  }

  String _deliveryQuoteDisplay() {
    if (_selectedRegionId == null || _selectedDeliveryTypeId == null) {
      return _text(
        'Choose an area and delivery type to calculate the price.',
        'اختر المنطقة ونوع التوصيل لاحتساب السعر.',
      );
    }
    if (_isLoadingDeliveryQuote) {
      return _text(
        'Calculating the delivery price…',
        'جارٍ احتساب سعر التوصيل…',
      );
    }
    if (_deliveryQuoteError != null) {
      return _deliveryQuoteError!;
    }
    final quote = _deliveryQuote;
    if (quote == null) {
      return _text(
        'Delivery price must be calculated before creating the shipment.',
        'يجب احتساب سعر التوصيل قبل إنشاء الشحنة.',
      );
    }
    return '${quote.deliveryCost.toStringAsFixed(2)} ${quote.currency} · '
        '${_regionName(quote.regionId)}';
  }

  Future<void> _refreshDeliveryQuote() async {
    final regionId = _selectedRegionId;
    final deliveryTypeId = _selectedDeliveryTypeId;
    final revision = ++_deliveryQuoteRevision;
    if (regionId == null || deliveryTypeId == null) {
      if (mounted) {
        setState(() {
          _isLoadingDeliveryQuote = false;
          _deliveryQuote = null;
          _deliveryQuoteError = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingDeliveryQuote = true;
      _deliveryQuote = null;
      _deliveryQuoteError = null;
    });

    try {
      final quote = await (widget.quoteLoader ?? ShipmentService.getDeliveryQuote)(
        regionId: regionId,
        deliveryTypeId: deliveryTypeId,
      );
      if (!mounted || revision != _deliveryQuoteRevision) {
        return;
      }
      setState(() {
        _isLoadingDeliveryQuote = false;
        _deliveryQuote = quote;
      });
    } catch (error) {
      if (!mounted || revision != _deliveryQuoteRevision) {
        return;
      }
      setState(() {
        _isLoadingDeliveryQuote = false;
        _deliveryQuote = null;
        _deliveryQuoteError = error is ShipmentServiceException
            ? error.localizedMessage(AppLocalizations.isArabic)
            : _text(
                'Unable to calculate the delivery price right now.',
                'تعذر احتساب سعر التوصيل حالياً.',
              );
      });
    }
  }

  // ---------------------------------------------------------------- validation (unchanged rules)

  String _text(String en, String ar) {
    return AppLocalizations.isArabic ? ar : en;
  }

  String _normalizeJordanPhone(String value) {
    var phone = value.replaceAll(RegExp(r'\D'), '');

    if (phone.startsWith('00962')) {
      phone = phone.substring(5);
    } else if (phone.startsWith('962')) {
      phone = phone.substring(3);
    }

    if (phone.isNotEmpty && !phone.startsWith('0')) {
      phone = '0$phone';
    }

    return phone;
  }

  bool _isValidJordanPhone(String phone) {
    return RegExp(r'^07[789]\d{7}$').hasMatch(phone);
  }

  bool _isValidCoordinatePair() {
    if (_selectedLatitude == null && _selectedLongitude == null) {
      return true;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      return false;
    }

    final latitude = _selectedLatitude!;
    final longitude = _selectedLongitude!;

    if (latitude < -90 || latitude > 90) {
      return false;
    }

    if (longitude < -180 || longitude > 180) {
      return false;
    }

    if (latitude == 0 && longitude == 0) {
      return false;
    }

    return true;
  }

  String? _validateRecipientName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return _text(
        'Recipient name is required.',
        'اسم المستلم مطلوب.',
      );
    }

    if (name.length < 2) {
      return _text(
        'Recipient name must be at least 2 characters.',
        'يجب أن يحتوي اسم المستلم على حرفين على الأقل.',
      );
    }

    if (name.length > 255) {
      return _text(
        'Recipient name is too long.',
        'اسم المستلم أطول من الحد المسموح.',
      );
    }

    return null;
  }

  String? _validateRecipientPhone(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return _text(
        'Recipient phone is required.',
        'رقم هاتف المستلم مطلوب.',
      );
    }

    final normalized = _normalizeJordanPhone(input);
    if (!_isValidJordanPhone(normalized)) {
      return _text(
        'Use a valid Jordan mobile number like 077, 078, or 079.',
        'استخدم رقم هاتف أردني صالح يبدأ بـ 077 أو 078 أو 079.',
      );
    }

    return null;
  }

  String? _validateDeliveryAddress(String? value) {
    final address = value?.trim() ?? '';

    if (address.isEmpty) {
      return _text(
        'Delivery address is required.',
        'عنوان التوصيل مطلوب.',
      );
    }

    if (address.length < 8) {
      return _text(
        'Enter a more detailed delivery address.',
        'يرجى إدخال عنوان توصيل أكثر تفصيلاً.',
      );
    }

    if (address.length > 500) {
      return _text(
        'Delivery address is too long.',
        'عنوان التوصيل أطول من الحد المسموح.',
      );
    }

    return null;
  }

  bool get _isPrepaid => _paymentType == 'prepaid';

  /// Prepaid locks the value at 0 so the two fields can never contradict;
  /// switching back to COD clears it for the merchant to enter.
  void _setPaymentType(String value) {
    if (value == _paymentType) {
      return;
    }
    setState(() {
      _paymentType = value;
      _shipmentCostController.text = value == 'prepaid' ? '0' : '';
    });
    context.read<AddShipmentProvider>().validateShipmentCost(
          _shipmentCostController.text,
          prepaid: _isPrepaid,
        );
  }

  String? _validateShipmentCost(String? value) {
    final normalized = value?.trim() ?? '';

    if (_isPrepaid) {
      return double.tryParse(normalized) == 0
          ? null
          : _text(
              'A prepaid shipment has no amount to collect.',
              'الشحنة المدفوعة مسبقاً ليس لها مبلغ تحصيل.',
            );
    }

    if (normalized.isEmpty) {
      return _text(
        'Shipment value is required.',
        'قيمة الشحنة مطلوبة.',
      );
    }

    final parsedValue = double.tryParse(normalized);
    if (parsedValue == null || parsedValue <= 0) {
      return _text(
        'Enter a valid shipment value greater than zero.',
        'يرجى إدخال قيمة صحيحة للشحنة أكبر من صفر.',
      );
    }

    return null;
  }

  String? _validateReference(String? value) {
    final reference = value?.trim() ?? '';

    if (reference.isEmpty) {
      return null;
    }

    if (reference.length > 100) {
      return _text(
        'Reference is too long.',
        'المرجع أطول من الحد المسموح.',
      );
    }

    return null;
  }

  String? _validatePiecesCount(String? value) {
    final rawValue = value?.trim() ?? '';

    if (rawValue.isEmpty) {
      return null;
    }

    final piecesCount = int.tryParse(rawValue);
    if (piecesCount == null || piecesCount <= 0) {
      return _text(
        'Enter a valid pieces count.',
        'يرجى إدخال عدد قطع صحيح.',
      );
    }

    if (piecesCount > 9999) {
      return _text(
        'Pieces count is too large.',
        'عدد القطع أكبر من الحد المسموح.',
      );
    }

    return null;
  }

  /// The first problem in [step], using the same rules the form always used.
  _StepIssue? _issueFor(ShipmentStep step) {
    switch (step) {
      case ShipmentStep.recipient:
        if (_validateRecipientName(_recipientNameController.text) != null) {
          return _StepIssue(focusNode: _recipientNameFocus);
        }
        if (_validateRecipientPhone(_recipientPhoneController.text) != null) {
          return _StepIssue(focusNode: _recipientPhoneFocus);
        }
        return null;
      case ShipmentStep.location:
        if (_selectedRegionId == null) {
          return _StepIssue(anchor: _areaKey);
        }
        if (!_isValidCoordinatePair()) {
          return _StepIssue(anchor: _pinKey);
        }
        if (_validateDeliveryAddress(_deliveryAddressController.text) != null) {
          return _StepIssue(focusNode: _deliveryAddressFocus);
        }
        return null;
      case ShipmentStep.shipment:
        if (_selectedDeliveryTypeId == null) {
          return _StepIssue(anchor: _deliveryTypeKey);
        }
        if (_selectedProductTypeId == null) {
          return _StepIssue(anchor: _productTypeKey);
        }
        if (_scheduleError != null) {
          return _StepIssue(anchor: _scheduleKey);
        }
        if (_validateReference(_referenceController.text) != null) {
          return _StepIssue(
              focusNode: _referenceFocus, expandsMoreDetails: true);
        }
        if (_validatePiecesCount(_piecesCountController.text) != null) {
          return _StepIssue(
              focusNode: _piecesCountFocus, expandsMoreDetails: true);
        }
        return null;
      case ShipmentStep.payment:
        if (_validateShipmentCost(_shipmentCostController.text) != null) {
          return _isPrepaid ? null : _StepIssue(focusNode: _shipmentCostFocus);
        }
        return null;
      case ShipmentStep.review:
        return null;
    }
  }

  // ---------------------------------------------------------------- step navigation

  void _goTo(ShipmentStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      if (step.index > _furthestStep.index) {
        _furthestStep = step;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _activeSectionKey.currentContext;
      if (!mounted || sectionContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Shows the step's errors and takes the user to the exact field.
  void _reveal(ShipmentStep step, _StepIssue issue) {
    setState(() {
      _attemptedSteps.add(step);
      if (issue.expandsMoreDetails) {
        _showMoreDetails = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final node = issue.focusNode;
      if (node != null) {
        // Focusing scrolls the field just into view above the keyboard.
        node.requestFocus();
        return;
      }
      final anchorContext = issue.anchor?.currentContext;
      if (anchorContext != null) {
        Scrollable.ensureVisible(
          anchorContext,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      }
    });
  }

  void _continue() {
    final current = _step;
    final issue = _issueFor(current);
    if (issue != null) {
      _reveal(current, issue);
      return;
    }

    // Editing an earlier step from the review returns there once every
    // step in between is still complete.
    if (_furthestStep == ShipmentStep.review) {
      for (final step in ShipmentStep.values) {
        if (step.index <= current.index || step == ShipmentStep.review) {
          continue;
        }
        if (_issueFor(step) != null) {
          _goTo(step);
          return;
        }
      }
      _goTo(ShipmentStep.review);
      return;
    }

    _goTo(ShipmentStep.values[current.index + 1]);
  }

  void _back() {
    if (_step.index == 0) {
      return;
    }
    _goTo(ShipmentStep.values[_step.index - 1]);
  }

  // ---------------------------------------------------------------- submit (unchanged contract)

  String _resolveSubmissionError(Object error) {
    if (error is ShipmentServiceException) {
      return error.localizedMessage(AppLocalizations.isArabic);
    }

    return _text(
      'Unable to create the shipment right now. Please try again.',
      'تعذر إنشاء الشحنة حالياً. حاول مرة أخرى.',
    );
  }

  Future<void> _submitForm() async {
    final provider = context.read<AddShipmentProvider>();
    if (provider.isSubmitting) {
      return;
    }

    // Errors are shown inline next to their cause: a floating snack bar
    // would sit on the bottom actions.
    if (!_hasInstantAccess && _selectedDeliveryTypeId != 2) {
      _deliveryTypeError = _text(
        'Instant shipments are not enabled for this account.',
        'الشحنات الفورية غير مفعلة لهذا الحساب.',
      );
      _goTo(ShipmentStep.shipment);
      _reveal(ShipmentStep.shipment, _StepIssue(anchor: _deliveryTypeKey));
      return;
    }

    FocusScope.of(context).unfocus();

    provider.validateRecipientName(_recipientNameController.text);
    provider.validateRecipientPhone(
      _normalizeJordanPhone(_recipientPhoneController.text),
    );
    provider.validateDeliveryAddress(_deliveryAddressController.text);
    provider.validateShipmentCost(
      _shipmentCostController.text,
      prepaid: _isPrepaid,
    );
    provider.setRegionSelected(_selectedRegionId != null);
    provider.setProductTypeSelected(_selectedProductTypeId != null);
    provider.setDeliveryTypeSelected(_selectedDeliveryTypeId != null);

    final minimumAllowed =
        JordanTime.now().subtract(const Duration(minutes: 5));
    if (_scheduledAt.isBefore(minimumAllowed)) {
      _scheduleError = _text(
        'Choose a shipment time that is not in the past.',
        'اختر موعد شحنة غير واقع في الماضي.',
      );
    }

    for (final step in ShipmentStep.values) {
      final issue = _issueFor(step);
      if (issue != null) {
        _goTo(step);
        _reveal(step, issue);
        return;
      }
    }

    if (!_hasCurrentDeliveryQuote) {
      setState(() {
        _submitError = _deliveryQuoteError ??
            (_isLoadingDeliveryQuote
                ? _text(
                    'Delivery price is still loading. Please wait before creating the shipment.',
                    'جارٍ تحميل سعر التوصيل. يرجى الانتظار قبل إنشاء الشحنة.',
                  )
                : _text(
                    'Delivery price must be calculated before creating the shipment.',
                    'يجب احتساب سعر التوصيل قبل إنشاء الشحنة.',
                  ));
      });
      return;
    }

    setState(() {
      _submitError = null;
    });

    try {
      final success = await provider.addShipment(
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _normalizeJordanPhone(
          _recipientPhoneController.text.trim(),
        ),
        regionId: _selectedRegionId!,
        deliveryAddress: _deliveryAddressController.text.trim(),
        shipmentCost: _shipmentCostController.text.trim(),
        productTypeId: _selectedProductTypeId!,
        deliveryTypeId: _selectedDeliveryTypeId!,
        shipmentDate: _scheduledAt,
        deliveryLatitude: _selectedLatitude,
        deliveryLongitude: _selectedLongitude,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        piecesCount: _piecesCountController.text.trim().isEmpty
            ? null
            : int.tryParse(_piecesCountController.text.trim()),
        note: _shipmentNoteController.text.trim().isEmpty
            ? null
            : _shipmentNoteController.text.trim(),
        paymentType: _paymentType,
        quotedDeliveryCost: _deliveryQuote!.deliveryCost,
      );

      if (!mounted || !success) {
        return;
      }

      unawaited(context.read<ShipmentProvider>().getClientShipments());
      if (_selectedDeliveryTypeId != 2) {
        unawaited(
            context.read<ShipmentInstantprovider>().getShipmentsInstant());
      }

      final createdShipment = provider.lastCreatedShipment ?? const {};
      final policyNumber =
          (createdShipment['policy_number'] ?? createdShipment['policy_num'])
              ?.toString();
      final createdDeliveryCost = createdShipment['delivery_cost'];

      await _showSuccessDialog(policyNumber, createdDeliveryCost);
      if (!mounted) {
        return;
      }
      Nav.back(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = _resolveSubmissionError(error);
      setState(() {
        _submitError = message;
      });
      if (error is ShipmentServiceException &&
          error.code == 'DELIVERY_PRICE_CHANGED') {
        unawaited(_refreshDeliveryQuote());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bannerContext = _submitErrorKey.currentContext;
        if (mounted && bannerContext != null) {
          Scrollable.ensureVisible(
            bannerContext,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  Future<void> _showSuccessDialog(
    String? policyNumber,
    dynamic deliveryCost,
  ) async {
    final parsedDeliveryCost = deliveryCost is num
        ? deliveryCost.toDouble()
        : double.tryParse(deliveryCost?.toString() ?? '');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SuccessDialog(
        title: _text('Shipment created', 'تم إنشاء الشحنة'),
        message: _text(
          'The shipment was created successfully and is now ready for follow-up.',
          'تم إنشاء الشحنة بنجاح وأصبحت جاهزة للمتابعة.',
        ),
        policyLabel: _text('Policy number', 'رقم الشحنة'),
        policyNumber: policyNumber,
        deliveryFeeLabel: _text('Delivery fee', 'أجرة التوصيل'),
        deliveryFee: parsedDeliveryCost == null
            ? null
            : '${parsedDeliveryCost.toStringAsFixed(2)} ${_text('JOD', 'د.أ')}',
        doneLabel: _text('Done', 'تم'),
        onDone: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  // ---------------------------------------------------------------- labels

  String _stepTitle(ShipmentStep step) {
    switch (step) {
      case ShipmentStep.recipient:
        return _text('Recipient', 'بيانات المستلم');
      case ShipmentStep.location:
        return _text('Delivery location', 'موقع التسليم');
      case ShipmentStep.shipment:
        return _text('Shipment details', 'تفاصيل الشحنة');
      case ShipmentStep.payment:
        return _text('Payment', 'الدفع');
      case ShipmentStep.review:
        return _text('Review', 'المراجعة');
    }
  }

  String _stepShortLabel(ShipmentStep step) {
    switch (step) {
      case ShipmentStep.recipient:
        return _text('Recipient', 'المستلم');
      case ShipmentStep.location:
        return _text('Location', 'الموقع');
      case ShipmentStep.shipment:
        return _text('Shipment', 'الشحنة');
      case ShipmentStep.payment:
        return _text('Payment', 'الدفع');
      case ShipmentStep.review:
        return _text('Review', 'المراجعة');
    }
  }

  String _stepSubtitle(ShipmentStep step) {
    switch (step) {
      case ShipmentStep.recipient:
        return _text('Who receives this shipment?', 'من سيستلم هذه الشحنة؟');
      case ShipmentStep.location:
        return _text(
            'Where should the driver deliver?', 'إلى أين سيوصل السائق الشحنة؟');
      case ShipmentStep.shipment:
        return _text('Service, type and timing.', 'الخدمة والنوع والموعد.');
      case ShipmentStep.payment:
        return _text('How is this shipment paid?', 'كيف تُدفع هذه الشحنة؟');
      case ShipmentStep.review:
        return _text('Check everything before creating.',
            'راجع كل البيانات قبل الإنشاء.');
    }
  }

  String _regionName(int? id) {
    if (id == null) {
      return '';
    }
    for (final region in widget.referenceData.regions) {
      if (region.id == id) {
        return AppLocalizations.isArabic ? region.anregion : region.enregion;
      }
    }
    return '';
  }

  String _deliveryTypeName(Map<String, dynamic> type) {
    final ar = type['type_name_ar']?.toString().trim() ?? '';
    final en = type['type_name_en']?.toString().trim() ?? '';
    if (AppLocalizations.isArabic) {
      return ar.isNotEmpty ? ar : en;
    }
    return en.isNotEmpty ? en : ar;
  }

  String _deliveryTypeDescription(Map<String, dynamic> type) {
    return (AppLocalizations.isArabic
                ? type['description_ar']
                : type['description_en'])
            ?.toString()
            .trim() ??
        '';
  }

  String _deliveryTypeNameById(int? id) {
    for (final type in widget.referenceData.deliveryTypes) {
      if (int.tryParse(type['id'].toString()) == id) {
        return _deliveryTypeName(type);
      }
    }
    return '';
  }

  String _productTypeName(List<ProductsTypes> types, int? id) {
    for (final type in types) {
      if (int.tryParse(type.id) == id) {
        return AppLocalizations.isArabic ? type.typeNameAr : type.typeNameEn;
      }
    }
    return '';
  }

  String _formattedDateLabel() {
    final date = _scheduledAt;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formattedTimeLabel() {
    final date = _scheduledAt;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _paymentLabel() => _isPrepaid
      ? _text('Prepaid', 'مدفوع مسبقاً')
      : _text('Cash on delivery', 'الدفع عند الاستلام');

  String _codAmountLabel() =>
      '${_shipmentCostController.text.trim()} ${_text('JOD', 'د.أ')}';

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // Read above this page's Scaffold: the shell passes the keyboard inset
    // through, and its floating nav bar sits behind the keyboard while it is up.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: _FlowColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: !keyboardOpen,
        child: _isInitializing
            ? const _ReferenceLoadingState()
            : _initializationError != null
                ? _ReferenceErrorState(
                    message: _initializationError!,
                    onRetry: () => _initializeReferenceData(force: true),
                  )
                : _buildFlow(context, keyboardOpen),
      ),
    );
  }

  Widget _buildFlow(BuildContext context, bool keyboardOpen) {
    final productTypes =
        context.select<AddShipmentProvider, List<ProductsTypes>>(
            (p) => p.productsType?.productsTypes ?? const []);

    final sections = <Widget>[];
    for (final step in ShipmentStep.values) {
      // The review lists every step itself, each with its own Edit.
      if (_step == ShipmentStep.review && step != _step) {
        continue;
      }
      if (step == _step) {
        sections.add(
          _ActiveStepCard(
            key: _activeSectionKey,
            number: step.index + 1,
            title: _stepTitle(step),
            subtitle: _stepSubtitle(step),
            child: _buildStepBody(step, productTypes),
          ),
        );
      } else if (step.index < _step.index ||
          (step.index <= _furthestStep.index && step != ShipmentStep.review)) {
        sections.add(
          _CompletedStepCard(
            number: step.index + 1,
            title: _stepTitle(step),
            summary: _summaryFor(step, productTypes),
            editLabel: _text('Edit', 'تعديل'),
            editSemanticLabel: '${_text('Edit', 'تعديل')} ${_stepTitle(step)}',
            onEdit: () => _goTo(step),
          ),
        );
      } else {
        sections.add(
          _UpcomingStepTile(
            number: step.index + 1,
            title: _stepTitle(step),
          ),
        );
      }
      sections.add(const SizedBox(height: 12));
    }

    // On a short phone with the keyboard up, the form needs every pixel: the
    // header steps aside until the keyboard closes (the active card still
    // names the step).
    final hideHeader = keyboardOpen && MediaQuery.sizeOf(context).height < 700;

    return Column(
      children: [
        if (!hideHeader)
          _FlowHeader(
            title: _text('Add Shipment', 'إضافة شحنة'),
            backLabel: _text('Back', 'رجوع'),
            stepLabels: ShipmentStep.values.map(_stepShortLabel).toList(),
            currentIndex: _step.index,
            counterLabel: _text(
              'Step ${_step.index + 1} of ${ShipmentStep.values.length}',
              'الخطوة ${_step.index + 1} من ${ShipmentStep.values.length}',
            ),
            compact: keyboardOpen,
            onBack: Nav.back,
          ),
        Expanded(
          child: Form(
            key: _formKey,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _initializeReferenceData(force: true),
              child: SingleChildScrollView(
                key: const Key('addShipmentScroll'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                // No keyboard inset here: the Scaffold already sits above it.
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sections,
                ),
              ),
            ),
          ),
        ),
        Selector<AddShipmentProvider, bool>(
          selector: (_, p) => p.isSubmitting,
          builder: (context, submitting, _) {
            final onReview = _step == ShipmentStep.review;
            return _FlowCtaBar(
              key: const Key('addShipmentCta'),
              primaryLabel: onReview
                  ? _text('Create Shipment', 'إنشاء الشحنة')
                  : _furthestStep == ShipmentStep.review
                      ? _text('Save & review', 'حفظ والعودة للمراجعة')
                      : _text('Continue', 'متابعة'),
              loadingLabel:
                  _text('Creating shipment...', 'جارٍ إنشاء الشحنة...'),
              backLabel: _text('Previous', 'السابق'),
              showBack: _step.index > 0,
              loading: submitting,
              onPrimary: onReview ? _submitForm : _continue,
              onBack: _back,
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- step bodies

  Widget _buildStepBody(ShipmentStep step, List<ProductsTypes> productTypes) {
    final showErrors = _attemptedSteps.contains(step);
    switch (step) {
      case ShipmentStep.recipient:
        return _buildRecipientStep(showErrors);
      case ShipmentStep.location:
        return _buildLocationStep(showErrors);
      case ShipmentStep.shipment:
        return _buildShipmentStep(showErrors, productTypes);
      case ShipmentStep.payment:
        return _buildPaymentStep(showErrors);
      case ShipmentStep.review:
        return _buildReviewStep(productTypes);
    }
  }

  Widget _buildRecipientStep(bool showErrors) {
    final provider = context.read<AddShipmentProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FlowTextField(
          fieldKey: const Key('recipientName'),
          controller: _recipientNameController,
          focusNode: _recipientNameFocus,
          label: _text('Recipient name', 'اسم المستلم'),
          hint: _text('Full name', 'الاسم الكامل'),
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          showErrors: showErrors,
          validator: _validateRecipientName,
          onChanged: provider.validateRecipientName,
          onSubmitted: (_) => _recipientPhoneFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        _FlowTextField(
          fieldKey: const Key('recipientPhone'),
          controller: _recipientPhoneController,
          focusNode: _recipientPhoneFocus,
          label: _text('Phone number', 'رقم الهاتف'),
          hint: '07XXXXXXXX',
          helper: _text('Jordan mobile: 077, 078 or 079',
              'رقم أردني يبدأ بـ 077 أو 078 أو 079'),
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          forceLtr: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          ],
          showErrors: showErrors,
          validator: _validateRecipientPhone,
          onChanged: (value) =>
              provider.validateRecipientPhone(_normalizeJordanPhone(value)),
          onSubmitted: (_) => _continue(),
        ),
      ],
    );
  }

  Widget _buildLocationStep(bool showErrors) {
    final provider = context.read<AddShipmentProvider>();
    final regionName = _regionName(_selectedRegionId);
    final hasPin = _selectedLatitude != null && _selectedLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorTile(
          key: _areaKey,
          tileKey: const Key('areaSelector'),
          label: _text('Area', 'المنطقة'),
          value: regionName,
          placeholder: _text('Choose the delivery area', 'اختر منطقة التوصيل'),
          icon: Icons.map_outlined,
          errorText: showErrors && _selectedRegionId == null
              ? _text(
                  'Select the delivery region.', 'يرجى اختيار منطقة التوصيل.')
              : null,
          onTap: _pickArea,
        ),
        const SizedBox(height: 14),
        _MapPinCard(
          key: _pinKey,
          title: _text('Pin on the map', 'الموقع على الخريطة'),
          emptyHint: _text(
            'Optional - helps the driver find the door faster.',
            'اختياري - يساعد السائق على الوصول بسرعة أكبر.',
          ),
          address: _selectedMapAddress,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          actionLabel:
              hasPin ? _text('Change', 'تغيير') : _text('Choose', 'اختيار'),
          errorText: showErrors && !_isValidCoordinatePair()
              ? _text('Selected map coordinates are not valid.',
                  'إحداثيات الموقع المحددة غير صالحة.')
              : null,
          onTap: _openLocationPicker,
        ),
        const SizedBox(height: 14),
        _FlowTextField(
          fieldKey: const Key('deliveryAddress'),
          controller: _deliveryAddressController,
          focusNode: _deliveryAddressFocus,
          label: _text('Detailed address', 'العنوان التفصيلي'),
          hint: _text(
            'Street, building, landmark, floor...',
            'الشارع، البناية، العلامة الفارقة، الطابق...',
          ),
          icon: Icons.location_on_outlined,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 2,
          maxLines: 4,
          showErrors: showErrors,
          validator: _validateDeliveryAddress,
          onChanged: provider.validateDeliveryAddress,
        ),
      ],
    );
  }

  Widget _buildShipmentStep(bool showErrors, List<ProductsTypes> productTypes) {
    final provider = context.read<AddShipmentProvider>();
    final deliveryTypes = _availableDeliveryTypes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(_text('Delivery type', 'نوع التوصيل')),
        const SizedBox(height: 8),
        _ChoiceGrid(
          key: _deliveryTypeKey,
          options: [
            for (final type in deliveryTypes)
              if (int.tryParse(type['id'].toString()) != null)
                _Choice(
                  value: int.parse(type['id'].toString()),
                  title: _deliveryTypeName(type),
                  subtitle: _deliveryTypeDescription(type),
                  icon: _deliveryTypeIcon(int.parse(type['id'].toString())),
                ),
          ],
          selected: _selectedDeliveryTypeId,
          onSelected: (value) {
            setState(() {
              _selectedDeliveryTypeId = value;
              _deliveryTypeError = null;
            });
            provider.setDeliveryTypeSelected(true);
            unawaited(_refreshDeliveryQuote());
          },
        ),
        if (_deliveryTypeError != null) ...[
          const SizedBox(height: 8),
          _InlineError(_deliveryTypeError!),
        ] else if (showErrors && _selectedDeliveryTypeId == null) ...[
          const SizedBox(height: 8),
          _InlineError(
              _text('Select a delivery type.', 'يرجى اختيار نوع التوصيل.')),
        ],
        const SizedBox(height: 18),
        _FieldLabel(_text('Product type', 'نوع المنتج')),
        const SizedBox(height: 8),
        _ChipChoices(
          key: _productTypeKey,
          options: [
            for (final type in productTypes)
              if (int.tryParse(type.id) != null)
                _Choice(
                  value: int.parse(type.id),
                  title: AppLocalizations.isArabic
                      ? type.typeNameAr
                      : type.typeNameEn,
                ),
          ],
          selected: _selectedProductTypeId,
          onSelected: (value) {
            setState(() {
              _selectedProductTypeId = value;
            });
            provider.setProductTypeSelected(true);
          },
        ),
        if (showErrors && _selectedProductTypeId == null) ...[
          const SizedBox(height: 8),
          _InlineError(
              _text('Select a product type.', 'يرجى اختيار نوع المنتج.')),
        ],
        const SizedBox(height: 18),
        _FieldLabel(_text('Shipment date & time', 'موعد الشحنة')),
        const SizedBox(height: 8),
        Row(
          key: _scheduleKey,
          children: [
            Expanded(
              child: _PickerTile(
                icon: Icons.event_outlined,
                label: _text('Date', 'التاريخ'),
                value: _formattedDateLabel(),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerTile(
                icon: Icons.schedule_rounded,
                label: _text('Time', 'الوقت'),
                value: _formattedTimeLabel(),
                onTap: _selectTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_scheduleError != null)
          _InlineError(_scheduleError!)
        else
          _HintText(
            _selectedDeliveryTypeId == 2
                ? _text(
                    'Scheduled shipments should use the real future delivery date and time.',
                    'الشحنات المجدولة يجب أن تستخدم موعد التنفيذ الفعلي في المستقبل.',
                  )
                : _text(
                    'For fast deliveries, choose the nearest practical execution time.',
                    'للشحنات السريعة، اختر أقرب وقت تنفيذ عملي.',
                  ),
          ),
        const SizedBox(height: 18),
        _FlowTextField(
          fieldKey: const Key('shipmentNote'),
          controller: _shipmentNoteController,
          focusNode: _shipmentNoteFocus,
          label: _text(
              'Notes for the driver (optional)', 'ملاحظات للسائق (اختياري)'),
          hint: _text(
            'Any delivery instructions or order notes...',
            'أي تعليمات للتوصيل أو ملاحظات على الشحنة...',
          ),
          icon: Icons.sticky_note_2_outlined,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 2,
          maxLines: 4,
          showErrors: showErrors,
        ),
        const SizedBox(height: 10),
        _DisclosureRow(
          key: const Key('moreDetailsToggle'),
          label: _text('More details (optional)', 'تفاصيل إضافية (اختياري)'),
          expanded: _showMoreDetails,
          onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: _showMoreDetails
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FlowTextField(
                        fieldKey: const Key('reference'),
                        controller: _referenceController,
                        focusNode: _referenceFocus,
                        label: _text('Reference', 'المرجع'),
                        hint: _text('Optional internal reference',
                            'مرجع داخلي اختياري'),
                        icon: Icons.tag_rounded,
                        textInputAction: TextInputAction.next,
                        showErrors: showErrors,
                        validator: _validateReference,
                        onSubmitted: (_) => _piecesCountFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      _FlowTextField(
                        fieldKey: const Key('piecesCount'),
                        controller: _piecesCountController,
                        focusNode: _piecesCountFocus,
                        label: _text('Pieces count', 'عدد القطع'),
                        hint: _text('Optional number of pieces',
                            'عدد القطع بشكل اختياري'),
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        forceLtr: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        showErrors: showErrors,
                        validator: _validatePiecesCount,
                        onSubmitted: (_) => _continue(),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(bool showErrors) {
    final provider = context.read<AddShipmentProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaymentCard(
          cardKey: const Key('paymentCod'),
          title: _text('Cash on delivery', 'الدفع عند الاستلام'),
          subtitle: _text('The driver collects the product value.',
              'يحصّل السائق قيمة المنتج.'),
          icon: Icons.payments_outlined,
          selected: !_isPrepaid,
          onTap: () => _setPaymentType('cod'),
        ),
        const SizedBox(height: 10),
        _PaymentCard(
          cardKey: const Key('paymentPrepaid'),
          title: _text('Prepaid', 'مدفوع مسبقاً'),
          subtitle: _text('Nothing to collect from the customer.',
              'لا يوجد مبلغ للتحصيل من العميل.'),
          icon: Icons.verified_outlined,
          selected: _isPrepaid,
          onTap: () => _setPaymentType('prepaid'),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isPrepaid
              ? _PaymentNote(
                  key: const ValueKey('prepaidNote'),
                  message: _text(
                    'The customer already paid the merchant; the merchant owes the delivery fee.',
                    'دفع العميل للتاجر مسبقاً؛ والتاجر مدين بأجرة التوصيل.',
                  ),
                )
              : _FlowTextField(
                  key: const ValueKey('codAmountSwitch'),
                  fieldKey: const Key('codAmount'),
                  controller: _shipmentCostController,
                  focusNode: _shipmentCostFocus,
                  label: _text('Amount to collect', 'مبلغ التحصيل'),
                  hint: _text('Shipment value in JOD', 'قيمة الشحنة بالدينار'),
                  icon: Icons.payments_outlined,
                  suffixText: _text('JOD', 'د.أ'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  forceLtr: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  showErrors: showErrors,
                  validator: _validateShipmentCost,
                  onChanged: (value) =>
                      provider.validateShipmentCost(value, prepaid: _isPrepaid),
                  onSubmitted: (_) => _continue(),
                ),
        ),
        const SizedBox(height: 16),
        _DeliveryFeeNote(
          title: _text('Delivery fee', 'أجرة التوصيل'),
          message: _deliveryQuoteDisplay(),
        ),
      ],
    );
  }

  Widget _buildReviewStep(List<ProductsTypes> productTypes) {
    final reference = _referenceController.text.trim();
    final pieces = _piecesCountController.text.trim();
    final note = _shipmentNoteController.text.trim();
    final hasPin = _selectedLatitude != null && _selectedLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewGroup(
          title: _stepTitle(ShipmentStep.recipient),
          editLabel: _text('Edit', 'تعديل'),
          onEdit: () => _goTo(ShipmentStep.recipient),
          rows: [
            _ReviewRow(_text('Recipient', 'المستلم'),
                _recipientNameController.text.trim()),
            _ReviewRow(_text('Phone', 'الهاتف'),
                _normalizeJordanPhone(_recipientPhoneController.text.trim()),
                ltr: true),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewGroup(
          title: _stepTitle(ShipmentStep.location),
          editLabel: _text('Edit', 'تعديل'),
          onEdit: () => _goTo(ShipmentStep.location),
          rows: [
            _ReviewRow(
                _text('Area', 'المنطقة'), _regionName(_selectedRegionId)),
            _ReviewRow(_text('Address', 'العنوان'),
                _deliveryAddressController.text.trim()),
            _ReviewRow(
              _text('Map pin', 'الموقع على الخريطة'),
              hasPin
                  ? _text('Pinned', 'محدد على الخريطة')
                  : _text('Not set', 'غير محدد'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewGroup(
          title: _stepTitle(ShipmentStep.shipment),
          editLabel: _text('Edit', 'تعديل'),
          onEdit: () => _goTo(ShipmentStep.shipment),
          rows: [
            _ReviewRow(_text('Delivery type', 'نوع التوصيل'),
                _deliveryTypeNameById(_selectedDeliveryTypeId)),
            _ReviewRow(_text('Product type', 'نوع المنتج'),
                _productTypeName(productTypes, _selectedProductTypeId)),
            _ReviewRow(_text('Date & time', 'الموعد'),
                '${_formattedDateLabel()}  ${_formattedTimeLabel()}',
                ltr: true),
            if (reference.isNotEmpty)
              _ReviewRow(_text('Reference', 'المرجع'), reference),
            if (pieces.isNotEmpty)
              _ReviewRow(_text('Pieces', 'عدد القطع'), pieces, ltr: true),
            if (note.isNotEmpty) _ReviewRow(_text('Notes', 'ملاحظات'), note),
          ],
        ),
        const SizedBox(height: 10),
        _ReviewGroup(
          title: _stepTitle(ShipmentStep.payment),
          editLabel: _text('Edit', 'تعديل'),
          onEdit: () => _goTo(ShipmentStep.payment),
          rows: [
            _ReviewRow(_text('Payment', 'طريقة الدفع'), _paymentLabel()),
            if (!_isPrepaid)
              _ReviewRow(_text('Amount to collect', 'مبلغ التحصيل'),
                  _codAmountLabel()),
            _ReviewRow(
              _text('Delivery fee', 'أجرة التوصيل'),
              _deliveryQuoteDisplay(),
            ),
          ],
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _submitErrorKey,
            child: _SubmitErrorBanner(
              key: const Key('submitError'),
              message: _submitError!,
            ),
          ),
        ],
      ],
    );
  }

  String _summaryFor(ShipmentStep step, List<ProductsTypes> productTypes) {
    switch (step) {
      case ShipmentStep.recipient:
        return [
          _recipientNameController.text.trim(),
          _normalizeJordanPhone(_recipientPhoneController.text.trim()),
        ].where((part) => part.isNotEmpty).join(' · ');
      case ShipmentStep.location:
        return [
          _regionName(_selectedRegionId),
          _deliveryAddressController.text.trim(),
        ].where((part) => part.isNotEmpty).join(' · ');
      case ShipmentStep.shipment:
        return [
          _deliveryTypeNameById(_selectedDeliveryTypeId),
          _productTypeName(productTypes, _selectedProductTypeId),
          '${_formattedDateLabel()} ${_formattedTimeLabel()}',
        ].where((part) => part.isNotEmpty).join(' · ');
      case ShipmentStep.payment:
        return _isPrepaid
            ? _paymentLabel()
            : '${_paymentLabel()} · ${_codAmountLabel()}';
      case ShipmentStep.review:
        return '';
    }
  }

  IconData _deliveryTypeIcon(int id) {
    switch (id) {
      case 1:
        return Icons.flash_on_rounded;
      case 2:
        return Icons.event_note_rounded;
      case 3:
        return Icons.today_rounded;
      case 4:
        return Icons.calendar_today_rounded;
      case 5:
        return Icons.savings_outlined;
      case 6:
        return Icons.local_fire_department_outlined;
      case 7:
        return Icons.health_and_safety_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}
