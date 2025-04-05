import 'package:flutter/material.dart';

/// Animasyonlu dialog gösterici
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  RouteSettings? routeSettings,
  Color? barrierColor,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return builder(buildContext);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    routeSettings: routeSettings,
  );
}

/// Animasyonlu Bottom Sheet gösteren yardımcı fonksiyon
Future<T?> showAnimatedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool enableDrag = true,
  bool isDismissible = true,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
}) {
  final theme = Theme.of(context);
  
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor ?? theme.canvasColor,
    elevation: elevation,
    shape: shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: clipBehavior,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    routeSettings: routeSettings,
    useRootNavigator: useRootNavigator,
  );
}

/// Animasyonlu Snackbar gösteren yardımcı fonksiyon
void showAnimatedSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
  Color? backgroundColor,
  SnackBarAction? action,
  bool floating = false,
  EdgeInsetsGeometry? margin,
  double? elevation,
  ShapeBorder? shape,
  SnackBarBehavior behavior = SnackBarBehavior.fixed,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
      action: action,
      margin: margin,
      elevation: elevation,
      shape: shape,
      behavior: floating ? SnackBarBehavior.floating : behavior,
    ),
  );
} 