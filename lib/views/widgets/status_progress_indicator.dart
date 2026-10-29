import 'package:flutter/material.dart';
import 'package:blockatie/services/status_service.dart';

class StatusProgressIndicator extends StatelessWidget {
  final String currentStatus;
  final double height;
  final double borderRadius;

  const StatusProgressIndicator({
    super.key,
    required this.currentStatus,
    this.height = 4.0,
    this.borderRadius = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = StatusService.getStatusProgress(currentStatus);
    final statusColor = StatusService.getStatusColor(currentStatus);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class StatusTimelineIndicator extends StatelessWidget {
  final String currentStatus;
  final List<String> allStatuses;

  const StatusTimelineIndicator({
    super.key,
    required this.currentStatus,
    required this.allStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allStatuses.length,
        itemBuilder: (context, index) {
          final status = allStatuses[index];
          final isCurrentStatus = status == currentStatus;
          final isCompleted = StatusService.getStatusOrder(status) <=
              StatusService.getStatusOrder(currentStatus);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCurrentStatus
                        ? StatusService.getStatusColor(status)
                        : isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Image.asset(
                      StatusService.getStatusIcon(status),
                      width: 15,
                      height: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 8,
                    color: isCurrentStatus
                        ? StatusService.getStatusColor(status)
                        : Colors.grey.shade600,
                    fontWeight:
                        isCurrentStatus ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String status;
  final String? message;
  final bool showProgress;

  const StatusCard({
    super.key,
    required this.status,
    this.message,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusService.getStatusColor(status);
    final statusMessage = message ?? StatusService.getStatusMessage(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    StatusService.getStatusIcon(status),
                    width: 20,
                    height: 20,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (statusMessage.isNotEmpty)
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            StatusProgressIndicator(
              currentStatus: status,
              height: 6,
              borderRadius: 3,
            ),
          ],
        ],
      ),
    );
  }
}
