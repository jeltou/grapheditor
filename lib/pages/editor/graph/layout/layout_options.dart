part of '../graph.dart';

class LayoutOptions {

  final Offset origin;


  final double hGap;


  final double vGap;


  final double padding;


  final double? radiusHint;


  final int iterations;

  const LayoutOptions({
    this.origin = const Offset(0, 0),
    this.hGap = 160.0,
    this.vGap = 120.0,
    this.padding = 24.0,
    this.radiusHint,
    this.iterations = 250,
  });

  LayoutOptions copyWith({
    Offset? origin,
    double? hGap,
    double? vGap,
    double? padding,
    double? radiusHint,
    int? iterations,
  }) {
    return LayoutOptions(
      origin: origin ?? this.origin,
      hGap: hGap ?? this.hGap,
      vGap: vGap ?? this.vGap,
      padding: padding ?? this.padding,
      radiusHint: radiusHint ?? this.radiusHint,
      iterations: iterations ?? this.iterations,
    );
  }
}