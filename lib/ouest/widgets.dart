import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';

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

/// Badge rouge « EN DIRECT », qui clignote (sauf si les animations sont
/// désactivées dans les réglages d'accessibilité du téléphone).
class OuestLiveBadge extends StatefulWidget {
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
  State<OuestLiveBadge> createState() => _OuestLiveBadgeState();
}

class _OuestLiveBadgeState extends State<OuestLiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _opacity = Tween(
    begin: 1.0,
    end: .25,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.blink && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!animate) {
      _c.value = 0;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      padding: widget.padding,
      decoration: BoxDecoration(color: OuestBrand.live, borderRadius: BorderRadius.circular(3)),
      child: Text(
        'EN DIRECT',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: widget.fontSize,
          letterSpacing: -.2,
        ),
      ),
    ),
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
          color: const Color(0xFFE6E6E6),
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
    return Container(color: Colors.white, padding: const EdgeInsets.all(14), child: row);
  }
}

/// Bloc « Suivez nous sur » + icônes + bouton de partage.
class OuestFollowBar extends StatelessWidget {
  final String shareText;
  const OuestFollowBar({super.key, required this.shareText});

  @override
  Widget build(BuildContext context) {
    final social = TveScope.of(context).group.social;
    const networks = [OuestSocial.facebook, OuestSocial.twitter, OuestSocial.instagram, OuestSocial.linkedin];
    final links = [
      for (final n in networks)
        if (n.url(social) != null) n,
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suivez nous sur', style: TextStyle(fontSize: 12, color: OuestBrand.text)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final n in links)
                      IconButton(
                        tooltip: n.label,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        iconSize: 13,
                        icon: FaIcon(n.icon, color: OuestBrand.text),
                        onPressed: () => openLink(n.url(social)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFE2E2E2)),
            ),
            child: IconButton(
              tooltip: 'Partager',
              icon: const Icon(Icons.share_outlined, color: OuestBrand.text),
              onPressed: () => SharePlus.instance.share(ShareParams(text: TveScope.of(context).shareText(shareText))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette vidéo des rangées horizontales.
class OuestVideoCard extends StatelessWidget {
  static const width = 216.0;
  final OuestVideo video;
  final VoidCallback onTap;
  final bool playing;

  /// Grande vignette du carrousel « Dernières vidéos » (largeur imposée par le parent).
  final bool large;
  const OuestVideoCard({super.key, required this.video, required this.onTap, this.playing = false, this.large = false});

  /// Hauteur du texte sous l'image (titre 3 lignes + date).
  static double textHeight({bool large = false}) => large ? 150 : 100;

  @override
  Widget build(BuildContext context) {
    final titleSize = large ? 20.0 : 14.0;
    return SizedBox(
      width: large ? null : width,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TveImage(video.thumbnail, radius: large ? 10 : 6),
                if (playing)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: OuestBrand.live, width: 2),
                      ),
                      child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 36),
                    ),
                  ),
              ],
            ),
            SizedBox(height: large ? 14 : 8),
            SizedBox(
              height: titleSize * 1.4 * 3 + 2,
              child: Text(
                video.title.toUpperCase(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: OuestBrand.text,
                  letterSpacing: -.1,
                ),
              ),
            ),
            SizedBox(height: large ? 18 : 10),
            OuestDateLine(date: video.publishedAt, large: large),
          ],
        ),
      ),
    );
  }
}

/// « Aujourd'hui • 16:30 ».
class OuestDateLine extends StatelessWidget {
  final DateTime? date;
  final bool large;
  const OuestDateLine({super.key, required this.date, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (date == null) return SizedBox(height: large ? 26 : 16);
    final style = TextStyle(fontSize: large ? 19 : 12, color: OuestBrand.text);
    final dot = large ? 11.0 : 6.0;
    return Row(
      children: [
        Text(ouestDay(date), style: style),
        Container(
          width: dot,
          height: dot,
          margin: EdgeInsets.symmetric(horizontal: large ? 18 : 8),
          decoration: const BoxDecoration(color: OuestBrand.accent, shape: BoxShape.circle),
        ),
        Text(ouestTime(date), style: style),
      ],
    );
  }
}

/// Titre de rangée : « DERNIÈRES VIDÉOS ».
class OuestRailTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const OuestRailTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
    child: SizedBox(
      height: 44,
      child: Row(
        children: [
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
          return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, i) => OuestVideoCard(
              video: items[i],
              playing: items[i] == widget.playing,
              onTap: () => widget.onOpen(items[i], items),
            ),
          ),
        );
      },
    );
  }
}

/// Carrousel animé de l'accueil : grande vignette centrée, voisines visibles
/// sur les côtés, défilement automatique (en boucle) mis en pause quand on le
/// fait glisser au doigt.
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

  static const viewportFraction = .86;

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
      _pc.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return LayoutBuilder(
      builder: (context, box) {
        final cardWidth = box.maxWidth * OuestCarousel.viewportFraction - 16;
        final height = cardWidth * 9 / 16 + OuestVideoCard.textHeight(large: true);
        return SizedBox(
          height: height,
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
              itemCount: items.length < 2 ? items.length : null,
              itemBuilder: (context, i) {
                final v = items[i % items.length];
                return AnimatedBuilder(
                  animation: _pc,
                  builder: (context, child) {
                    final page = _pc.hasClients && _pc.position.haveDimensions ? _pc.page! : _start.toDouble();
                    final d = (page - i).abs().clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 1 - d * .08,
                      alignment: Alignment.topCenter,
                      child: Opacity(opacity: 1 - d * .35, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: OuestVideoCard(video: v, large: true, onTap: () => widget.onOpen(v, items)),
                  ),
                );
              },
            ),
          ),
        );
      },
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
                const SizedBox(height: 360, child: Center(child: CircularProgressIndicator()))
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
            trailing: Icon(
              _open ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: OuestBrand.text,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
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
