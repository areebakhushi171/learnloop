import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationUtils {
  const NavigationUtils._();

  static void push(BuildContext context, String route, {Object? extra}) {
    context.push(route, extra: extra);
  }

  static void go(BuildContext context, String route, {Object? extra}) {
    context.go(route, extra: extra);
  }

  static void pop(BuildContext context, [Object? result]) {
    context.pop(result);
  }
}
