import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'home_screen.dart';
import 'live_screen.dart';
import 'replay_screen.dart';

enum OuestPage { home, live, replay }

/// Navigation de l'app : une page à la fois (accueil, direct, replay) et un
/// menu latéral animé. À l'ouverture, la page glisse vers la droite en
/// rétrécissant (coins arrondis, ombre) et dévoile le menu.
///
/// Ouverture : icône en haut à gauche, ou glissement depuis le bord gauche.
/// Fermeture : toucher la page, glisser vers la gauche, ou bouton retour.
class OuestShell extends StatefulWidget {
  const OuestShell({super.key});

  static OuestShellState of(BuildContext context) => context.findAncestorStateOfType<OuestShellState>()!;

  @override
  State<OuestShell> createState() => OuestShellState();
}

class OuestShellState extends State<OuestShell> with SingleTickerProviderStateMixin {
  OuestPage _page = OuestPage.home;
  OuestVideo? _video;

  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 320),
  );

  /// Zone du bord gauche qui ouvre le menu au glissement.
  static const _edge = 28.0;
  bool _dragging = false;

  OuestPage get page => _page;
  bool get isMenuOpen => _menu.value > 0;

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  void go(OuestPage page) {
    setState(() {
      _page = page;
      if (page != OuestPage.replay) _video = null;
    });
    closeMenu();
  }

  /// Ouvre une vidéo dans la page « Replay TV ».
  void openVideo(OuestVideo video) {
    setState(() {
      _page = OuestPage.replay;
      _video = video;
    });
    closeMenu();
  }

  void openMenu() {
    HapticFeedback.selectionClick();
    _menu.forward();
  }

  void closeMenu() => _menu.reverse();

  double _travel(BuildContext context) => math.min(MediaQuery.sizeOf(context).width * .70, 320);

  void _dragStart(DragStartDetails d) => _dragging = isMenuOpen || d.globalPosition.dx < _edge;

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _menu.value += d.primaryDelta! / _travel(context);
  }

  void _dragEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final v = d.primaryVelocity ?? 0;
    if (v.abs() > 400) {
      v > 0 ? _menu.forward() : _menu.reverse();
    } else {
      _menu.value > .5 ? _menu.forward() : _menu.reverse();
    }
  }

  void _push(String title, Widget body) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: OuestBrand.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        body: body,
      ),
    ),
  );

  /// Bouton retour sur l'accueil : demander avant de quitter l'app.
  Future<void> _confirmQuit() async {
    final name = TveScope.of(context).appName;
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Image.asset(OuestBrand.logo, height: 48),
        title: Text('Quitter $name ?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        content: const Text("Voulez-vous vraiment quitter l'application ?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: OuestBrand.text, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OuestBrand.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (quit ?? false) await SystemNavigator.pop();
  }

  void _openAbout() => _push('À propos', const TveAboutScreen());

  void _openPrivacy() => _push(
    'Confidentialité',
    ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(child: Image.asset(OuestBrand.logo, height: 70)),
        const SizedBox(height: 24),
        for (final p in OuestBrand.privacyText)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(p, style: const TextStyle(fontSize: 15, height: 1.6, color: OuestBrand.text)),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Une seule page montée : le lecteur s'arrête quand on change de page.
    final body = switch (_page) {
      OuestPage.home => const OuestHomeScreen(),
      OuestPage.live => const OuestLiveScreen(),
      OuestPage.replay => OuestReplayScreen(key: ValueKey(_video?.id), video: _video),
    };
    final travel = _travel(context);

    return AnimatedBuilder(
      animation: _menu,
      builder: (context, page) {
        final t = Curves.easeOutCubic.transform(_menu.value);
        final open = _menu.value > 0;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (open) {
              closeMenu();
            } else if (_page != OuestPage.home) {
              go(OuestPage.home);
            } else {
              _confirmQuit();
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: t > .5 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _dragStart,
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
              child: Stack(
                children: [
                  // Menu derrière la page.
                  Positioned.fill(
                    child: _SideMenu(
                      progress: _menu,
                      width: travel,
                      current: _page,
                      onSelect: go,
                      onAbout: _openAbout,
                      onPrivacy: _openPrivacy,
                    ),
                  ),
                  // Page, qui glisse et rétrécit.
                  Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..translateByDouble(travel * t, 0, 0, 1)
                      ..scaleByDouble(1 - .16 * t, 1 - .16 * t, 1, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28 * t),
                        boxShadow: [
                          if (open)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .35 * t),
                              blurRadius: 40,
                              offset: const Offset(-8, 12),
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28 * t),
                        child: AbsorbPointer(absorbing: open, child: page),
                      ),
                    ),
                  ),
                  // Toucher la page réduite la ferme.
                  if (open)
                    Positioned(
                      left: travel * t,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: closeMenu),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_page), child: body),
    );
  }
}

/// Le menu latéral : fond brun dégradé, logo, entrées animées en cascade.
class _SideMenu extends StatelessWidget {
  final Animation<double> progress;
  final double width;
  final OuestPage current;
  final ValueChanged<OuestPage> onSelect;
  final VoidCallback onAbout, onPrivacy;

  const _SideMenu({
    required this.progress,
    required this.width,
    required this.current,
    required this.onSelect,
    required this.onAbout,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final social = tve.group.social;
    final facebook = OuestSocial.facebook.url(social);

    var index = 0;
    Widget stagger(Widget child) => _Stagger(progress: progress, index: index++, child: child);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8A2E1C), OuestBrand.primary, Color(0xFF3E120A)],
            stops: [0, .45, 1],
          ),
        ),
        child: Stack(
          children: [
            // Halos décoratifs, en écho aux arcs du splash.
            Positioned(
              left: -width * .55,
              bottom: -width * .35,
              child: _Halo(size: width * 1.3, alpha: .06),
            ),
            Positioned(
              left: -width * .35,
              bottom: -width * .55,
              child: _Halo(size: width * 1.1, alpha: .06),
            ),
            SafeArea(
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stagger(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Image.asset(OuestBrand.logo, height: 44, semanticLabel: OuestBrand.name),
                        ),
                      ),
                      const SizedBox(height: 12),
                      stagger(
                        Text(
                          OuestBrand.tagline,
                          style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5, height: 1.35),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            stagger(
                              _MenuTile(
                                icon: Icons.home_rounded,
                                label: 'Accueil',
                                selected: current == OuestPage.home,
                                onTap: () => onSelect(OuestPage.home),
                              ),
                            ),
                            stagger(
                              _MenuTile(
                                icon: Icons.live_tv_rounded,
                                label: '${tve.appName} en direct',
                                selected: current == OuestPage.live,
                                trailing: const _LiveDot(),
                                onTap: () => onSelect(OuestPage.live),
                              ),
                            ),
                            stagger(
                              _MenuTile(
                                icon: Icons.video_library_rounded,
                                label: 'Replay TV',
                                selected: current == OuestPage.replay,
                                onTap: () => onSelect(OuestPage.replay),
                              ),
                            ),
                            const SizedBox(height: 22),
                            stagger(
                              Padding(
                                padding: const EdgeInsets.only(left: 14, bottom: 8),
                                child: Text(
                                  'PARAMÈTRES',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .5),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            if (facebook != null)
                              stagger(
                                _MenuTile(
                                  faIcon: FontAwesomeIcons.facebookF,
                                  label: 'Facebook',
                                  external: true,
                                  onTap: () => openLink(facebook),
                                ),
                              ),
                            stagger(_MenuTile(icon: Icons.info_outline_rounded, label: 'À propos', onTap: onAbout)),
                            stagger(
                              _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Confidentialité', onTap: onPrivacy),
                            ),
                          ],
                        ),
                      ),
                      stagger(_Footer(social: social)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrée en cascade : chaque élément glisse et apparaît un peu après le précédent.
class _Stagger extends StatelessWidget {
  final Animation<double> progress;
  final int index;
  final Widget child;
  const _Stagger({required this.progress, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = math.min(.1 + index * .05, .6);
    final anim = CurvedAnimation(
      parent: progress,
      curve: Interval(start, math.min(start + .45, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      // Glissement seul (pas de widget Opacity : évite les erreurs Impeller sur iOS).
      builder: (context, child) => Transform.translate(offset: Offset(-56 * (1 - anim.value), 0), child: child),
      child: child,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData? icon;
  final FaIconData? faIcon;
  final String label;
  final bool selected, external;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuTile({
    this.icon,
    this.faIcon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.external = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? OuestBrand.primary : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (selected)
                  BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: faIcon != null ? FaIcon(faIcon, size: 17, color: fg) : Icon(icon, size: 22, color: fg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
                ?trailing,
                if (external) Icon(Icons.north_east_rounded, size: 16, color: fg.withValues(alpha: .6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Point rouge pulsant à côté de « en direct ».
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 8 + 10 * _c.value,
            height: 8 + 10 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OuestBrand.live.withValues(alpha: .5 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: OuestBrand.live),
          ),
        ],
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  final TveSocial social;
  const _Footer({required this.social});

  @override
  Widget build(BuildContext context) {
    final networks = [
      for (final n in const [OuestSocial.facebook, OuestSocial.youtube, OuestSocial.twitter, OuestSocial.linkedin])
        if (n.url(social) != null) n,
    ];
    final site = OuestSocial.website.url();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: .15), height: 24),
        if (networks.isNotEmpty)
          Row(
            children: [
              for (final n in networks)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => openLink(n.url(social)),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .1),
                        border: Border.all(color: Colors.white.withValues(alpha: .25)),
                      ),
                      child: FaIcon(n.icon, size: 14, color: Colors.white, semanticLabel: n.label),
                    ),
                  ),
                ),
            ],
          ),
        if (site != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => openLink(site),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ads_click_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  site.replaceFirst(RegExp(r'^https?://'), ''),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Halo extends StatelessWidget {
  final double size, alpha;
  const _Halo({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    ),
  );
}
