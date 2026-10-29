import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/shipment.dart';
import 'package:blockatie/utils/client_shipment_cancellation_eligibility.dart';
import 'package:blockatie/utils/instant_shipment_progress.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class OrderInstantTile extends StatelessWidget {
  const OrderInstantTile({
    super.key,
    required this.shipment,
    required this.typeLabel,
    required this.statusLabel,
    required this.stageLabel,
    required this.createdLabel,
    required this.canCancel,
    required this.isBusy,
    required this.onViewDetails,
    this.onTrackShipment,
    this.onCancelShipment,
    this.onCallReceiver,
    this.onOpenMap,
    this.driverRatingSection,
  });

  final Shipment shipment;
  final String typeLabel;
  final String statusLabel;
  final String stageLabel;
  final String createdLabel;
  final bool canCancel;
  final bool isBusy;
  final VoidCallback onViewDetails;
  final VoidCallback? onTrackShipment;
  final VoidCallback? onCancelShipment;
  final VoidCallback? onCallReceiver;
  final VoidCallback? onOpenMap;
  final Widget? driverRatingSection;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final useInstantFlow =
        InstantShipmentProgressHelper.isInstantShipment(shipment);
    final currentStage = InstantShipmentProgressHelper.currentStage(shipment);
    final waitingForDriver =
        InstantShipmentProgressHelper.isWaitingForDriver(shipment);
    final hasDriver = InstantShipmentProgressHelper.hasAssignedDriver(shipment);
    final statusColor =
        useInstantFlow ? currentStage.color : _statusColor(shipment);
    final stageText = useInstantFlow ? currentStage.title(isRtl) : stageLabel;
    final afterStorePickup = useInstantFlow &&
        const {'picked_up', 'out_for_delivery', 'delivered', 'completed'}
            .contains(currentStage.key);
    final trackAction = afterStorePickup ? null : onTrackShipment;
    final canShowCancel = canCancel &&
        ClientShipmentCancellationEligibility.isListEligible(shipment) &&
        onCancelShipment != null &&
        !InstantShipmentProgressHelper.isFinalStatus(shipment);

    return _CompactShipmentShell(
      accentColor: statusColor,
      waitingForDriver: waitingForDriver,
      onTap: isBusy ? null : onViewDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShipmentTopLine(
            policyNumber: _safeValue(
              shipment.policyNum,
              fallback: _copy(isRtl, 'Shipment', '\u0634\u062D\u0646\u0629'),
            ),
            typeLabel: _safeValue(
              typeLabel,
              fallback: _copy(isRtl, 'Instant', '\u0641\u0648\u0631\u064A'),
            ),
            statusLabel: waitingForDriver
                ? _copy(isRtl, 'Waiting',
                    '\u0628\u0627\u0646\u062A\u0638\u0627\u0631')
                : _safeValue(
                    useInstantFlow ? currentStage.title(isRtl) : statusLabel,
                    fallback: _copy(
                      isRtl,
                      'In progress',
                      '\u0642\u064A\u062F \u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629',
                    ),
                  ),
            statusColor: statusColor,
          ),
          const SizedBox(height: 12),
          _ShipmentRouteSummary(
            destination: _shortAddress(
              shipment.deliveryAddress,
              fallback: _copy(
                isRtl,
                'Destination will appear in details',
                '\u062A\u0638\u0647\u0631 \u0627\u0644\u0648\u062C\u0647\u0629 \u0641\u064A \u0627\u0644\u062A\u0641\u0627\u0635\u064A\u0644',
              ),
            ),
            createdLabel: createdLabel,
          ),
          const SizedBox(height: 12),
          if (useInstantFlow && !waitingForDriver) ...[
            _InstantStageStrip(stage: currentStage),
            const SizedBox(height: 12),
          ],
          if (waitingForDriver)
            _WaitingDriverStrip(stage: currentStage)
          else
            _DriverMiniStrip(
              hasDriver: hasDriver,
              driverName: shipment.driverName,
            ),
          const SizedBox(height: 12),
          _ShipmentMetaRow(
            stageText: stageText,
            statusColor: statusColor,
            isFinal: InstantShipmentProgressHelper.isFinalStatus(shipment),
          ),
          if (driverRatingSection != null) ...[
            const SizedBox(height: 12),
            driverRatingSection!,
          ],
          const SizedBox(height: 14),
          _ShipmentActions(
            isBusy: isBusy,
            showCancel: canShowCancel,
            onDetails: onViewDetails,
            onTrack: trackAction,
            onCancel: onCancelShipment,
          ),
        ],
      ),
    );
  }

  static String _safeValue(String? value, {required String fallback}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _shortAddress(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return fallback;
    if (text.length <= 58) return text;
    return '${text.substring(0, 58).trim()}...';
  }

  static String _copy(bool isRtl, String en, String ar) => isRtl ? ar : en;

  static Color _statusColor(Shipment shipment) {
    final statusId = InstantShipmentProgressHelper.effectiveStatusId(shipment);
    if (statusId == 6 || statusId == 11) return const Color(0xff0F766E);
    if (statusId == 7 || statusId == 8 || statusId == 9) {
      return const Color(0xffDC2626);
    }
    if (statusId == 3 || statusId == 4 || statusId == 5) {
      return AppColors.primary;
    }
    return const Color(0xffF59E0B);
  }
}

class _CompactShipmentShell extends StatelessWidget {
  const _CompactShipmentShell({
    required this.accentColor,
    required this.waitingForDriver,
    required this.child,
    required this.onTap,
  });

  final Color accentColor;
  final bool waitingForDriver;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: waitingForDriver
                  ? const Color(0xffFED7AA)
                  : const Color(0xffDCE8F6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(24),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShipmentTopLine extends StatelessWidget {
  const _ShipmentTopLine({
    required this.policyNumber,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
  });

  final String policyNumber;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policyNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _SoftChip(
                    label: typeLabel,
                    icon: Icons.bolt_rounded,
                    color: AppColors.primary,
                  ),
                  _SoftChip(
                    label: statusLabel,
                    icon: Icons.radio_button_checked_rounded,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShipmentRouteSummary extends StatelessWidget {
  const _ShipmentRouteSummary({
    required this.destination,
    required this.createdLabel,
  });

  final String destination;
  final String createdLabel;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineInfo(
            icon: Icons.flag_rounded,
            label:
                isRtl ? '\u0627\u0644\u0648\u062C\u0647\u0629' : 'Destination',
            value: destination,
            color: const Color(0xff16A06D),
          ),
          const SizedBox(height: 9),
          _InlineInfo(
            icon: Icons.schedule_rounded,
            label: isRtl ? '\u0627\u0644\u0648\u0642\u062A' : 'Time',
            value: createdLabel,
            color: const Color(0xff64748B),
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstantStageStrip extends StatelessWidget {
  const _InstantStageStrip({required this.stage});

  final InstantShipmentStage stage;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final isWaiting = stage.key == 'waiting_driver';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: isWaiting ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stage.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stage.icon, color: stage.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title(isRtl),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: stage.color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.message(isRtl),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontSize: 11.4,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingDriverStrip extends StatefulWidget {
  const _WaitingDriverStrip({required this.stage});

  final InstantShipmentStage stage;

  @override
  State<_WaitingDriverStrip> createState() => _WaitingDriverStripState();
}

class _WaitingDriverStripState extends State<_WaitingDriverStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final stage = widget.stage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: stage.color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xffF97316).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffF97316)
                          .withValues(alpha: 0.22 * _pulse.value),
                      blurRadius: 14 * _pulse.value,
                      spreadRadius: 2 * _pulse.value,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Icon(
              Icons.radar_rounded,
              color: stage.color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title(isRtl),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: stage.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.message(isRtl),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffB45309),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverMiniStrip extends StatelessWidget {
  const _DriverMiniStrip({
    required this.hasDriver,
    required this.driverName,
  });

  final bool hasDriver;
  final String? driverName;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    final title = hasDriver
        ? (isRtl
            ? '\u062A\u0645 \u062A\u0639\u064A\u064A\u0646 \u0627\u0644\u0633\u0627\u0626\u0642'
            : 'Driver assigned')
        : (isRtl
            ? '\u0627\u0644\u0633\u0627\u0626\u0642 \u063A\u064A\u0631 \u0645\u062D\u062F\u062F'
            : 'Driver not assigned');
    final subtitle = hasDriver && (driverName?.trim().isNotEmpty ?? false)
        ? driverName!.trim()
        : (isRtl
            ? '\u062A\u0627\u0628\u0639 \u0627\u0644\u062A\u0641\u0627\u0635\u064A\u0644 \u0644\u0645\u0639\u0631\u0641\u0629 \u0622\u062E\u0631 \u062A\u062D\u062F\u064A\u062B'
            : 'Open details for the latest update');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xff059669),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff065F46),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff047857),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentMetaRow extends StatelessWidget {
  const _ShipmentMetaRow({
    required this.stageText,
    required this.statusColor,
    required this.isFinal,
  });

  final String stageText;
  final Color statusColor;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Row(
      children: [
        Expanded(
          child: _SoftChip(
            label: stageText,
            icon: Icons.timeline_rounded,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        _SoftChip(
          label: isFinal
              ? (isRtl ? '\u0646\u0647\u0627\u0626\u064A\u0629' : 'Final')
              : (isRtl ? '\u0646\u0634\u0637\u0629' : 'Active'),
          icon: isFinal ? Icons.lock_rounded : Icons.autorenew_rounded,
          color: isFinal ? const Color(0xff64748B) : const Color(0xff16A06D),
        ),
      ],
    );
  }
}

class _ShipmentActions extends StatelessWidget {
  const _ShipmentActions({
    required this.isBusy,
    required this.showCancel,
    required this.onDetails,
    required this.onTrack,
    required this.onCancel,
  });

  final bool isBusy;
  final bool showCancel;
  final VoidCallback onDetails;
  final VoidCallback? onTrack;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.isRTL;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onDetails,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(
                isRtl
                    ? '\u0627\u0644\u062A\u0641\u0627\u0635\u064A\u0644'
                    : 'Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
        if (onTrack != null) ...[
          const SizedBox(width: 8),
          _IconAction(
            tooltip: isRtl ? '\u062A\u062A\u0628\u0639' : 'Track',
            icon: Icons.near_me_outlined,
            onTap: isBusy ? null : onTrack,
          ),
        ],
        if (showCancel) ...[
          const SizedBox(width: 8),
          _IconAction(
            tooltip: isRtl ? '\u0625\u0644\u063A\u0627\u0621' : 'Cancel',
            icon: Icons.close_rounded,
            danger: true,
            onTap: isBusy ? null : onCancel,
          ),
        ],
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xffDC2626) : AppColors.primary;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: color,
            side: BorderSide(
              color: danger ? const Color(0xffFCA5A5) : const Color(0xffBFDBFE),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Icon(icon, size: 19),
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
