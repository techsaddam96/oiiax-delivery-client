// import 'package:blockatie/provider/filter.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class CalendarBottomSheet extends StatelessWidget {
//   final DateTime focusedDate;

//   const CalendarBottomSheet({super.key, required this.focusedDate});

//   List<DateTime> _getDaysInMonth() {
//     final days = <DateTime>[];
//     final firstDay = DateTime(focusedDate.year, focusedDate.month, 28);
//     for (int i = 0; i < 42; i++) {
//       // 6 weeks x 7 days
//       days.add(firstDay.add(Duration(days: i)));
//     }
//     return days;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateNotifier = Provider.of<FilterProvider>(context, listen: false);

//     final days = _getDaysInMonth();

//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Month ${focusedDate.year}',
//             style: const TextStyle(fontSize: 18),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
//                 .map((day) => Expanded(
//                       child: Text(
//                         day,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ))
//                 .toList(),
//           ),
//           const SizedBox(height: 8),
//           GridView.count(
//             crossAxisCount: 7,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             children: days.map((date) {
//               final isSelected = date.day == dateNotifier.selectedDate.day &&
//                   date.month == dateNotifier.selectedDate.month &&
//                   date.year == dateNotifier.selectedDate.year;
//               final isCurrentMonth = date.month == focusedDate.month;
//               return GestureDetector(
//                 onTap: () {
//                   dateNotifier.updateDate(date);
//                   Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.all(4.0),
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? Colors.blue
//                         : (isCurrentMonth
//                             ? null
//                             : Colors.grey.withOpacity(0.3)),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       date.day.toString(),
//                       style: TextStyle(
//                         color: isSelected
//                             ? Colors.white
//                             : (isCurrentMonth ? Colors.black : Colors.grey),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/filter.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Replace with your AppColors class

class CalendarSheet extends StatelessWidget {
  const CalendarSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const _CalendarBottomContent();
      },
    );
    final filterProvider = context.read<FilterProvider>();
    filterProvider.dateController.text = filterProvider.formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    // Not used directly; use `CalendarSheet.show(context);`
    return const SizedBox.shrink();
  }
}

class _CalendarBottomContent extends StatelessWidget {
  const _CalendarBottomContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CalendarWidget(),
            // const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppTranslations.getText("cancel"),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Optionally handle selected date
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppTranslations.getText("ok"),
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildHeader(provider),
              // const Divider(color: Colors.grey, thickness: 0.5),
              // const SizedBox(height: 20),
              _buildWeekDaysHeader(),
              const SizedBox(height: 10),
              ..._buildCalendarGrid(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(FilterProvider provider) {
    return Row(
      children: [
        Text(
          '${provider.getMonthName(provider.selectedDate.month)} ${provider.selectedDate.year}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.primary),
          onPressed: provider.previousMonth,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: AppColors.primary),
          onPressed: provider.nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (day) => Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildCalendarGrid(FilterProvider provider) {
    List<List<int?>> weeks = provider.getCalendarDays();

    return weeks
        .map(
          (week) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  week.map((day) => _buildDayCell(day, provider)).toList(),
            ),
          ),
        )
        .toList();
  }

  Widget _buildDayCell(int? day, FilterProvider provider) {
    if (day == null) {
      return const SizedBox(width: 32, height: 32);
    }

    bool isSelected = day == provider.selectedDate.day;

    return GestureDetector(
      onTap: () => provider.selectDate(day),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
