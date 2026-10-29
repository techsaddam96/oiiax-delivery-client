import 'package:blockatie/provider/orders.dart';
import 'package:blockatie/views/pages/orders/components/dotted_line.dart';
import 'package:blockatie/views/pages/orders/components/status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatusIndicatorRow extends StatelessWidget {
  const StatusIndicatorRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider =
        Provider.of<OrderStatusProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        // height: 80, // Constrain the height
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Placed
                StatusIndicator(
                  icon: 'assets/images/icn_pending.png',
                  label: 'Pending',
                  isActive: orderProvider.isStatusActive(0),
                  isCompleted: orderProvider.isStatusCompleted(0),
                  onTap: () => orderProvider.updateStatusByIndex(0),
                ),
                // const SizedBox(
                //     width:
                //         8), // Add spacing before dotted line
                SizedBox(
                  width: 30, // Give explicit width
                  // height: 2, // Give explicit height
                  child: Align(
                    alignment: Alignment.center,
                    child: DottedLine(
                      isCompleted: orderProvider.currentStatusIndex > 0,
                    ),
                  ),
                ),
                // const SizedBox(
                //     width:
                //         8), // Add spacing after dotted line
                // Accepted
                StatusIndicator(
                  icon: 'assets/images/icn_processing.png',
                  label: 'Processing',
                  isActive: orderProvider.isStatusActive(1),
                  isCompleted: orderProvider.isStatusCompleted(1),
                  onTap: () => orderProvider.updateStatusByIndex(1),
                ),
                // const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 1,
                  ),
                ),
                // const SizedBox(width: 8),
                // In Progress
                StatusIndicator(
                  icon: 'assets/images/icn_dispatched.png',
                  label: 'Dispatched',
                  isActive: orderProvider.isStatusActive(2),
                  isCompleted: orderProvider.isStatusCompleted(2),
                  onTap: () => orderProvider.updateStatusByIndex(2),
                ),
                // const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 2,
                  ),
                ),
                // const SizedBox(width: 8),
                // Delivered
                StatusIndicator(
                  icon: 'assets/images/icn_intransit.png',
                  label: 'In Transit',
                  isActive: orderProvider.isStatusActive(3),
                  isCompleted: orderProvider.isStatusCompleted(3),
                  onTap: () => orderProvider.updateStatusByIndex(3),
                ),
                // const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 3,
                  ),
                ),
                // const SizedBox(width: 8),
                // Out for Delivery
                StatusIndicator(
                  icon: 'assets/images/icn_outfordelivery.png',
                  label: 'Out for Delivery',
                  isActive: orderProvider.isStatusActive(4),
                  isCompleted: orderProvider.isStatusCompleted(4),
                  onTap: () => orderProvider.updateStatusByIndex(4),
                ),
                // const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 4,
                  ),
                ),
                // const SizedBox(width: 8),
                // Delivered
                StatusIndicator(
                  icon: 'assets/images/icn_delivered.png',
                  label: 'Delivered',
                  isActive: orderProvider.isStatusActive(5),
                  isCompleted: orderProvider.isStatusCompleted(5),
                  onTap: () => orderProvider.updateStatusByIndex(5),
                ),
                // const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 5,
                  ),
                ),
                // const SizedBox(width: 8),
                // Cancelled
                StatusIndicator(
                  icon: 'assets/images/icn_cancelled.png',
                  label: 'Cancelled',
                  isActive: orderProvider.isStatusActive(6),
                  isCompleted: orderProvider.isStatusCompleted(6),
                  onTap: () => orderProvider.updateStatusByIndex(6),
                ),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 5,
                  ),
                ),
                StatusIndicator(
                  icon: 'assets/images/icn_returned.png',
                  label: 'Returned',
                  isActive: orderProvider.isStatusActive(7),
                  isCompleted: orderProvider.isStatusCompleted(7),
                  onTap: () => orderProvider.updateStatusByIndex(7),
                ),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 5,
                  ),
                ),
                StatusIndicator(
                  icon: 'assets/images/icn_failed_delivery.png',
                  label: 'Failed Delivery',
                  isActive: orderProvider.isStatusActive(8),
                  isCompleted: orderProvider.isStatusCompleted(8),
                  onTap: () => orderProvider.updateStatusByIndex(8),
                ),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 5,
                  ),
                ),
                StatusIndicator(
                  icon: 'assets/images/icn_awaiting_pickup.png',
                  label: 'Awaiting Pickup',
                  isActive: orderProvider.isStatusActive(9),
                  isCompleted: orderProvider.isStatusCompleted(9),
                  onTap: () => orderProvider.updateStatusByIndex(9),
                ),
                SizedBox(
                  width: 30,
                  // height: 2,
                  child: DottedLine(
                    isCompleted: orderProvider.currentStatusIndex > 5,
                  ),
                ),
                StatusIndicator(
                    icon: 'assets/images/icn_cmplted.png',
                    label: 'Completed',
                    isActive: orderProvider.isStatusActive(10),
                    isCompleted: orderProvider.isStatusCompleted(10),
                    onTap: () {
                      // Nav.to(const LocationOrderPage());
                      orderProvider.updateStatusByIndex(10);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
