# Ouest TV

App mobile Ouest TV (« la chaîne d'information de l'Afrique de l'Ouest »), construite sur le
framework [`tve_kit`](https://github.com/mameAmy466/framework) et l'API TVE v3.

## Écrans (d'après les maquettes)

| Écran | Fichier |
|---|---|
| Démarrage (logo, slogan, arcs, site www.ouest.tv, Facebook, YouTube) | `lib/ouest/splash.dart` |
| Accueil (carte chaîne + EN DIRECT clignotant, carrousel animé, rangées de vidéos) | `lib/ouest/home_screen.dart` |
| Direct (lecteur, carte chaîne, réseaux, rangées repliables) | `lib/ouest/live_screen.dart` |
| Replay TV (lecteur, titre, vidéos similaires) | `lib/ouest/replay_screen.dart` |
| Menu latéral animé (la page glisse et rétrécit ; Accueil / Direct / Replay, Paramètres, réseaux, site) | `lib/ouest/shell.dart` |

Le reste : `brand.dart` (couleurs, slogan, **liens des réseaux sociaux**), `content.dart` (source des
rangées), `player.dart` (lecteur avec contrôles sous l'image), `widgets.dart`.

Rangées : « Dernières vidéos » puis une rangée par émission (vidéos VOD de l'API) ou, à défaut, par
playlist YouTube synchronisée. Les rangées vides sont masquées.

## À compléter

- **Code du groupe TVE** : `ouesttv` dans `lib/main.dart` — ce groupe n'existe pas encore dans l'API.
  Pour tester avec un autre groupe : `flutter run --dart-define=TVE_GROUP=leraltv`.
- **Liens sociaux et site web** (Facebook, Instagram, X, WhatsApp, YouTube, LinkedIn, site) : `OuestLinks`
  dans `lib/ouest/brand.dart`. Le splash affiche le site (www.ouest.tv), Facebook et YouTube, et n'utilise que ces liens (l'API n'est pas encore chargée) ; les
  autres écrans prennent aussi `social.*` de l'API.
- **Dépendance `tve_kit`** : pointe sur la branche `claude/blissful-faraday-iun5xh` (ajout de
  `splashBuilder` / `homeBuilder`). À passer sur `main` ou un tag une fois fusionnée.
- Icône de l'app : `assets/images/app_icon.png` (logo d'origine, 512×512), à générer pour
  Android/iOS (ex. `flutter_launcher_icons`).

## Lancer

Flutter ≥ 3.32 (Dart ≥ 3.8). Testé avec Flutter 3.35.7.

```bash
flutter pub get
flutter run                                   # Android / iOS
flutter run --dart-define=TVE_GROUP=leraltv   # avec un groupe qui existe déjà dans l'API
```

**Chrome (web)** : l'API renvoie l'en-tête CORS en double (`Access-Control-Allow-Origin: *, *`),
le navigateur bloque donc les requêtes (à corriger côté serveur). En attendant, pour tester :

```bash
flutter run -d chrome --dart-define=TVE_GROUP=leraltv --web-browser-flag "--disable-web-security"
```

Sur le web, le direct HLS ne se lit pas (Chrome n'a pas de lecteur HLS natif) ; sur mobile, OK.

Police : Montserrat, embarquée dans `assets/fonts` (licence SIL OFL).
