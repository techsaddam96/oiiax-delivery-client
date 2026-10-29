import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:blockatie/services/delivery_type_service.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:blockatie/constants/colors.dart';
import 'dart:async';

class DeliveryTypeCustomDropdown extends StatefulWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final String labelText;

  const DeliveryTypeCustomDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelText = 'Type Of Delivery',
  });

  @override
  State<DeliveryTypeCustomDropdown> createState() =>
      _DeliveryTypeCustomDropdownState();
}

class _DeliveryTypeCustomDropdownState
    extends State<DeliveryTypeCustomDropdown> {
  String? _currentDescription;
  bool _showDescription = false;
  Timer? _descriptionTimer;

  @override
  void initState() {
    super.initState();
    _checkAndShowDescription();
  }

  @override
  void didUpdateWidget(DeliveryTypeCustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndShowDescription();
  }

  void _checkAndShowDescription() {
    final deliveryTypes = DeliveryTypeService.getAllDeliveryTypes();
    final isLoading = DeliveryTypeService.isLoading;

    // Show description for different render flows
    if (isLoading) {
      _showRenderDescription(
          'Loading delivery types from server...', Colors.orange);
    } else if (deliveryTypes.isEmpty) {
      _showRenderDescription(
          'No delivery types available. Please check your connection.',
          Colors.red);
    } else if (widget.value != null) {
      // Show description for selected item
      final selectedType = deliveryTypes.firstWhere(
        (type) => int.parse(type['id']) == widget.value,
        orElse: () => {},
      );
      if (selectedType.isNotEmpty && selectedType['description_en'] != null) {
        _showRenderDescription(selectedType['description_en'], Colors.blue);
      }
    } else {
      _showRenderDescription(
          'Select a delivery type to see its description', Colors.grey);
    }
  }

  void _showRenderDescription(String description, Color color) {
    setState(() {
      _currentDescription = description;
      _showDescription = true;
    });

    // Clear previous timer
    _descriptionTimer?.cancel();

    // Auto-hide description after 3 seconds
    _descriptionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showDescription = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryTypes = DeliveryTypeService.getAllDeliveryTypes();
    final isLoading = DeliveryTypeService.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            value: widget.value,
            onChanged: widget.enabled ? widget.onChanged : null,
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                Icons.local_shipping_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 24,
                    ),
            ),
            items: deliveryTypes.map((type) {
              return DropdownMenuItem<int>(
                value: int.parse(type['id']),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppLocalizations.isArabic
                              ? type['type_name_ar']
                              : type['type_name_en'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            validator: widget.validator,
            dropdownColor: Colors.white,
            icon: const SizedBox.shrink(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
            menuMaxHeight: 300,
          ),
          if (_showDescription && _currentDescription != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentDescription!,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

// Alternative compact version without descriptions
class DeliveryTypeCompactDropdown extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final String labelText;

  const DeliveryTypeCompactDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelText = 'Type Of Delivery',
  });

  @override
  Widget build(BuildContext context) {
    final deliveryTypes = DeliveryTypeService.getAllDeliveryTypes();
    final isLoading = DeliveryTypeService.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Spacing.y(1),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              iconSize: 24,
              elevation: 8,
              dropdownColor: Colors.white,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? Colors.black87 : Colors.grey.shade600,
              ),
              items: _buildCompactItems(deliveryTypes, isLoading),
              onChanged: enabled ? onChanged : null,
              hint: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Loading delivery types...'),
                      ],
                    )
                  : Text('Select delivery type'),
            ),
          ),
        ),
        Spacing.y(2),
      ],
    );
  }

  List<DropdownMenuItem<int>> _buildCompactItems(
      List<Map<String, dynamic>> deliveryTypes, bool isLoading) {
    if (deliveryTypes.isEmpty || isLoading) {
      return [
        DropdownMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              Text('Loading delivery types...'),
            ],
          ),
        ),
      ];
    }

    return deliveryTypes.map((type) {
      return DropdownMenuItem<int>(
        value: int.parse(type['id']),
        child: Text(
          type['type_name_en'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }
}
