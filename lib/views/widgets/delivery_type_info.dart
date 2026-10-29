import 'package:flutter/material.dart';
import 'package:blockatie/services/delivery_type_service.dart';

class DeliveryTypeInfo extends StatelessWidget {
  final int deliveryTypeId;
  final bool showDescription;
  final bool isDelivered;
  final double iconSize;
  final double fontSize;

  const DeliveryTypeInfo({
    super.key,
    required this.deliveryTypeId,
    this.showDescription = false,
    this.isDelivered = false,
    this.iconSize = 10,
    this.fontSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    final typeName = DeliveryTypeService.getDeliveryTypeName(deliveryTypeId);
    final description =
        DeliveryTypeService.getDeliveryTypeDescription(deliveryTypeId);
    final iconPath = DeliveryTypeService.getDeliveryTypeIcon(deliveryTypeId);
    final colorName = DeliveryTypeService.getDeliveryTypeColor(deliveryTypeId);

    Color color;
    switch (colorName) {
      case 'primary':
        color = Colors.blue;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      case 'grey':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDelivered ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            color: isDelivered ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeName,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isDelivered ? Colors.white : color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showDescription && description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color:
                        isDelivered ? Colors.white70 : color.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryTypeChip extends StatelessWidget {
  final int deliveryTypeId;
  final bool isDelivered;
  final VoidCallback? onTap;

  const DeliveryTypeChip({
    super.key,
    required this.deliveryTypeId,
    this.isDelivered = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeName = DeliveryTypeService.getDeliveryTypeName(deliveryTypeId);
    final colorName = DeliveryTypeService.getDeliveryTypeColor(deliveryTypeId);

    Color color;
    switch (colorName) {
      case 'primary':
        color = Colors.blue;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      case 'grey':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDelivered
              ? Colors.grey.withOpacity(0.2)
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDelivered ? Colors.grey : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          typeName,
          style: TextStyle(
            fontSize: 10,
            color: isDelivered ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
