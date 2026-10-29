import 'package:flutter/material.dart';
import 'package:blockatie/services/delivery_type_service.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:provider/provider.dart';

import '../../provider/add_shipment_provider.dart';
import '../../utils/localization/app_localizations.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? suffixIcon;
  final bool isExpanded;
  final double? menuMaxHeight;

  const CustomDropdownField({
    super.key,
    this.value,
    required this.labelText,
    this.hintText,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.suffixIcon,
    this.isExpanded = true,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          value: value,
          menuMaxHeight: menuMaxHeight,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: isExpanded,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 8,
          dropdownColor: Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Spacing.y(2),
      ],
    );
  }
}

// Specialized dropdown for governorates
class GovernorateDropdown extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const GovernorateDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  static const List<Map<String, dynamic>> _governorates = [
    {'id': 1, 'name': 'Amman'},
    {'id': 2, 'name': 'Zarqa'},
    {'id': 3, 'name': 'Irbid'},
    {'id': 4, 'name': 'Balqa'},
    {'id': 5, 'name': 'Karak'},
    {'id': 6, 'name': 'Tafilah'},
    {'id': 7, 'name': 'Maan'},
    {'id': 8, 'name': 'Ajloun'},
    {'id': 9, 'name': 'Mafraq'},
    {'id': 10, 'name': 'Aqaba'},
    {'id': 11, 'name': 'Jerash'},
    {'id': 12, 'name': 'Madaba'},
  ];

  @override
  Widget build(BuildContext context) {
    return CustomDropdownField<int>(
      value: value,
      labelText: 'Select Governorate and City for Delivery.',
      items: _governorates.map((governorate) {
        return DropdownMenuItem<int>(
          value: governorate['id'] as int,
          child: Text(governorate['name'] as String),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
    );
  }
}

// Specialized dropdown for product types
class ProductTypeDropdown extends StatefulWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const ProductTypeDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<ProductTypeDropdown> createState() => _ProductTypeDropdownState();
}

class _ProductTypeDropdownState extends State<ProductTypeDropdown> {
  @override
  void initState() {
    super.initState();
    // تحميل بيانات المنتج بعد انتهاء build الحالي لتجنب مشاكل notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AddShipmentProvider>(context, listen: false);
      if (provider.productsType == null) {
        provider.getProductTypes();
      }
    });
  }

  String _getLocalizedTypeName(String typeName, String? arName) {
    if (AppLocalizations.isRTL && arName != null && arName.isNotEmpty) {
      return arName;
    }
    return typeName;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddShipmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.productsType == null ||
            provider.productsType!.productsTypes.isEmpty) {
          return const Text('No products loaded');
        }

        return CustomDropdownField<int>(
          value: widget.value,
          labelText: 'Product Type',
          items: provider.productsType!.productsTypes.map((type) {
            return DropdownMenuItem<int>(
              value: int.parse(type.id),
              child:
                  Text(_getLocalizedTypeName(type.typeNameEn, type.typeNameAr)),
            );
          }).toList(),
          onChanged: widget.onChanged,
          validator: widget.validator,
          enabled: widget.enabled,
        );
      },
    );
  }
}

// Specialized dropdown for delivery types
class DeliveryTypeDropdown extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool showDescription;

  const DeliveryTypeDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.showDescription = true, // Default to true to show descriptions
  });

  @override
  Widget build(BuildContext context) {
    final deliveryTypes = DeliveryTypeService.getAllDeliveryTypes();
    final isLoading = DeliveryTypeService.isLoading;

    // Show loading state if delivery types are not loaded yet
    if (deliveryTypes.isEmpty || isLoading) {
      return CustomDropdownField<int>(
        value: value,
        labelText: 'Type Of Delivery',
        items: [
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
        ],
        onChanged: null,
        // Disable until loaded
        validator: validator,
        enabled: false,
      );
    }

    return CustomDropdownField<int>(
      value: value,
      labelText: 'Type Of Delivery',
      menuMaxHeight: 300,
      // Increased height for descriptions
      items: deliveryTypes.map((type) {
        return DropdownMenuItem<int>(
          value: int.parse(type['id']),
          child: showDescription
              ? Container(
                  constraints: const BoxConstraints(minHeight: 70),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type['type_name_en'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (type['description_en'] != null &&
                          type['description_en'].isNotEmpty)
                        Flexible(
                          child: Text(
                            type['description_en'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                )
              : Text(
                  type['type_name_en'] ?? 'Unknown',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
    );
  }
}

// Generic dropdown for any list of items
class GenericDropdown<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final String? hintText;
  final List<T> items;
  final String Function(T) itemLabel;
  final T Function(T) itemValue;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const GenericDropdown({
    super.key,
    this.value,
    required this.labelText,
    this.hintText,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdownField<T>(
      value: value,
      labelText: labelText,
      hintText: hintText,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: itemValue(item),
          child: Text(itemLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
    );
  }
}
