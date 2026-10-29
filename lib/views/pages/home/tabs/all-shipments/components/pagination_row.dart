import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/shipment.dart';
import 'package:flutter/material.dart';

Widget buildPagination(ShipmentProvider provider) {
  final current = provider.currentPage;
  final total = provider.totalPages;

  // Don't show pagination if there are no pages or only one page
  if (total <= 1) {
    return const SizedBox.shrink();
  }

  List<Widget> pageButtons = [];

  // ← Prev (Left Arrow)
  pageButtons.add(
    navArrow(
      icon: Icons.chevron_left,
      enabled: current > 1,
      onTap: () => provider.goToPrevPage(),
    ),
  );

  // Always show first page
  pageButtons.add(pageBtn(provider, 1));

  // Show second page if total > 1
  if (total > 1) {
    pageButtons.add(pageBtn(provider, 2));
  }

  // Show ellipsis if there are pages between 2 and the last two pages
  if (total > 4) {
    pageButtons.add(ellipsis());
  }

  // Show second-to-last page if total > 3
  if (total > 3) {
    pageButtons.add(pageBtn(provider, total - 1));
  }

  // Show last page if total > 2
  if (total > 2) {
    pageButtons.add(pageBtn(provider, total));
  }

  // → Next (Right Arrow)
  pageButtons.add(
    navArrow(
      icon: Icons.chevron_right,
      enabled: current < total,
      onTap: () => provider.goToNextPage(),
    ),
  );

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageButtons,
    ),
  );
}

Widget pageBtn(ShipmentProvider provider, int pageNum) {
  // Validate page number
  if (pageNum < 1 || pageNum > provider.totalPages) {
    return const SizedBox.shrink();
  }

  bool isSelected = provider.currentPage == pageNum;
  return GestureDetector(
    onTap: () => provider.setPage(pageNum),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(1), // Padding for gradient border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.gradient1,
                  AppColors.gradient2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: !isSelected
            ? Border.all(color: Colors.grey.shade300, width: 1)
            : null,
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$pageNum',
            style: TextStyle(
              color: isSelected ? Colors.blue.shade600 : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget navArrow({
  required IconData icon,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade200,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    ),
  );
}

Widget ellipsis() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: Text(
        "...",
        style: TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

// Widget buildPagination(ShipmentProvider provider) {
//   final current = provider.currentPage;
//   final total = provider.totalPages;
//   const maxVisibleButtons = 5; // Total buttons including arrows and ellipsis

//   List<Widget> pageButtons = [];

//   // ← Prev
//   pageButtons.add(
//     navArrow(
//       icon: Icons.chevron_left,
//       enabled: current > 1,
//       onTap: () => provider.goToPrevPage(),
//     ),
//   );

//   // Calculate the range of visible pages
//   int start = (current - 2).clamp(1, total - 4); // Start 2 pages before current
//   int end = (start + 1).clamp(1, total); // Show 4 pages after start

//   // Always show first page if within range
//   if (start > 1) {
//     pageButtons.add(pageBtn(provider, 1));
//     if (start > 2) pageButtons.add(ellipsis());
//   }

//   // Add visible page buttons
//   for (int i = start; i <= end; i++) {
//     pageButtons.add(pageBtn(provider, i));
//   }

//   // Show ellipsis and last page if needed
//   if (end < total - 1) {
//     pageButtons.add(ellipsis());
//     if (total > 1) pageButtons.add(pageBtn(provider, total));
//   }

//   // → Next
//   pageButtons.add(
//     navArrow(
//       icon: Icons.chevron_right,
//       enabled: current < total,
//       onTap: () => provider.goToNextPage(),
//     ),
//   );

//   return SingleChildScrollView(
//     scrollDirection: Axis.horizontal,
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: pageButtons,
//     ),
//   );
// }

// Widget pageBtn(ShipmentProvider provider, int pageNum) {
//   bool isSelected = provider.currentPage == pageNum;
//   return GestureDetector(
//     onTap: () => provider.setPage(pageNum),
//     child: Container(
//       margin: const EdgeInsets.symmetric(horizontal: 0),
//       padding: const EdgeInsets.all(1),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(7),
//         gradient: isSelected
//             ? LinearGradient(
//                 colors: [AppColors.gradient2, AppColors.gradient1],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               )
//             : null,
//       ),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.transparent : Colors.grey.shade300,
//           ),
//           borderRadius: BorderRadius.circular(6),
//           boxShadow: isSelected
//               ? [BoxShadow(color: Colors.blue.shade100, blurRadius: 4)]
//               : [],
//           color: isSelected ? Colors.white : Colors.grey.shade100,
//         ),
//         child: Text(
//           '$pageNum',
//           style: TextStyle(
//             color: isSelected ? Colors.blue : Colors.black87,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     ),
//   );
// }

// Widget navArrow(
//     {required IconData icon,
//     required bool enabled,
//     required VoidCallback onTap}) {
//   return GestureDetector(
//     onTap: enabled ? onTap : null,
//     child: Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: enabled ? Colors.white : Colors.grey.withOpacity(0.3),
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Icon(
//         icon,
//         size: 20,
//         color: enabled ? Colors.black87 : Colors.grey,
//       ),
//     ),
//   );
// }

// Widget ellipsis() {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 4),
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//     decoration: BoxDecoration(
//       border: Border.all(color: Colors.grey.shade300),
//       borderRadius: BorderRadius.circular(6),
//       color: Colors.grey.shade100,
//     ),
//     child: const Text(
//       "...",
//       style: TextStyle(fontSize: 16, color: Colors.black54),
//     ),
//   );
// }
