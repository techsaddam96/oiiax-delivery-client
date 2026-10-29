import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/localization/translations.dart';
import 'package:flutter/material.dart';

class ControllableToggleBtn extends StatefulWidget {
  final Function(int) onTabChanged;
  final int initialIndex;
  static _ControllableToggleBtnState? _instance;

  const ControllableToggleBtn({
    super.key,
    required this.onTabChanged,
    this.initialIndex = 1,
  });

  static void switchToTab(int index) {
    _instance?.switchToTab(index);
  }

  @override
  State<ControllableToggleBtn> createState() => _ControllableToggleBtnState();
}

class _ControllableToggleBtnState extends State<ControllableToggleBtn>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    ControllableToggleBtn._instance = this;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      widget.onTabChanged(_tabController.index);
      setState(() {});
    });
  }

  void switchToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SizeConfig.widthMultiplier * 54,
      height: SizeConfig.heightMultiplier * 4.5,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: _tabController.index == 0
                  ? const Radius.circular(5)
                  : Radius.zero,
              right: _tabController.index == 1
                  ? const Radius.circular(5)
                  : Radius.zero,
            ),
          ),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelPadding: EdgeInsets.zero,
        tabs: [
          _buildTab(
              'assets/images/icn_support.png',
              AppTranslations.getText('support'),
              _tabController.index == 0,
              'support_tab'),
          _buildTab(
              'assets/images/client.png',
              AppTranslations.getText('client'),
              _tabController.index == 1,
              'client_tab'),
        ],
      ),
    );
  }

  Widget _buildTab(
      dynamic icon, String text, bool isSelected, String? semanticLabel) {
    final textTheme = Theme.of(context).textTheme;

    Widget iconWidget;

    if (icon is IconData) {
      iconWidget = Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.black : Colors.white,
      );
    } else if (icon is String) {
      iconWidget = Image.asset(
        icon,
        width: 18,
        height: 18,
        color: isSelected ? Colors.black : Colors.white,
      );
    } else {
      iconWidget = const SizedBox(); // fallback
    }

    return Tab(
      child: Semantics(
        label: semanticLabel ?? text,
        button: true,
        child: SizedBox(
          width: 100, // Each tab gets half of 200
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
