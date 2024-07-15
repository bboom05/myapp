// lib/system/style.dart

import 'package:flutter/material.dart';

final myBoxDecorationBorder = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    border: Border.all(width: 1, color: Colors.grey.shade300));

final myBoxDecorationShadow = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 2,
      blurRadius: 5,
      offset: Offset(0, 3), // changes position of shadow
    ),
  ],
);

BoxDecoration customBoxDecoration(
    {Color? color,
    double? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Color? shadowColor,
    double? spreadRadius,
    double? blurRadius,
    Offset? offset}) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 8.0)),
    border: Border.all(
        width: borderWidth ?? 1, color: borderColor ?? Colors.grey.shade300),
    boxShadow: [
      BoxShadow(
        color: shadowColor ?? Colors.grey.withOpacity(0.5),
        spreadRadius: spreadRadius ?? 2,
        blurRadius: blurRadius ?? 5,
        offset: offset ?? Offset(0, 3), // changes position of shadow
      ),
    ],
  );
}
