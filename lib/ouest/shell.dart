import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'home_screen.dart';
import 'live_screen.dart';
import 'replay_screen.dart';

enum OuestPage { home, live, replay }

/// Navigation de l'app : une page à la fois (accueil, direct, replay),
/// le menu s'ouvre en plein écran depuis l'icône en haut à gauche.
class OuestShell extends StatefulWidget {
  const OuestShell({super.key});

  static OuestShellState of(BuildContext context) => context.findAncestorStateOfType<OuestShellState>()!;

  @override
  State<OuestShell> createState() => OuestShellState();
}

class OuestShellState extends State<OuestShell> {
  OuestPage _page = OuestPage.home;
  OuestVideo? _video;

  OuestPage get page => _page;

  void go(OuestPage page) => setState(() {
    _page = page;
    if (page != OuestPage.replay) _video = null;
  });

  /// Ouvre une vidéo dans la page « Replay TV ».
  void openVideo(OuestVideo video) => setState(() {
    _page = OuestPage.replay;
    _video = video;
  });

  Future<void> openMenu() async {
    final page = await Navigator.of(
      context,
    ).push<OuestPage>(MaterialPageRoute(builder: (_) => const OuestMenuScreen()));
    if (page != null) go(page);
  }

  @override
  Widget build(BuildContext context) {
    // Une seule page montée : le lecteur s'arrête quand on change de page.
    final body = switch (_page) {
      OuestPage.home => const OuestHomeScreen(),
      OuestPage.live => const OuestLiveScreen(),
      OuestPage.replay => OuestReplayScreen(key: ValueKey(_video?.id), video: _video),
    };
    return PopScope(
      canPop: _page == OuestPage.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(OuestPage.home);
      },
      child: KeyedSubtree(key: ValueKey(_page), child: body),
    );
  }
}

/// Maquette « menu ».
class OuestMenuScreen extends StatelessWidget {
  const OuestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final social = tve.group.social;
    final facebook = OuestSocial.facebook.url(social);
    void push(String title, Widget body) => Navigator.of(context).push(
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

    return Scaffold(
      backgroundColor: OuestBrand.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'MENU',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF3A3A3A)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                children: [
                  _MenuGroup(
                    children: [
                      _MenuItem('ACCUEIL', () => Navigator.of(context).pop(OuestPage.home)),
                      _MenuItem(
                        '${tve.appName.toUpperCase()} EN DIRECT',
                        () => Navigator.of(context).pop(OuestPage.live),
                      ),
                      _MenuItem('REPLAY TV', () => Navigator.of(context).pop(OuestPage.replay)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 36, 0, 20),
                    child: Text(
                      'PARAMETRES',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A7A7A)),
                    ),
                  ),
                  _MenuGroup(
                    children: [
                      if (facebook != null) _MenuItem('FACEBOOK', () => openLink(facebook)),
                      _MenuItem('A PROPOS', () => push('À propos', const TveAboutScreen())),
                      _MenuItem(
                        'POLITIQUE CONFIDENTIALITÉ',
                        () => push(
                          'Confidentialité',
                          tve.group.privacyPolicyHtml == null
                              ? const TveEmptyView(icon: Icons.privacy_tip_outlined)
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: TveHtml(tve.group.privacyPolicyHtml!),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Text('Follow us on', style: TextStyle(fontSize: 12, color: Color(0xFF3A3A3A))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final n in const [
                  OuestSocial.facebook,
                  OuestSocial.twitter,
                  OuestSocial.instagram,
                  OuestSocial.linkedin,
                ])
                  if (n.url(social) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => openLink(n.url(social)),
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFF3C9AE)),
                          ),
                          child: FaIcon(n.icon, size: 11, color: OuestBrand.accent, semanticLabel: n.label),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEEEEEE)),
          children[i],
        ],
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 104,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, color: OuestBrand.text)),
          ),
          const Icon(Icons.chevron_right_rounded, color: OuestBrand.accent),
        ],
      ),
    ),
  );
}
