import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double get widthMultiplier => screenWidth / 100;
  double get heightMultiplier => screenHeight / 100;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
