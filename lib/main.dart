import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';

import 'ouest/brand.dart';
import 'ouest/shell.dart';
import 'ouest/splash.dart';

/// ─── VARIABLES ────────────────────────────────────────────────────────────
/// Code du groupe dans l'API TVE (https://tveapi.acan.group/v3/groups/<code>).
/// Surchargeable au build : `flutter run --dart-define=TVE_GROUP=leraltv`.
const group = String.fromEnvironment('TVE_GROUP', defaultValue: 'ouesttv');

const config = TveConfig(
  group: group,
  appName: 'Ouest TV',
  // Site déclaré à YouTube pour le lecteur intégré (sinon erreurs 152/153).
  youtubeOrigin: OuestLinks.website,
  // defaultChannel: 'ouest-tv',
  // playStoreUrl: 'https://play.google.com/store/apps/details?id=com.acangroup.ouest_tv',
  // appStoreUrl: 'https://apps.apple.com/app/id000000000',
);

/// ─── DESIGN ───────────────────────────────────────────────────────────────
final design = TveDesign(
  primary: OuestBrand.primary,
  secondary: OuestBrand.accent,
  backgroundLight: OuestBrand.background,
  themeMode: ThemeMode.light,
  fontFamily: 'Montserrat', // embarquée (assets/fonts, licence OFL)
  logoAsset: OuestBrand.logo,
  splashMinDuration: const Duration(milliseconds: 1800),
  splashBuilder: (context, error, onRetry) => OuestSplash(error: error, onRetry: onRetry),
  homeBuilder: (_) => const OuestShell(),
);

void main() => runTveApp(config: config, design: design);
