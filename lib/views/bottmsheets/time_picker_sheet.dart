// // widgets/custom_time_picker_sheet.dart
// import 'package:blockatie/provider/time.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class CustomTimePickerSheet extends StatelessWidget {
//   const CustomTimePickerSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final timeProvider = Provider.of<TimeProvider>(context);
//     final hours = List.generate(12, (index) => index + 1); // 1–12
//     final minutes = List.generate(60, (index) => index); // 0–59
//     final periods = ['AM', 'PM'];

//     return Padding(
//       padding: const EdgeInsets.only(top: 12.0, bottom: 20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // drag indicator
//           Container(
//             width: 40,
//             height: 5,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(5),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             "Set Time",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           Container(
//             height: 180,
//             margin: const EdgeInsets.symmetric(horizontal: 20),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.blue),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildPicker<int>(
//                   context,
//                   items: hours,
//                   selectedValue: timeProvider.selectedHour,
//                   onChanged: (index) =>
//                       timeProvider.setHour(hours[index]),
//                 ),
//                 _buildPicker<int>(
//                   context,
//                   items: minutes,
//                   selectedValue: timeProvider.selectedMinute,
//                   onChanged: (index) =>
//                       timeProvider.setMinute(minutes[index]),
//                 ),
//                 _buildPicker<String>(
//                   context,
//                   items: periods,
//                   selectedValue: timeProvider.selectedPeriod,
//                   onChanged: (index) =>
//                       timeProvider.setPeriod(periods[index]),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context, timeProvider.formattedTime);
//                 },
//                 child: const Text(
//                   'Save',
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//               const SizedBox(width: 12),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildPicker<T>(
//     BuildContext context, {
//     required List<T> items,
//     required T selectedValue,
//     required Function(int) onChanged,
//   }) {
//     return Expanded(
//       child: CupertinoPicker(
//         scrollController: FixedExtentScrollController(
//           initialItem: items.indexOf(selectedValue),
//         ),
//         itemExtent: 40,
//         magnification: 1.2,
//         useMagnifier: true,
//         onSelectedItemChanged: onChanged,
//         children: items.map((e) {
//           return Center(
//             child: Text(
//               e.toString().padLeft(2, '0'),
//               style: const TextStyle(fontSize: 18),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// widgets/custom_time_picker_sheet.dart
import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/time.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockatie/utils/localization/translations.dart';

class CustomTimePickerSheet extends StatelessWidget {
  const CustomTimePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);
    final hours = List.generate(12, (index) => index + 1); // 1–12
    final minutes = List.generate(60, (index) => index); // 0–59
    final periods = ['AM', 'PM'];

    return Container(
      padding:
          const EdgeInsets.only(top: 12.0, bottom: 20, left: 15, right: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppTranslations.getText('set_time'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Spacing.x(15),
                    _buildWheel<int>(
                      context,
                      items: hours,
                      selectedItem: timeProvider.selectedHour,
                      onChanged: (val) => timeProvider.setHour(val),
                    ),
                    _buildWheel<int>(
                      context,
                      items: minutes,
                      selectedItem: timeProvider.selectedMinute,
                      onChanged: (val) => timeProvider.setMinute(val),
                    ),
                    _buildWheel<String>(
                      context,
                      items: periods,
                      selectedItem: timeProvider.selectedPeriod,
                      onChanged: (val) => timeProvider.setPeriod(val),
                    ),
                  ],
                ),
                // dividers
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: Divider(color: Colors.grey.shade400),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Divider(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppTranslations.getText('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, timeProvider.formattedTime);
                },
                child: Text(
                  AppTranslations.getText('save'),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel<T>(
    BuildContext context, {
    required List<T> items,
    required T selectedItem,
    required void Function(T) onChanged,
  }) {
    final controller = FixedExtentScrollController(
      initialItem: items.indexOf(selectedItem),
    );

    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 50,
        physics: const FixedExtentScrollPhysics(),
        overAndUnderCenterOpacity: 0.0,
        perspective: 0.0001,
        useMagnifier: false,
        onSelectedItemChanged: (index) {
          onChanged(items[index]);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            final isSelected = items[index] == selectedItem;
            return Center(
              child: Text(
                items[index].toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black54,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
