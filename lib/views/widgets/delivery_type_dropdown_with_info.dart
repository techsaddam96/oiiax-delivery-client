import 'package:flutter/material.dart';
import 'package:blockatie/services/delivery_type_service.dart';
import 'package:blockatie/views/widgets/custom_dropdown_field.dart';

class DeliveryTypeDropdownWithInfo extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const DeliveryTypeDropdownWithInfo({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeliveryTypeDropdown(
          value: value,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          showDescription: false, // Compact version
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DeliveryTypeService.getDeliveryTypeDescription(value!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DeliveryTypeDropdownCompact extends StatelessWidget {
  final int? value;
  final void Function(int?)? onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const DeliveryTypeDropdownCompact({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DeliveryTypeDropdown(
      value: value,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      showDescription: false,
    );
  }
}
