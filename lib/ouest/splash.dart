import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tve_kit/tve_kit.dart';
import 'package:video_player/video_player.dart';

import 'brand.dart';

/// Écran de démarrage animé : la vidéo d'animation Ouest TV
/// (`assets/video/splash.mp4`, 5 s, muette) en plein écran.
///
/// - Tant que la vidéo n'est pas prête : fond blanc (comme l'écran natif).
/// - À la fin de la vidéo, si les données ne sont pas encore chargées, la
///   dernière image reste affichée avec une barre de chargement.
/// - Erreur de chargement : message + « Réessayer » par-dessus.
/// - Si la vidéo ne peut pas être lue : écran fixe [_StaticSplash].
class OuestSplash extends StatefulWidget {
  final Object? error;
  final VoidCallback onRetry;
  const OuestSplash({super.key, this.error, required this.onRetry});

  static const video = 'assets/video/splash.mp4';

  @override
  State<OuestSplash> createState() => _OuestSplashState();
}

class _OuestSplashState extends State<OuestSplash> with SingleTickerProviderStateMixin {
  /// Moment de l'animation où le logo est formé : le vrai logo de l'app
  /// apparaît alors en fondu à sa place.
  static const _logoAt = Duration(milliseconds: 3400);

  /// Blanc de fond de la vidéo (légèrement grisé par l'encodage).
  static const _videoWhite = Color(0xFFFDFDFD);

  /// Zone du logo dans la vidéo (fractions de l'image 9:16).
  static const _logoLeft = .219, _logoRight = .780, _logoCenterY = .432, _coverTop = .36, _coverBottom = .50;

  late final AnimationController _logoFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  // Sans couper la musique éventuelle de l'utilisateur.
  final _video = VideoPlayerController.asset(
    OuestSplash.video,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  bool _ready = false, _failed = false, _ended = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _video.initialize();
      await _video.setVolume(0);
      _video.addListener(_onTick);
      await _video.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('OuestSplash: vidéo illisible ($e)');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    final v = _video.value;
    if (v.position >= _logoAt && _logoFade.status == AnimationStatus.dismissed) _logoFade.forward();
    final ended =
        v.isInitialized && v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 80);
    if (ended != _ended && mounted) setState(() => _ended = ended);
  }

  @override
  void dispose() {
    _video.removeListener(_onTick);
    _video.dispose();
    _logoFade.dispose();
    super.dispose();
  }

  /// La vidéo, puis par-dessus (en coordonnées de la vidéo, donc recadré
  /// pareil) le logo de l'app qui remplace en fondu celui de l'animation.
  Widget _videoWithLogo(Size v) {
    final left = v.width * _logoLeft, width = v.width * (_logoRight - _logoLeft);
    final logoHeight = width / 2.277; // proportions de assets/images/logo.png
    return Stack(
      children: [
        Positioned.fill(child: VideoPlayer(_video)),
        // Fond blanc qui masque le logo de la vidéo (sans widget Opacity).
        Positioned(
          left: left - 12,
          width: width + 24,
          top: v.height * _coverTop,
          height: v.height * (_coverBottom - _coverTop),
          child: AnimatedBuilder(
            animation: _logoFade,
            builder: (context, _) => ColoredBox(color: _videoWhite.withValues(alpha: _logoFade.value)),
          ),
        ),
        Positioned(
          left: left,
          width: width,
          top: v.height * _logoCenterY - logoHeight / 2,
          height: logoHeight,
          child: Image.asset(OuestBrand.logo, opacity: _logoFade, fit: BoxFit.contain),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _StaticSplash(error: widget.error, onRetry: widget.onRetry);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _video.value.size.width,
                height: _video.value.size.height,
                child: _videoWithLogo(_video.value.size),
              ),
            ),
          // Chargement qui se prolonge après l'animation.
          if (_ended && widget.error == null)
            Positioned(
              left: 0,
              right: 0,
              top: size.height * .62,
              child: const Center(
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: OuestBrand.primary,
                    backgroundColor: Color(0xFFF2CDCD),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          if (widget.error != null)
            Positioned(
              left: 24,
              right: 24,
              top: size.height * .6,
              child: Material(
                color: Colors.white,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: TveErrorView(error: widget.error!, onRetry: widget.onRetry),
              ),
            ),
        ],
      ),
    );
  }
}

/// Écran de démarrage fixe (repli si la vidéo est illisible) : logo + slogan
/// sur fond blanc, trois arcs en bas et le bloc « Suivez-nous ».
class _StaticSplash extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _StaticSplash({this.error, required this.onRetry});

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
                    if (error == null) ...[
                      const SizedBox(height: 36),
                      const SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: OuestBrand.primary,
                          backgroundColor: Color(0xFFF2CDCD),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ],
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
