import 'package:base_app/features/mind_article/feature_flags.dart';
import 'package:flutter/material.dart';

/// Single source of truth for the menu drawer's feature list (RAJ-38, RAJ-39).
///
/// Adding a new feature = one edit here. The drawer reads this list at build
/// time and filters by feature flag — entries whose flag is disabled don't
/// render.
///
/// Flag keys are imported from base_app (post-RAJ-83 dep flip) so the website
/// and base_app can never drift on the canonical key strings. URLs are still
/// duplicated as plain strings to keep the bundle lean — pulling them from
/// base_app's page classes would drag the page widgets into this WASM build.
class MenuFeature {
  final String flagKey;
  final String label;
  final String description;
  final IconData icon;
  final String url; // deep link target (web URL or app schema)

  const MenuFeature({
    required this.flagKey,
    required this.label,
    required this.description,
    required this.icon,
    required this.url,
  });
}

class MenuFeatures {
  /// The full registered list. Order is preserved in the drawer.
  static const List<MenuFeature> all = [
    MenuFeature(
      flagKey: MindArticleFlags.enabled,
      label: 'ai-mind deep dive',
      description: 'Long-form on the cognitive layer',
      icon: Icons.menu_book_outlined,
      url: 'https://vishalraj.space/articles/ai-mind-deep-dive',
    ),
  ];

  /// Default flag values used at app startup. Mirror base_app's defaults.
  /// Both apps init their own FeatureFlags singleton; flipping a flag in
  /// one app does NOT affect the other (singletons are per-process).
  static const Map<String, bool> defaultFlags = {
    MindArticleFlags.enabled: true, // dev default; flip to env-aware later
  };

  MenuFeatures._();
}
