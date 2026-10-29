import 'package:flutter/material.dart';
import 'package:blockatie/constants/colors.dart';
import 'dart:math' as math;

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.hasNextPage = true,
    this.hasPreviousPage = true,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show pagination if there are no pages or only one page
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _buildNavigationButton(
                icon: Icons.chevron_left,
                isEnabled: hasPreviousPage,
                onTap: hasPreviousPage
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 6),

              // Page numbers
              ..._buildPageNumbers(),

              const SizedBox(width: 6),

              // Next button
              _buildNavigationButton(
                icon: Icons.chevron_right,
                isEnabled: hasNextPage,
                onTap:
                    hasNextPage ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
          size: 16,
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageNumbers = [];

    // Handle edge cases
    if (totalPages <= 0) return pageNumbers;
    if (totalPages == 1) return pageNumbers;

    if (totalPages <= 7) {
      // Show all pages if total is 7 or less
      for (int i = 1; i <= totalPages; i++) {
        pageNumbers.add(_buildPageNumber(i));
        if (i < totalPages) pageNumbers.add(const SizedBox(width: 4));
      }
    } else {
      // Show first page
      pageNumbers.add(_buildPageNumber(1));
      pageNumbers.add(const SizedBox(width: 4));

      if (currentPage <= 3) {
        // Show pages 2, 3, 4, 5 (but not more than totalPages)
        for (int i = 2; i <= math.min(5, totalPages - 1); i++) {
          pageNumbers.add(_buildPageNumber(i));
          pageNumbers.add(const SizedBox(width: 4));
        }
        if (totalPages > 6) {
          pageNumbers.add(_buildEllipsis());
          pageNumbers.add(const SizedBox(width: 4));
        }
        pageNumbers.add(_buildPageNumber(totalPages));
      } else if (currentPage >= totalPages - 2) {
        // Show pages near the end
        pageNumbers.add(_buildPageNumber(1));
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        for (int i = math.max(2, totalPages - 4); i <= totalPages; i++) {
          pageNumbers.add(_buildPageNumber(i));
          if (i < totalPages) pageNumbers.add(const SizedBox(width: 4));
        }
      } else {
        // Show pages around current page
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageNumbers.add(_buildPageNumber(i));
          pageNumbers.add(const SizedBox(width: 4));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 4));
        pageNumbers.add(_buildPageNumber(totalPages));
      }
    }

    return pageNumbers;
  }

  Widget _buildPageNumber(int pageNumber) {
    final isCurrentPage = pageNumber == currentPage;

    return GestureDetector(
      onTap: () => onPageChanged(pageNumber),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrentPage ? AppColors.primary : Colors.grey.shade300,
            width: isCurrentPage ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isCurrentPage ? AppColors.primary : Colors.black,
              fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
