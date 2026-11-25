import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';

/// Marge du bas d'une liste plein écran : [extra] + la barre système
/// (navigation Android, indicateur d'accueil iPhone), pour que la fin du
/// contenu ne passe pas dessous.
EdgeInsets ouestBottomPadding(BuildContext context, [double extra = 24]) =>
    EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom + extra);

/// Barre du haut des maquettes : icône menu + titre en capitales.
class OuestAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenu;
  final bool uppercase;
  const OuestAppBar({super.key, required this.title, required this.onMenu, this.uppercase = false});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 64,
    centerTitle: false,
    titleSpacing: 0,
    backgroundColor: OuestBrand.background,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(tooltip: 'Menu', icon: const Icon(Icons.notes_rounded, size: 28), onPressed: onMenu),
    title: Text(
      uppercase ? title.toUpperCase() : title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: OuestBrand.text),
    ),
  );
}

/// Badge rouge « EN DIRECT ». Le bouton reste fixe : seul le point blanc
/// à gauche clignote pour marquer le direct (immobile si les animations sont
/// désactivées dans les réglages d'accessibilité du téléphone).
class OuestLiveBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;
  final bool blink;
  const OuestLiveBadge({
    super.key,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.blink = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: OuestBrand.live, borderRadius: BorderRadius.circular(3)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OuestLiveDot(size: fontSize * .75, color: Colors.white, blink: blink),
        SizedBox(width: fontSize * .55),
        Text(
          'EN DIRECT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: fontSize, letterSpacing: -.2),
        ),
      ],
    ),
  );
}

/// Point « live » qui clignote (opacité + léger battement).
class OuestLiveDot extends StatefulWidget {
  final double size;
  final Color color;
  final bool blink;
  const OuestLiveDot({super.key, this.size = 8, this.color = OuestBrand.live, this.blink = true});

  @override
  State<OuestLiveDot> createState() => _OuestLiveDotState();
}

class _OuestLiveDotState extends State<OuestLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.blink && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!animate) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final t = Curves.easeInOut.transform(_c.value);
      // Couleur semi-transparente plutôt qu'un widget Opacity (évite les
      // erreurs de validation d'Impeller sur iOS avec une animation continue).
      return Transform.scale(
        scale: 1 - .25 * t,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: widget.color.a * (1 - .8 * t)),
            shape: BoxShape.circle,
          ),
        ),
      );
    },
  );
}

/// Carte « logo + OUEST TV + slogan » (accueil et direct).
class OuestChannelCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback? onLive;
  final bool boxed;
  const OuestChannelCard({
    super.key,
    this.name = OuestBrand.name,
    this.subtitle = OuestBrand.tagline,
    this.onLive,
    this.boxed = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 94,
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
          child: Image.asset(OuestBrand.logo, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: OuestBrand.text),
                    ),
                  ),
                  if (onLive != null)
                    InkWell(
                      onTap: onLive,
                      child: const OuestLiveBadge(
                        fontSize: 10,
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.25)),
            ],
          ),
        ),
      ],
    );
    if (!boxed) return row;
    return OuestPanel(margin: EdgeInsets.zero, child: row);
  }
}

/// Carte « Suivez-nous » : réseaux sociaux de la chaîne.
class OuestFollowBar extends StatelessWidget {
  const OuestFollowBar({super.key});

  @override
  Widget build(BuildContext context) {
    final social = TveScope.of(context).group.social;
    const networks = [OuestSocial.facebook, OuestSocial.youtube, OuestSocial.twitter, OuestSocial.linkedin];
    final links = [
      for (final n in networks)
        if (n.url(social) != null) n,
    ];
    if (links.isEmpty) return const SizedBox.shrink();
    return OuestPanel(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivez-nous',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OuestBrand.text),
                ),
                SizedBox(height: 2),
                Text('sur nos réseaux', style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
              ],
            ),
          ),
          for (final n in links)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _RoundButton(
                tooltip: n.label,
                onTap: () => openLink(n.url(social)),
                child: FaIcon(n.icon, size: 14, color: OuestBrand.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton « Partager » (pastille), à côté du titre de ce qu'on partage.
class OuestShareButton extends StatelessWidget {
  final String text;
  const OuestShareButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    return Material(
      color: const Color(0xFFF6ECEA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ouestShare(context, tve.shareText(text), appName: tve.appName),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_rounded, size: 16, color: OuestBrand.primary),
              SizedBox(width: 6),
              Text(
                'Partager',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OuestBrand.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Partage l'app : image aux couleurs d'Ouest TV (logo + slogan), texte avec
/// les liens des stores, et le nom de l'app comme titre / objet.
Future<void> ouestShare(BuildContext context, String text, {required String appName}) async {
  final box = context.findRenderObject() as RenderBox?;
  // Position du bouton : requise par la feuille de partage sur iPad.
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  List<XFile>? files;
  try {
    final data = await rootBundle.load(OuestBrand.shareImage);
    files = [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'ouest-tv.png')];
  } catch (_) {
    files = null; // image indisponible : partage du texte seul
  }
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      title: appName,
      subject: appName,
      files: files,
      fileNameOverrides: files == null ? null : const ['ouest-tv.png'],
      sharePositionOrigin: origin,
    ),
  );
}

class _RoundButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  const _RoundButton({required this.tooltip, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: const Color(0xFFF6ECEA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Center(child: child)),
      ),
    ),
  );
}

/// Carte blanche arrondie, sans bordure, avec une ombre très légère.
class OuestPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const OuestPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  static const shadow = [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6))];

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
    child: child,
  );
}

/// Vignette vidéo des rangées horizontales : carte blanche, sans bordure, avec marge intérieure.
class OuestVideoCard extends StatelessWidget {
  static const width = 216.0;
  static const _pad = 10.0;

  /// Hauteur totale d'une carte (image 16:9 + titre 3 lignes + date + marges).
  static const height = _pad + (width - 2 * _pad) * 9 / 16 + 8 + 14 * 1.4 * 3 + 2 + 10 + 16 + _pad;

  final OuestVideo video;
  final VoidCallback onTap;
  final bool playing;
  const OuestVideoCard({super.key, required this.video, required this.onTap, this.playing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    TveImage(video.thumbnail, radius: 9),
                    if (playing)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(9)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.equalizer_rounded, color: Colors.white, size: 30),
                              Text(
                                'EN LECTURE',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 14 * 1.4 * 3 + 2,
                  child: Text(
                    video.title.toUpperCase(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: OuestBrand.text,
                      letterSpacing: -.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OuestDateLine(date: video.publishedAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Aujourd'hui • 16:30 ».
class OuestDateLine extends StatelessWidget {
  final DateTime? date;
  const OuestDateLine({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox(height: 16);
    const style = TextStyle(fontSize: 12, color: Color(0xFF6B6B6B));
    return Row(
      children: [
        Text(ouestDay(date), style: style),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: OuestBrand.accent, shape: BoxShape.circle),
        ),
        Text(ouestTime(date), style: style),
      ],
    );
  }
}

/// Titre de rangée : petite barre brune + « DERNIÈRES VIDÉOS ».
class OuestRailTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const OuestRailTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
    child: SizedBox(
      height: 46,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: OuestBrand.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: OuestBrand.text),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Liste horizontale de vignettes, chargée à la demande. Se masque si vide.
class OuestRailList extends StatefulWidget {
  final OuestRail rail;
  final void Function(OuestVideo video, List<OuestVideo> rail) onOpen;
  final OuestVideo? playing;

  /// Appelé une fois les vidéos chargées (ex. pour savoir si la rangée est vide).
  final ValueChanged<List<OuestVideo>>? onLoaded;
  const OuestRailList({super.key, required this.rail, required this.onOpen, this.playing, this.onLoaded});

  @override
  State<OuestRailList> createState() => _OuestRailListState();
}

class _OuestRailListState extends State<OuestRailList> {
  late Future<List<OuestVideo>> _f = _load();

  Future<List<OuestVideo>> _load() async {
    final items = await widget.rail.load();
    widget.onLoaded?.call(items);
    return items;
  }

  @override
  void didUpdateWidget(covariant OuestRailList old) {
    super.didUpdateWidget(old);
    if (old.rail.id != widget.rail.id) _f = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OuestVideo>>(
      future: _f,
      builder: (context, snap) {
        if (snap.hasError) {
          return SizedBox(
            height: 120,
            child: TveErrorView(error: snap.error!, onRetry: () => setState(() => _f = _load())),
          );
        }
        final items = snap.data;
        if (items == null) {
          return const SizedBox(
            height: OuestVideoCard.height + 28,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          // Marge de sécurité : la hauteur réelle du texte varie selon la plateforme.
          height: OuestVideoCard.height + 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => Align(
              alignment: Alignment.topCenter,
              child: OuestVideoCard(
                video: items[i],
                playing: items[i] == widget.playing,
                onTap: () => widget.onOpen(items[i], items),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Carrousel « Dernières vidéos » : cartes plein format (image, dégradé,
/// titre en surimpression, bouton lecture), voisines réduites sur les côtés,
/// effet de parallaxe sur l'image, indicateur de position animé et défilement
/// automatique en boucle (en pause pendant le glissement au doigt, coupé si
/// les animations sont désactivées dans l'accessibilité).
class OuestCarousel extends StatefulWidget {
  final List<OuestVideo> items;
  final void Function(OuestVideo video, List<OuestVideo> rail) onOpen;
  final Duration interval;
  const OuestCarousel({
    super.key,
    required this.items,
    required this.onOpen,
    this.interval = const Duration(seconds: 5),
  });

  static const viewportFraction = .84;

  /// Proportions d'une carte (largeur / hauteur).
  static const cardRatio = 16 / 11;

  @override
  State<OuestCarousel> createState() => _OuestCarouselState();
}

class _OuestCarouselState extends State<OuestCarousel> {
  // Départ au milieu d'une très longue liste pour boucler dans les deux sens.
  late final int _start = widget.items.length * 1000;
  late final PageController _pc = PageController(viewportFraction: OuestCarousel.viewportFraction, initialPage: _start);
  Timer? _timer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _dragging || !_pc.hasClients) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
      _pc.nextPage(duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }

  double get _page => _pc.hasClients && _pc.position.haveDimensions ? _pc.page! : _start.toDouble();

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return LayoutBuilder(
      builder: (context, box) {
        final cardWidth = box.maxWidth * OuestCarousel.viewportFraction - 14;
        return Column(
          children: [
            SizedBox(
              // + marge pour l'ombre des cartes
              height: cardWidth / OuestCarousel.cardRatio + 24,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification && n.dragDetails != null) {
                    _dragging = true;
                  } else if (n is ScrollEndNotification && _dragging) {
                    _dragging = false;
                    _schedule(); // repart de zéro après une interaction
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pc,
                  clipBehavior: Clip.none,
                  itemCount: items.length < 2 ? items.length : null,
                  itemBuilder: (context, i) {
                    final v = items[i % items.length];
                    return AnimatedBuilder(
                      animation: _pc,
                      builder: (context, _) {
                        final delta = _page - i; // < 0 : à droite, > 0 : à gauche
                        final d = delta.abs().clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: 1 - d * .1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(7, 4, 7, 20),
                            child: _FeaturedCard(
                              video: v,
                              parallax: delta.clamp(-1.0, 1.0),
                              dim: d * .35,
                              onTap: () => widget.onOpen(v, items),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (items.length > 1)
              AnimatedBuilder(
                animation: _pc,
                builder: (context, _) => _Dots(count: items.length, page: _page),
              ),
          ],
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final OuestVideo video;
  final double parallax;

  /// 0 = carte centrale, jusqu'à ~0,35 = voisine estompée.
  final double dim;
  final VoidCallback onTap;
  const _FeaturedCard({required this.video, required this.parallax, required this.onTap, this.dim = 0});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: const Color(0xFF1B1B1B),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image légèrement agrandie, décalée selon le défilement (parallaxe).
                Transform.translate(
                  offset: Offset(parallax * 40, 0),
                  child: Transform.scale(
                    scale: 1.18,
                    child: TveImage(video.thumbnail, width: double.infinity, height: double.infinity),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x33000000), Color(0xE6000000)],
                      stops: [.35, .55, 1],
                    ),
                  ),
                ),
                // Bouton lecture « verre dépoli ».
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .22),
                      border: Border.all(color: Colors.white.withValues(alpha: .55)),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        video.title.toUpperCase(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DateChip(date: video.publishedAt),
                    ],
                  ),
                ),
                // Voile couleur fond pour estomper les cartes voisines.
                if (dim > 0)
                  IgnorePointer(
                    child: ColoredBox(color: OuestBrand.background.withValues(alpha: dim)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime? date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    const style = TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500);
    return Row(
      children: [
        Text(ouestDay(date), style: style),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: OuestBrand.accent, shape: BoxShape.circle),
        ),
        Text(ouestTime(date), style: style),
      ],
    );
  }
}

/// Indicateur de position : le point actif s'allonge en pastille.
class _Dots extends StatelessWidget {
  final int count;
  final double page;
  const _Dots({required this.count, required this.page});

  @override
  Widget build(BuildContext context) {
    final p = page % count;
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var k = 0; k < count; k++)
            Builder(
              builder: (context) {
                // distance circulaire entre le point k et la page courante
                var d = (p - k).abs();
                d = d > count / 2 ? count - d : d;
                final t = (1 - d).clamp(0.0, 1.0);
                return Container(
                  width: 7 + 17 * t,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFFD9C4C0), OuestBrand.primary, t),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Rangée « à la une » : titre + carrousel. Disparaît si vide.
class OuestFeaturedRail extends StatefulWidget {
  final OuestRail rail;
  final void Function(OuestVideo video, List<OuestVideo> rail) onOpen;
  const OuestFeaturedRail({super.key, required this.rail, required this.onOpen});

  @override
  State<OuestFeaturedRail> createState() => _OuestFeaturedRailState();
}

class _OuestFeaturedRailState extends State<OuestFeaturedRail> {
  late Future<List<OuestVideo>> _f = widget.rail.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OuestVideo>>(
      future: _f,
      builder: (context, snap) {
        if (snap.hasError) {
          return SizedBox(
            height: 160,
            child: TveErrorView(error: snap.error!, onRetry: () => setState(() => _f = widget.rail.load())),
          );
        }
        final items = snap.data;
        if (items != null && items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OuestRailTitle(widget.rail.title),
              if (items == null)
                const SizedBox(height: 290, child: Center(child: CircularProgressIndicator()))
              else
                OuestCarousel(items: items, onOpen: widget.onOpen),
            ],
          ),
        );
      },
    );
  }
}

/// Rangée simple (accueil) : titre + liste. Disparaît entièrement si vide.
class OuestRailSection extends StatefulWidget {
  final OuestRail rail;
  final void Function(OuestVideo video, List<OuestVideo> rail) onOpen;
  const OuestRailSection({super.key, required this.rail, required this.onOpen});

  @override
  State<OuestRailSection> createState() => _OuestRailSectionState();
}

class _OuestRailSectionState extends State<OuestRailSection> {
  bool _empty = false;

  @override
  Widget build(BuildContext context) {
    if (_empty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OuestRailTitle(widget.rail.title),
          OuestRailList(
            rail: widget.rail,
            onOpen: widget.onOpen,
            onLoaded: (items) {
              if (items.isEmpty && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _empty = true);
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Rangée repliable (direct et replay).
class OuestCollapsibleRail extends StatefulWidget {
  final OuestRail rail;
  final bool initiallyExpanded;
  final OuestVideo? playing;
  final void Function(OuestVideo video, List<OuestVideo> rail) onOpen;
  const OuestCollapsibleRail({
    super.key,
    required this.rail,
    required this.onOpen,
    this.initiallyExpanded = false,
    this.playing,
  });

  @override
  State<OuestCollapsibleRail> createState() => _OuestCollapsibleRailState();
}

class _OuestCollapsibleRailState extends State<OuestCollapsibleRail> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: OuestRailTitle(
            widget.rail.title,
            trailing: AnimatedRotation(
              turns: _open ? 0 : -.5,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: OuestPanel.shadow,
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: OuestBrand.text, size: 20),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OuestRailList(rail: widget.rail, onOpen: widget.onOpen, playing: widget.playing),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
