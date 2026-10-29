import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/client_profile.dart';
import 'package:blockatie/models/statistics.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';

class ClientWelcomeSummaryCard extends StatelessWidget {
  const ClientWelcomeSummaryCard({
    super.key,
    required this.profile,
    required this.stats,
  });

  final ClientInfo? profile;
  final ClientStatisticsData? stats;

  @override
  Widget build(BuildContext context) {
    final displayName = _firstNonEmpty([profile?.nstore, profile?.nclient]) ??
        AppTranslations.getText('store_name_not_available');
    final isActive = (profile?.status ?? 0) == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -38,
            end: -28,
            child: _SoftCircle(size: 126, opacity: 0.12),
          ),
          const PositionedDirectional(
            bottom: -54,
            start: -36,
            child: _SoftCircle(size: 136, opacity: 0.08),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getText('hub_welcome_back'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.getText(
                            'hub_everything_in_one_place',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SummaryStatusBadge(isActive: isActive),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      value: _metricValue(stats?.shipments),
                      label: AppTranslations.getText('shipments'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      value: _metricValue(stats?.shipmentsInProgress),
                      label: AppTranslations.getText('active_orders'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      value: stats?.availableForWithdrawal == null
                          ? '—'
                          : '${stats!.availableForWithdrawal!.toStringAsFixed(2)} JOD',
                      label: AppTranslations.getText('available_to_withdraw'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _metricValue(int? value) => value?.toString() ?? '--';
}

class _SummaryStatusBadge extends StatelessWidget {
  const _SummaryStatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xff16A06D) : const Color(0xffF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            AppTranslations.getText(isActive ? 'active' : 'inactive'),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
