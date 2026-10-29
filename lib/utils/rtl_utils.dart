import 'package:flutter/material.dart';
import 'package:blockatie/utils/localization/app_localizations.dart';

/// Utility class for RTL-aware UI components and layouts
class RTLUtils {
  /// Get the appropriate alignment for start position (left in LTR, right in RTL)
  static Alignment get startAlignment =>
      AppLocalizations.isRTL ? Alignment.centerRight : Alignment.centerLeft;

  /// Get the appropriate alignment for end position (right in LTR, left in RTL)
  static Alignment get endAlignment =>
      AppLocalizations.isRTL ? Alignment.centerLeft : Alignment.centerRight;

  /// Get the appropriate cross axis alignment for start
  static CrossAxisAlignment get startCrossAxisAlignment =>
      AppLocalizations.isRTL
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start;

  /// Get the appropriate cross axis alignment for end
  static CrossAxisAlignment get endCrossAxisAlignment => AppLocalizations.isRTL
      ? CrossAxisAlignment.start
      : CrossAxisAlignment.end;

  /// Get the appropriate main axis alignment for start
  static MainAxisAlignment get startMainAxisAlignment =>
      AppLocalizations.isRTL ? MainAxisAlignment.end : MainAxisAlignment.start;

  /// Get the appropriate main axis alignment for end
  static MainAxisAlignment get endMainAxisAlignment =>
      AppLocalizations.isRTL ? MainAxisAlignment.start : MainAxisAlignment.end;

  /// Get the appropriate text alignment
  static TextAlign get startTextAlign =>
      AppLocalizations.isRTL ? TextAlign.right : TextAlign.left;

  /// Get the appropriate text alignment for end
  static TextAlign get endTextAlign =>
      AppLocalizations.isRTL ? TextAlign.left : TextAlign.right;

  /// Get the appropriate text alignment for center
  static TextAlign get centerTextAlign => TextAlign.center;

  /// Get the appropriate border radius for RTL
  static BorderRadius get startBorderRadius => AppLocalizations.isRTL
      ? const BorderRadius.only(
          topRight: Radius.circular(8), bottomRight: Radius.circular(8))
      : const BorderRadius.only(
          topLeft: Radius.circular(8), bottomLeft: Radius.circular(8));

  /// Get the appropriate border radius for end
  static BorderRadius get endBorderRadius => AppLocalizations.isRTL
      ? const BorderRadius.only(
          topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))
      : const BorderRadius.only(
          topRight: Radius.circular(8), bottomRight: Radius.circular(8));

  /// Get the appropriate margin for start
  static EdgeInsets get startMargin => AppLocalizations.isRTL
      ? const EdgeInsets.only(right: 8)
      : const EdgeInsets.only(left: 8);

  /// Get the appropriate margin for end
  static EdgeInsets get endMargin => AppLocalizations.isRTL
      ? const EdgeInsets.only(left: 8)
      : const EdgeInsets.only(right: 8);

  /// Get the appropriate padding for start
  static EdgeInsets get startPadding => AppLocalizations.isRTL
      ? const EdgeInsets.only(right: 16)
      : const EdgeInsets.only(left: 16);

  /// Get the appropriate padding for end
  static EdgeInsets get endPadding => AppLocalizations.isRTL
      ? const EdgeInsets.only(left: 16)
      : const EdgeInsets.only(right: 16);

  /// Get the appropriate icon for RTL
  static IconData get startIcon =>
      AppLocalizations.isRTL ? Icons.arrow_back_ios : Icons.arrow_forward_ios;

  /// Get the appropriate icon for end
  static IconData get endIcon =>
      AppLocalizations.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios;

  /// Get the appropriate flex alignment for start
  static MainAxisAlignment get startFlex =>
      AppLocalizations.isRTL ? MainAxisAlignment.end : MainAxisAlignment.start;

  /// Get the appropriate flex alignment for end
  static MainAxisAlignment get endFlex =>
      AppLocalizations.isRTL ? MainAxisAlignment.start : MainAxisAlignment.end;

  /// Get the appropriate list order for RTL
  static List<T> getRTLOrder<T>(List<T> items) {
    if (AppLocalizations.isRTL) {
      return items.reversed.toList();
    }
    return items;
  }

  /// Get the appropriate alignment for floating action button
  static FloatingActionButtonLocation get fabLocation => AppLocalizations.isRTL
      ? FloatingActionButtonLocation.startFloat
      : FloatingActionButtonLocation.endFloat;

  /// Get the appropriate alignment for snackbar
  static SnackBarBehavior get snackBarBehavior => AppLocalizations.isRTL
      ? SnackBarBehavior.floating
      : SnackBarBehavior.fixed;

  /// Get the appropriate alignment for bottom sheet
  static Alignment get bottomSheetAlignment =>
      AppLocalizations.isRTL ? Alignment.bottomRight : Alignment.bottomLeft;

  /// Get the appropriate alignment for top sheet
  static Alignment get topSheetAlignment =>
      AppLocalizations.isRTL ? Alignment.topRight : Alignment.topLeft;

  /// Get the appropriate alignment for center sheet
  static Alignment get centerSheetAlignment => Alignment.center;

  /// Get the appropriate alignment for dialog
  static Alignment get dialogAlignment => Alignment.center;

  /// Get the appropriate alignment for popup menu
  static Alignment get popupMenuAlignment =>
      AppLocalizations.isRTL ? Alignment.topRight : Alignment.topLeft;

  /// Get the appropriate alignment for tooltip
  static Alignment get tooltipAlignment =>
      AppLocalizations.isRTL ? Alignment.topRight : Alignment.topLeft;

  /// Get the appropriate alignment for overlay
  static Alignment get overlayAlignment =>
      AppLocalizations.isRTL ? Alignment.topRight : Alignment.topLeft;

  /// Get the appropriate alignment for modal barrier
  static Alignment get modalBarrierAlignment => Alignment.center;

  /// Get the appropriate alignment for navigator
  static Alignment get navigatorAlignment => Alignment.center;

  /// Get the appropriate alignment for route
  static Alignment get routeAlignment => Alignment.center;

  /// Get the appropriate alignment for page
  static Alignment get pageAlignment => Alignment.center;

  /// Get the appropriate alignment for scaffold
  static Alignment get scaffoldAlignment => Alignment.center;

  /// Get the appropriate alignment for container
  static Alignment get containerAlignment => Alignment.center;

  /// Get the appropriate alignment for box
  static Alignment get boxAlignment => Alignment.center;

  /// Get the appropriate alignment for card
  static Alignment get cardAlignment => Alignment.center;

  /// Get the appropriate alignment for list tile
  static Alignment get listTileAlignment => Alignment.center;

  /// Get the appropriate alignment for list view
  static Alignment get listViewAlignment => Alignment.center;

  /// Get the appropriate alignment for grid view
  static Alignment get gridViewAlignment => Alignment.center;

  /// Get the appropriate alignment for table
  static Alignment get tableAlignment => Alignment.center;

  /// Get the appropriate alignment for data table
  static Alignment get dataTableAlignment => Alignment.center;

  /// Get the appropriate alignment for paginated data table
  static Alignment get paginatedDataTableAlignment => Alignment.center;

  /// Get the appropriate alignment for single child scroll view
  static Alignment get singleChildScrollViewAlignment => Alignment.center;

  /// Get the appropriate alignment for custom scroll view
  static Alignment get customScrollViewAlignment => Alignment.center;

  /// Get the appropriate alignment for nested scroll view
  static Alignment get nestedScrollViewAlignment => Alignment.center;

  /// Get the appropriate alignment for scrollable
  static Alignment get scrollableAlignment => Alignment.center;

  /// Get the appropriate alignment for scrollbar
  static Alignment get scrollbarAlignment => Alignment.center;

  /// Get the appropriate alignment for notification listener
  static Alignment get notificationListenerAlignment => Alignment.center;

  /// Get the appropriate alignment for inherited widget
  static Alignment get inheritedWidgetAlignment => Alignment.center;

  /// Get the appropriate alignment for stateful widget
  static Alignment get statefulWidgetAlignment => Alignment.center;

  /// Get the appropriate alignment for stateless widget
  static Alignment get statelessWidgetAlignment => Alignment.center;

  /// Get the appropriate alignment for render object
  static Alignment get renderObjectAlignment => Alignment.center;

  /// Get the appropriate alignment for element
  static Alignment get elementAlignment => Alignment.center;

  /// Get the appropriate alignment for widget
  static Alignment get widgetAlignment => Alignment.center;

  /// Get the appropriate alignment for build context
  static Alignment get buildContextAlignment => Alignment.center;

  /// Get the appropriate alignment for media query
  static Alignment get mediaQueryAlignment => Alignment.center;

  /// Get the appropriate alignment for theme
  static Alignment get themeAlignment => Alignment.center;

  /// Get the appropriate alignment for color scheme
  static Alignment get colorSchemeAlignment => Alignment.center;

  /// Get the appropriate alignment for text theme
  static Alignment get textThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for icon theme
  static Alignment get iconThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for app bar theme
  static Alignment get appBarThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for bottom app bar theme
  static Alignment get bottomAppBarThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for card theme
  static Alignment get cardThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for chip theme
  static Alignment get chipThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for data table theme
  static Alignment get dataTableThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for dialog theme
  static Alignment get dialogThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for divider theme
  static Alignment get dividerThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for floating action button theme
  static Alignment get floatingActionButtonThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for icon button theme
  static Alignment get iconButtonThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for input decoration theme
  static Alignment get inputDecorationThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for list tile theme
  static Alignment get listTileThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for navigation bar theme
  static Alignment get navigationBarThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for navigation drawer theme
  static Alignment get navigationDrawerThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for navigation rail theme
  static Alignment get navigationRailThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for popup menu theme
  static Alignment get popupMenuThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for progress indicator theme
  static Alignment get progressIndicatorThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for radio theme
  static Alignment get radioThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for slider theme
  static Alignment get sliderThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for snack bar theme
  static Alignment get snackBarThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for switch theme
  static Alignment get switchThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for tab bar theme
  static Alignment get tabBarThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for text button theme
  static Alignment get textButtonThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for time picker theme
  static Alignment get timePickerThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for toggle buttons theme
  static Alignment get toggleButtonsThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for tooltip theme
  static Alignment get tooltipThemeAlignment => Alignment.center;

  /// Get the appropriate alignment for visual density
  static Alignment get visualDensityAlignment => Alignment.center;

  /// Get the appropriate alignment for material state property
  static Alignment get materialStatePropertyAlignment => Alignment.center;

  /// Get the appropriate alignment for material tap target size
  static Alignment get materialTapTargetSizeAlignment => Alignment.center;

  /// Get the appropriate alignment for material type
  static Alignment get materialTypeAlignment => Alignment.center;

  /// Get the appropriate alignment for material visual density
  static Alignment get materialVisualDensityAlignment => Alignment.center;

  /// Get the appropriate alignment for material state
  static Alignment get materialStateAlignment => Alignment.center;

  /// Get the appropriate alignment for material state property
  static Alignment get materialStatePropertyAlignment2 => Alignment.center;

  /// Get the appropriate alignment for material state property resolve
  static Alignment get materialStatePropertyResolveAlignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property all
  static Alignment get materialStatePropertyAllAlignment => Alignment.center;

  /// Get the appropriate alignment for material state property resolve with
  static Alignment get materialStatePropertyResolveWithAlignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable
  static Alignment get materialStatePropertyResolveWithNullableAlignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable2
  static Alignment get materialStatePropertyResolveWithNullable2Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable3
  static Alignment get materialStatePropertyResolveWithNullable3Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable4
  static Alignment get materialStatePropertyResolveWithNullable4Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable5
  static Alignment get materialStatePropertyResolveWithNullable5Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable6
  static Alignment get materialStatePropertyResolveWithNullable6Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable7
  static Alignment get materialStatePropertyResolveWithNullable7Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable8
  static Alignment get materialStatePropertyResolveWithNullable8Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable9
  static Alignment get materialStatePropertyResolveWithNullable9Alignment =>
      Alignment.center;

  /// Get the appropriate alignment for material state property resolve with nullable10
  static Alignment get materialStatePropertyResolveWithNullable10Alignment =>
      Alignment.center;
}
