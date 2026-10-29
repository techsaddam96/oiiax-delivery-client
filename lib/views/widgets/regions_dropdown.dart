import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/services/regions_service.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class RegionsDropdown extends StatefulWidget {
  final int? value;
  final ValueChanged<int?>? onChanged;
  final String? labelText;
  final String? hintText;

  const RegionsDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
  });

  @override
  State<RegionsDropdown> createState() => _RegionsDropdownState();
}

class _RegionsDropdownState extends State<RegionsDropdown> {
  bool _isLoading = false;
  List<Region> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    if (RegionsService.isLoaded) {
      setState(() {
        _regions = RegionsService.regions;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RegionsService.loadRegions();
      setState(() {
        _regions = RegionsService.regions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading regions: $e');
    }
  }

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
          labelText: widget.labelText ?? 'Select Region',
          hintText: widget.hintText ?? 'Choose a region',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: _isLoading
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
        items: [
          // Add a placeholder item for hint text
          DropdownMenuItem<int>(
            value: null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.hintText ?? 'Choose a region',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add the actual region items
          ..._regions.map((region) {
            return DropdownMenuItem<int>(
              value: region.id,
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
                            ? region.anregion
                            : region.enregion,
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
        ],
        validator: (value) {
          if (value == null) {
            return 'Please select a region';
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
