import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

abstract interface class LmChromeTransitionBinding {
  Animation<double> get primaryAnimation;
  Animation<double> get secondaryAnimation;
  ValueListenable<double>? get gestureProgress;
}
