import 'dart:ui';

import 'package:flutter/cupertino.dart';

class ConvertRbgWavelength {
  double call(Color color) {
    double hue = HSVColor.fromColor(color).hue;
    return 620.0;
  }
}