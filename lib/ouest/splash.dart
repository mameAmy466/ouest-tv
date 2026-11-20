import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';

/// Écran de démarrage (maquette « splash ») : logo + slogan sur fond blanc,
/// trois arcs en bas et le bloc « Suivez-nous ».
class OuestSplash extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const OuestSplash({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final arcs = size.width * 0.62;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: arcs,
            child: const CustomPaint(painter: _ArcsPainter()),
          ),
          Positioned.fill(
            bottom: arcs * 0.6,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: (size.width * 0.53).clamp(180, 320)),
                      child: Image.asset(OuestBrand.logo, semanticLabel: OuestBrand.name),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "la chaîne d'information de\nl'Afrique de l'Ouest",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: OuestBrand.text),
                    ),
                    if (error != null) ...[const SizedBox(height: 24), TveErrorView(error: error!, onRetry: onRetry)],
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: _FollowUs())),
        ],
      ),
    );
  }
}

/// Bas du splash : site web à gauche, Facebook et YouTube à droite.
class _FollowUs extends StatelessWidget {
  const _FollowUs();

  @override
  Widget build(BuildContext context) {
    final site = OuestSocial.website.url();
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 34),
      child: Row(
        children: [
          if (site != null)
            InkWell(
              onTap: () => openLink(site),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ads_click_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      site.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), ''),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          for (final n in const [OuestSocial.facebook, OuestSocial.youtube])
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: n.url() == null ? null : () => openLink(n.url()),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: FaIcon(n.icon, size: 14, color: OuestBrand.primary, semanticLabel: n.label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Trois grands cercles concentriques dont on ne voit que le haut.
class _ArcsPainter extends CustomPainter {
  const _ArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = w * 0.95;
    const colors = [Color(0xFFF8EAEA), Color(0xFFF2CDCD), OuestBrand.primary];
    final step = size.height * 0.19;
    for (var i = 0; i < colors.length; i++) {
      final top = i * step;
      canvas.drawCircle(Offset(w / 2, top + r), r, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcsPainter oldDelegate) => false;
}
