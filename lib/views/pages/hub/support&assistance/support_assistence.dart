import 'package:blockatie/constants/colors.dart';
import 'package:blockatie/provider/system_settings_provider.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';
import 'package:blockatie/views/pages/hub/support&assistance/components/personal_info_form.dart';
import 'package:blockatie/views/widgets/cutom-appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportAssistancePage extends StatefulWidget {
  final bool showAppBar;

  const SupportAssistancePage({super.key, this.showAppBar = true});

  @override
  State<SupportAssistancePage> createState() => _SupportAssistancePageState();
}

class _SupportAssistancePageState extends State<SupportAssistancePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formSectionKey = GlobalKey();

  bool get _isArabic => AppLocalizations.isRTL;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsProvider = context.read<SystemSettingsProvider>();
      if (!settingsProvider.hasSettings && !settingsProvider.isLoading) {
        settingsProvider.loadSystemSettings();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _text(String ar, String en) => _isArabic ? ar : en;

  Future<void> _scrollToForm() async {
    final formContext = _formSectionKey.currentContext;
    if (formContext == null) return;
    await Scrollable.ensureVisible(
      formContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _openWhatsApp(SystemSettingsProvider settings) async {
    if (!settings.hasWhatsApp) {
      _showSnack(
        _text('رقم واتساب غير متوفر حالياً',
            'WhatsApp is not available right now'),
        isError: true,
      );
      return;
    }

    final message = _text(
      'مرحباً، أحتاج مساعدة في تطبيق أصحاب المتاجر.',
      'Hello, I need help with the store app.',
    );
    final appUri =
        Uri.parse(settings.getWhatsAppUrlWithFallback(message: message));
    final webUri = Uri.parse(settings.getWhatsAppUrl(message: message));

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (!mounted) return;
      _showSnack(_text('تعذر فتح واتساب', 'Unable to open WhatsApp'),
          isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        _text('حدث خطأ أثناء فتح واتساب',
            'Something went wrong while opening WhatsApp'),
        isError: true,
      );
    }
  }

  Future<void> _openDialer(SystemSettingsProvider settings) async {
    if (!settings.hasPhone) {
      _showSnack(
        _text('رقم الدعم غير متوفر حالياً',
            'Support phone is not available right now'),
        isError: true,
      );
      return;
    }

    final uri = Uri.parse(settings.getPhoneCallUrl());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (!mounted) return;
      _showSnack(_text('تعذر فتح تطبيق الاتصال', 'Unable to open phone dialer'),
          isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        _text('حدث خطأ أثناء فتح الاتصال',
            'Something went wrong while opening the dialer'),
        isError: true,
      );
    }
  }

  Future<void> _openSocialUrl(String url, String label) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.trim().isEmpty) {
      _showSnack(
        _text('$label غير متوفر حالياً', '$label is not available right now'),
        isError: true,
      );
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (!mounted) return;
      _showSnack(_text('تعذر فتح $label', 'Unable to open $label'),
          isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        _text('حدث خطأ أثناء فتح $label',
            'Something went wrong while opening $label'),
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xffDC2626) : const Color(0xff16A06D),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      resizeToAvoidBottomInset: true,
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: _text('الدعم والمساعدة', 'Support & Help'),
              subtitle: _text(
                'نحن هنا لمساعدة متجرك في أي وقت',
                'We are here to help your store anytime',
              ),
              showBtn: false,
              onBack: () => Navigator.of(context).maybePop(),
            )
          : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Consumer<SystemSettingsProvider>(
          builder: (context, settings, _) {
            return Column(
              children: [
                if (widget.showAppBar) const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => settings.refreshSystemSettings(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(
                        18,
                        16,
                        18,
                        // The Scaffold already resizes around the IME.  The
                        // shell hides its floating navigation while typing,
                        // so neither its height nor the keyboard height
                        // belongs in this scroll padding.
                        keyboardVisible ? 24 : bottomSafeArea + 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SupportHero(
                            title: _text('تحتاج مساعدة لمتجرك؟',
                                'Need help with your store?'),
                            subtitle: _text(
                              'أرسل رسالة دعم أو تواصل معنا مباشرة من خيارات الدعم.',
                              'Send a support request or contact us directly from the support options.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: _text('خيارات التواصل', 'Contact Options'),
                            children: [
                              _SupportActionTile(
                                icon: Icons.chat_rounded,
                                label: 'WhatsApp',
                                subtitle: _text(
                                  'تواصل معنا على واتساب',
                                  'Chat with us on WhatsApp',
                                ),
                                color: const Color(0xff16A06D),
                                enabled:
                                    settings.hasWhatsApp && !settings.isLoading,
                                onTap: () => _openWhatsApp(settings),
                              ),
                              const SizedBox(height: 10),
                              _SupportActionTile(
                                icon: Icons.call_rounded,
                                label: _text('اتصل بنا', 'Call us'),
                                subtitle: _text(
                                  'افتح تطبيق الاتصال للتواصل مع الدعم',
                                  'Open the phone dialer to contact support',
                                ),
                                color: AppColors.primary,
                                enabled:
                                    settings.hasPhone && !settings.isLoading,
                                onTap: () => _openDialer(settings),
                              ),
                              const SizedBox(height: 10),
                              _SupportActionTile(
                                icon: Icons.mark_unread_chat_alt_rounded,
                                label: _text(
                                    'أرسل رسالة دعم', 'Send support message'),
                                subtitle: _text(
                                  'اكتب تفاصيل المشكلة وسنقوم بالرد عليك',
                                  'Tell us about the issue and we will get back to you',
                                ),
                                color: const Color(0xff0EA5E9),
                                enabled: true,
                                onTap: _scrollToForm,
                              ),
                            ],
                          ),
                          if (settings.hasFacebook ||
                              settings.hasInstagram ||
                              settings.hasLinkedIn) ...[
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: _text('تابعنا', 'Follow us'),
                              children: [
                                _SocialStrip(
                                  settings: settings,
                                  onOpen: _openSocialUrl,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          ContactFormWidget(
                            key: _formSectionKey,
                            textTheme: Theme.of(context).textTheme,
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: _text('أسئلة سريعة', 'Quick FAQ'),
                            children: [
                              _FaqTile(
                                question: _text(
                                  'كيف أتابع شحناتي؟',
                                  'How do I track my shipments?',
                                ),
                                answer: _text(
                                  'افتح الشحنات واختر الشحنة المطلوبة لعرض التفاصيل والتتبع.',
                                  'Open Shipments and select the shipment to view details and tracking.',
                                ),
                              ),
                              _FaqTile(
                                question: _text(
                                  'كيف أطلب دعم فني؟',
                                  'How do I request technical support?',
                                ),
                                answer: _text(
                                  'استخدم نموذج الرسالة وأدخل بيانات التواصل وتفاصيل المشكلة.',
                                  'Use the message form with your contact information and issue details.',
                                ),
                              ),
                              _FaqTile(
                                question: _text(
                                  'لماذا أحتاج رقم هاتف صحيح؟',
                                  'Why do I need a valid phone number?',
                                ),
                                answer: _text(
                                  'حتى يتمكن فريق الدعم من التواصل معك بسرعة عند الحاجة.',
                                  'So the support team can reach you quickly when needed.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class _SupportHero extends StatelessWidget {
  const _SupportHero({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
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
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffDDEBFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.035),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xffE1E8F2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  const _SupportActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = enabled ? color : const Color(0xff94A3B8);

    return Material(
      color: tileColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tileColor.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: Color(0xff94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialStrip extends StatelessWidget {
  const _SocialStrip({
    required this.settings,
    required this.onOpen,
  });

  final SystemSettingsProvider settings;
  final Future<void> Function(String url, String label) onOpen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (settings.hasFacebook)
          _SocialButton(
            label: 'Facebook',
            asset: 'assets/images/facebook.png',
            onTap: () => onOpen(settings.facebookUrl, 'Facebook'),
          ),
        if (settings.hasInstagram)
          _SocialButton(
            label: 'Instagram',
            asset: 'assets/images/instagram.png',
            onTap: () => onOpen(settings.instagramUrl, 'Instagram'),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.asset,
    required this.onTap,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(asset, width: 22, height: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 10),
        iconColor: AppColors.primary,
        collapsedIconColor: const Color(0xff94A3B8),
        title: Text(
          question,
          style: const TextStyle(
            color: Color(0xff0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
