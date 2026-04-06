import 'package:flutter/material.dart';

/// Represents where the tooltip should appear relative to the highlighted area.
enum TooltipPosition { above, below, center }

/// A single callout item within a tutorial step (e.g., icon + label).
class TutorialCallout {
  final IconData icon;
  final String label;
  final String description;

  const TutorialCallout({
    required this.icon,
    required this.label,
    required this.description,
  });
}

/// Data model for a single step in the app tutorial.
class TutorialStep {
  /// Unique identifier for this step.
  final String id;

  /// The GlobalKey of the widget to highlight. If null, shows a full-screen overlay.
  final GlobalKey? targetKey;

  /// Title displayed in the tooltip.
  final String title;

  /// Body text displayed in the tooltip.
  final String body;

  /// Optional list of callout items (icon + label pairs).
  final List<TutorialCallout> callouts;

  /// Where the tooltip should be positioned relative to the target.
  final TooltipPosition tooltipPosition;

  /// Optional icon to display in the tooltip header.
  final IconData? headerIcon;

  /// Shape of the spotlight cutout — circle or rounded rectangle.
  final SpotlightShape spotlightShape;

  /// Extra padding around the highlighted widget.
  final double spotlightPadding;

  /// Called when this step becomes active (e.g. to open a sheet).
  final void Function(BuildContext context)? onEnter;

  /// Called when leaving this step (e.g. to dismiss a sheet).
  final void Function(BuildContext context)? onExit;

  const TutorialStep({
    required this.id,
    this.targetKey,
    required this.title,
    required this.body,
    this.callouts = const [],
    this.tooltipPosition = TooltipPosition.below,
    this.headerIcon,
    this.spotlightShape = SpotlightShape.roundedRect,
    this.spotlightPadding = 8.0,
    this.onEnter,
    this.onExit,
  });
}

enum SpotlightShape { circle, roundedRect }
