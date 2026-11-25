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

- **Source des données** : Ouest TV est une chaîne **aCAS** : groupe partagé `acasgroup`, chaîne
  `ouest-tv` (`lib/main.dart`). Sa configuration d'app (nom, logo, réseaux, à propos…) vient de
  `…/groups/acasgroup/channels/ouest-tv?include=app` et se règle dans le back-office aCAS.
  Pour tester avec un autre groupe : `flutter run --dart-define=TVE_GROUP=leraltv`.
- **À corriger dans le back-office** (config d'app de la chaîne) : Facebook, X, Instagram et le
  texte « À propos » sont encore ceux de Koode ; le site est `koode.net` (l'app affiche
  `www.ouest.tv`, fixé dans `OuestLinks`).
- **Liens sociaux et site web** (Facebook, Instagram, X, WhatsApp, YouTube, LinkedIn, site) : `OuestLinks`
  dans `lib/ouest/brand.dart`. Le splash affiche le site (www.ouest.tv), Facebook et YouTube, et n'utilise que ces liens (l'API n'est pas encore chargée) ; les
  autres écrans prennent aussi `social.*` de l'API.
- **Dépendance `tve_kit`** : pointe sur la branche `claude/blissful-faraday-iun5xh` (ajout de
  `splashBuilder` / `homeBuilder`). À passer sur `main` ou un tag une fois fusionnée.
- Logo HD : les icônes et l'écran natif sont générés à partir du logo fourni en 512×512.
  Avec un logo haute définition (1024 px ou plus), remplacez les fichiers de `assets/branding/`
  puis relancez les deux commandes ci-dessous.

## Icône et écran de démarrage natif

L'icône de l'app et l'écran affiché avant le chargement de Flutter (fond blanc + logo) sont
générés depuis `assets/branding/` (config dans `pubspec.yaml`) :

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Ensuite, l'écran de démarrage Flutter reste affiché au moins 5 s, le temps de charger le groupe
et de précharger l'accueil (`preload` dans `lib/main.dart`). Sur l'accueil, le bouton retour
demande confirmation avant de quitter l'app.

## Lancer

Flutter ≥ 3.32 (Dart ≥ 3.8). Testé avec Flutter 3.35.7.

```bash
flutter pub get
flutter run                                   # Android / iOS
flutter run --dart-define=TVE_GROUP=leraltv   # avec un autre groupe, pour tester
```

**Chrome (web)** : l'API renvoie l'en-tête CORS en double (`Access-Control-Allow-Origin: *, *`),
le navigateur bloque donc les requêtes (à corriger côté serveur). En attendant, pour tester :

```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

Sur le web, le direct HLS ne se lit pas (Chrome n'a pas de lecteur HLS natif) ; sur mobile, OK.

Police : Montserrat, embarquée dans `assets/fonts` (licence SIL OFL).
