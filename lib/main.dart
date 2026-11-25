import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tve_kit/tve_kit.dart';

import 'ouest/brand.dart';
import 'ouest/content.dart';
import 'ouest/shell.dart';
import 'ouest/splash.dart';

/// ─── VARIABLES ────────────────────────────────────────────────────────────
/// Ouest TV est une chaîne aCAS : toutes les chaînes aCAS sont dans le groupe
/// `acasgroup`, seule la chaîne change (`ouest-tv`). Sa configuration d'app
/// (nom, logo, réseaux, à propos…) vient de
/// https://tveapi.acan.group/v3/groups/acasgroup/channels/ouest-tv?include=app
///
/// Test avec un autre groupe : `flutter run --dart-define=TVE_GROUP=leraltv`
/// (la chaîne n'est alors plus imposée, sauf `--dart-define=TVE_CHANNEL=…`).
const _groupOverride = String.fromEnvironment('TVE_GROUP');
const group = _groupOverride == '' ? 'acasgroup' : _groupOverride;
const channel = String.fromEnvironment('TVE_CHANNEL', defaultValue: _groupOverride == '' ? 'ouest-tv' : '');

const config = TveConfig(
  group: group,
  appChannel: channel == '' ? null : channel,
  appName: 'Ouest TV',
  // Site déclaré à YouTube pour le lecteur intégré (sinon erreurs 152/153).
  youtubeOrigin: OuestLinks.website,
  // Partage : on partage l'app (liens des stores).
  // TODO(ouest-tv) : liens FICTIFS pour les tests, à remplacer par les vrais
  // après publication (l'id Android correspond à applicationId).
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.acangroup.ouest_tv',
  appStoreUrl: 'https://apps.apple.com/app/ouest-tv/id0000000000',
  shareTemplate:
      '{title}\n\n'
      "📺 Regardez Ouest TV, la chaîne d'information de l'Afrique de l'Ouest, en direct et en replay "
      "sur l'application {app} :\n\n"
      'Android : {playstore}\n'
      'iPhone : {appstore}',
);

/// ─── DESIGN ───────────────────────────────────────────────────────────────
final design = TveDesign(
  primary: OuestBrand.primary,
  secondary: OuestBrand.accent,
  backgroundLight: OuestBrand.background,
  themeMode: ThemeMode.light,
  fontFamily: 'Montserrat', // embarquée (assets/fonts, licence OFL)
  logoAsset: OuestBrand.logo,
  // Splash affiché au moins 5 s, le temps de charger le groupe et de précharger l'accueil.
  splashMinDuration: const Duration(seconds: 5),
  preload: (api, group) => OuestContent.preload(api, group, config),
  splashBuilder: (context, error, onRetry) => OuestSplash(error: error, onRetry: onRetry),
  homeBuilder: (_) => const OuestShell(),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // App en portrait ; seuls les lecteurs passent en paysage (plein écran).
  TveFullscreen.appOrientations = const [DeviceOrientation.portraitUp];
  SystemChrome.setPreferredOrientations(TveFullscreen.appOrientations);
  runTveApp(config: config, design: design);
}
