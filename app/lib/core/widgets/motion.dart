import 'package:flutter/widgets.dart';

extension MotionX on BuildContext {
  /// True when the phone's "remove animations" setting is on.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}