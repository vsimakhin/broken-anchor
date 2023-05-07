import 'package:flutter/material.dart';

Color? getIconColor(bool isTracking) {
  const defaultIcon = Icon(Icons.sailing);
  if (isTracking) {
    return Colors.blueAccent;
  } else {
    return defaultIcon.color;
  }
}

String fmtAccuracy(double mm) {
  return '${mm.toStringAsFixed(2)} m';
}

String fmtDistance(double dd) {
  return '${dd.toStringAsFixed(2)} m';
}

String fmtSpeed(double ss) {
  return '${ss.toStringAsFixed(2)} m/s (${(ss * 1.94384).toStringAsFixed(2)} knots)';
}

String fmtHeading(double hh) {
  String direction = '';

  if (hh >= 22.5 && hh <= 67.5) {
    direction = "NE";
  } else if (hh >= 67.5 && hh <= 112.5) {
    direction = "E";
  } else if (hh >= 112.5 && hh <= 157.5) {
    direction = "SE";
  } else if (hh >= 157.5 && hh <= 202.5) {
    direction = "S";
  } else if (hh >= 202.5 && hh <= 247.5) {
    direction = "SW";
  } else if (hh >= 247.5 && hh <= 292.5) {
    direction = "W";
  } else if (hh >= 292.5 && hh <= 337.5) {
    direction = "NW";
  } else {
    direction = "N";
  }

  return '${hh.toStringAsFixed(0)}° $direction';
}
