import 'package:flutter/material.dart';

class ScreenUtils {
  const ScreenUtils._();

  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;
}
