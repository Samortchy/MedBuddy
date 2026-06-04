import 'package:flutter/widgets.dart';

/// Back-navigation helper for custom app-bar back buttons.
///
/// A bare `Navigator.pop()` / `maybePop()` does nothing when the current screen
/// is the root of the stack (e.g. reached after a `pushReplacement`/tab switch),
/// which makes the back arrow look broken. This pops when possible, and
/// otherwise navigates to a sensible parent route so the button always works.
void goBack(BuildContext context, {String fallbackRoute = '/home'}) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    nav.pushReplacementNamed(fallbackRoute);
  }
}
