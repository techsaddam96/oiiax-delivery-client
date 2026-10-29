import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/blockatie_pro_provider.dart';
import 'package:blockatie/utils/app_utils.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:blockatie/views/pages/blockatie_pro/components/package_card_widget.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BlockatieProPage extends StatefulWidget {
  const BlockatieProPage({super.key});

  @override
  State<BlockatieProPage> createState() => _BlockatieProPageState();
}

class _BlockatieProPageState extends State<BlockatieProPage> {
  late final BlockatieProProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = BlockatieProProvider();
    _provider.fetchPackages();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xffF6F8FC),
        appBar: CustomAppBar(
          title: AppTranslations.getText('blockatie_pro'),
          subtitle: _copy(
            'Professional upgrade plans for your store operations',
            'باقات احترافية لمتجرك والتوصيل المباشر',
          ),
          onHelp: () => _showHelpDialog(context),
        ),
        body: Consumer<BlockatieProProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _packageList(
                context: context,
                children: const [
                  _ProIntroCard(),
                  SizedBox(height: 16),
                  _PackageSkeletonCard(),
                  SizedBox(height: 12),
                  _PackageSkeletonCard(),
                ],
              );
            }

            if (provider.error != null) {
              return _packageList(
                context: context,
                onRefresh: provider.fetchPackages,
                children: [
                  const _ProIntroCard(),
                  const SizedBox(height: 16),
                  _PageMessageCard(
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xffDC2626),
                    borderColor: const Color(0xffF1D4D4),
                    title: AppTranslations.getText('error_loading_packages'),
                    message: provider.error!,
                    actionLabel: AppTranslations.getText('retry'),
                    onAction: provider.fetchPackages,
                  ),
                ],
              );
            }

            if (provider.packages.isEmpty) {
              return _packageList(
                context: context,
                onRefresh: provider.fetchPackages,
                children: [
                  const _ProIntroCard(),
                  const SizedBox(height: 16),
                  _PageMessageCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xff94A3B8),
                    borderColor: const Color(0xffE2E8F0),
                    title: AppTranslations.getText('no_packages_available'),
                    message:
                        AppTranslations.getText('check_back_later_packages'),
                  ),
                ],
              );
            }

            return _packageList(
              context: context,
              onRefresh: provider.fetchPackages,
              children: [
                const _ProIntroCard(),
                const SizedBox(height: 16),
                ...provider.packages.map(
                  (package) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PackageCardWidget(
                      package: package,
                      onWhatsAppPressed: () =>
                          _openWhatsApp(package.linkContact),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _packageList({
    required BuildContext context,
    required List<Widget> children,
    Future<void> Function()? onRefresh,
  }) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        128 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: children,
    );

    if (onRefresh == null) {
      return list;
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: list,
    );
  }

  Future<void> _openWhatsApp(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        AppUtils.showErrorDialog(
          AppTranslations.getText('could_not_open_whatsapp'),
        );
      }
    } catch (_) {
      if (mounted) {
        AppUtils.showErrorDialog(
          AppTranslations.getText('could_not_open_whatsapp'),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.getText('help'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xff0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            AppTranslations.getText('blockatie_pro_help_content'),
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppTranslations.getText('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openWhatsApp(
                  'https://api.whatsapp.com/send?phone=0779063650&text=${Uri.encodeComponent(AppTranslations.getText('whatsapp_message'))}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppTranslations.getText('contact_support')),
            ),
          ],
        );
      },
    );
  }

  String _copy(String en, String ar) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }
}

class _ProIntroCard extends StatelessWidget {
  const _ProIntroCard();

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'باقات OIIAX برو' : 'OIIAX Pro Packages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'اختر الباقة الأنسب لتوسيع خدمات متجرك والتوصيل بسهولة.'
                      : 'Choose the right plan to grow your store and delivery operations.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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

class _PageMessageCard extends StatelessWidget {
  const _PageMessageCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackageSkeletonCard extends StatelessWidget {
  const _PackageSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
    );
  }
}
