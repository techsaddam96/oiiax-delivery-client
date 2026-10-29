import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/models/blockatie_pro_package.dart';
import 'package:blockatie/utils/app_images.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageCardWidget extends StatelessWidget {
  final BlockatieProPackage package;
  final VoidCallback? onWhatsAppPressed;

  const PackageCardWidget({
    super.key,
    required this.package,
    this.onWhatsAppPressed,
  });

  @override
  Widget build(BuildContext context) {
    final localizedName = _localizedText(
      primary: AppLocalizations.isRTL ? package.nameAr : package.nameEn,
      fallback: AppLocalizations.isRTL ? package.nameEn : package.nameAr,
      finalFallback: package.name,
    );
    final localizedDescription = _localizedText(
      primary: AppLocalizations.isRTL
          ? package.descriptionAr
          : package.descriptionEn,
      fallback: AppLocalizations.isRTL
          ? package.descriptionEn
          : package.descriptionAr,
      finalFallback: package.description,
    );
    final localizedFeatures = _localizedFeatures(
      primary: AppLocalizations.isRTL ? package.featuresAr : package.featuresEn,
      fallback:
          AppLocalizations.isRTL ? package.featuresEn : package.featuresAr,
      finalFallback: package.features,
    );
    final isActive = package.isActive == 1;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showContactDialog(context, package),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -12,
                end: -28,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    AppImages.tabl,
                    width: 128,
                    height: 128,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _TopChip(
                                icon: Icons.workspace_premium_rounded,
                                label: AppTranslations.getText('blockatie_pro'),
                                background: const Color(0xffEEF5FF),
                                foreground: AppColors.primary,
                              ),
                              _TopChip(
                                icon: isActive
                                    ? Icons.verified_rounded
                                    : Icons.pause_circle_outline_rounded,
                                label: isActive
                                    ? AppTranslations.getText('active')
                                    : AppTranslations.getText('inactive'),
                                background: isActive
                                    ? const Color(0xffE9F7EF)
                                    : const Color(0xffFFF1F2),
                                foreground: isActive
                                    ? const Color(0xff11875D)
                                    : const Color(0xffDC2626),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppTranslations.getText('in_just'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${package.currency} ${package.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizedName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizedDescription,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xff64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: Column(
                        children: localizedFeatures.take(4).map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffE8F1FF),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Color(0xff334155),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onWhatsAppPressed ??
                            () => _showContactDialog(context, package),
                        icon: Image.asset(
                          AppImages.whatsapp,
                          width: 18,
                          height: 18,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 18,
                            );
                          },
                        ),
                        label: Text(
                          AppTranslations.getText('whatsapp'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, BlockatieProPackage package) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Image.asset(
                AppImages.whatsapp,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.support_agent_rounded),
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.getText('contact_support'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppTranslations.getText('get_in_touch_about')} ${_localizedText(primary: AppLocalizations.isRTL ? package.nameAr : package.nameEn, fallback: AppLocalizations.isRTL ? package.nameEn : package.nameAr, finalFallback: package.name)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xff334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${AppTranslations.getText('price')}: ${package.currency} ${package.price.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppTranslations.getText('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openWhatsApp(package.linkContact);
              },
              icon: Image.asset(
                AppImages.whatsapp,
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.open_in_new_rounded, size: 16),
              ),
              label: Text(AppTranslations.getText('open_whatsapp')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openWhatsApp(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _localizedText({
    required String primary,
    required String fallback,
    required String finalFallback,
  }) {
    if (primary.trim().isNotEmpty) {
      return primary.trim();
    }
    if (fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    return finalFallback.trim();
  }

  List<String> _localizedFeatures({
    required List<String> primary,
    required List<String> fallback,
    required List<String> finalFallback,
  }) {
    final values = primary.isNotEmpty
        ? primary
        : fallback.isNotEmpty
            ? fallback
            : finalFallback;
    return values.where((feature) => feature.trim().isNotEmpty).toList();
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
