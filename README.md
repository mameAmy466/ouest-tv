# Ouest TV

App mobile Ouest TV (« la chaîne d'information de l'Afrique de l'Ouest »), construite sur le
framework [`tve_kit`](https://github.com/mameAmy466/framework) et l'API TVE v3.

## Écrans (d'après les maquettes)

| Écran | Fichier |
|---|---|
| Démarrage (logo, slogan, arcs, « Suivez-nous ») | `lib/ouest/splash.dart` |
| Accueil (carte chaîne + bouton EN DIRECT, rangées de vidéos) | `lib/ouest/home_screen.dart` |
| Direct (lecteur, carte chaîne, réseaux, rangées repliables) | `lib/ouest/live_screen.dart` |
| Replay TV (lecteur, titre, vidéos similaires) | `lib/ouest/replay_screen.dart` |
| Menu (Accueil / Direct / Replay, Paramètres, « Follow us on ») | `lib/ouest/shell.dart` |

Le reste : `brand.dart` (couleurs, slogan, **liens des réseaux sociaux**), `content.dart` (source des
rangées), `player.dart` (lecteur avec contrôles sous l'image), `widgets.dart`.

Rangées : « Dernières vidéos » puis une rangée par émission (vidéos VOD de l'API) ou, à défaut, par
playlist YouTube synchronisée. Les rangées vides sont masquées.

## À compléter

- **Code du groupe TVE** : `ouesttv` dans `lib/main.dart` — ce groupe n'existe pas encore dans l'API.
  Pour tester avec un autre groupe : `flutter run --dart-define=TVE_GROUP=leraltv`.
- **Liens sociaux** (Facebook, Instagram, X, WhatsApp, YouTube, LinkedIn) : `OuestLinks` dans
  `lib/ouest/brand.dart`. Le splash n'utilise que ceux-ci (l'API n'est pas encore chargée) ; les
  autres écrans prennent aussi `social.*` de l'API.
- **Dépendance `tve_kit`** : pointe sur la branche `claude/blissful-faraday-iun5xh` (ajout de
  `splashBuilder` / `homeBuilder`). À passer sur `main` ou un tag une fois fusionnée.
- Icône de l'app : `assets/images/app_icon.png` (logo d'origine, 512×512), à générer pour
  Android/iOS (ex. `flutter_launcher_icons`).

## Lancer

```bash
flutter pub get
flutter run
```

Police : Montserrat, embarquée dans `assets/fonts` (licence SIL OFL).
