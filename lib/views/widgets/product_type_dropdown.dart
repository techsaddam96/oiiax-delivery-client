import 'package:flutter/material.dart';
import 'package:blockatie/constants/colors.dart';

class ProductTypeDropdown extends StatefulWidget {
  final int? value;
  final ValueChanged<int?>? onChanged;
  final String? labelText;
  final String? hintText;

  const ProductTypeDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
  });

  @override
  State<ProductTypeDropdown> createState() => _ProductTypeDropdownState();
}

class _ProductTypeDropdownState extends State<ProductTypeDropdown> {
  final List<Map<String, dynamic>> _productTypes = [
    {
      'id': 1,
      'name_en': 'Non-Fragile',
      'name_ar': 'غير قابل للكسر',
      'description': 'Regular items that are not easily damaged',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'id': 2,
      'name_en': 'Fragile',
      'name_ar': 'قابل للكسر',
      'description': 'Items that require special handling',
      'icon': Icons.warning_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
      child: DropdownButtonFormField<int>(
        value: widget.value,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Product Type',
          hintText: widget.hintText ?? 'Select product type',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(
            Icons.category_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        items: _productTypes.map((type) {
          return DropdownMenuItem<int>(
            value: type['id'],
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
                  Icon(
                    type['icon'],
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      type['name_en'],
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
        validator: (value) {
          if (value == null) {
            return 'Please select a product type';
          }
          return null;
        },
        dropdownColor: Colors.white,
        icon: const SizedBox.shrink(),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        menuMaxHeight: 300,
      ),
    );
  }
}
