import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';
import 'package:video_player/video_player.dart';

import 'brand.dart';
import 'widgets.dart';

/// Lecteur des maquettes « direct » et « replay » : vidéo en 16:9, barre rouge,
/// puis une ligne de contrôles sous l'image (lecture, heure, son, plein écran).
///
/// - flux HLS / audio de l'API → lecteur natif avec ces contrôles ;
/// - vidéo YouTube → lecteur YouTube intégré (ses propres contrôles).
///
/// [load] est rappelé si la lecture échoue (URL signée expirée).
class OuestPlayer extends StatefulWidget {
  final Future<TvePlayback> Function()? load;
  final String? youtubeId;
  final bool isLive;

  const OuestPlayer({super.key, this.load, this.youtubeId, this.isLive = false})
    : assert(load != null || youtubeId != null);

  @override
  State<OuestPlayer> createState() => _OuestPlayerState();
}

class _OuestPlayerState extends State<OuestPlayer> {
  VideoPlayerController? _ctrl;
  String? _youtube;
  Object? _error;
  bool _loading = true;
  int _retries = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _init();
    if (widget.isLive) {
      _clock = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _disposeCtrl();
    super.dispose();
  }

  void _disposeCtrl() {
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    _ctrl = null;
  }

  Future<void> _init() async {
    _disposeCtrl();
    setState(() {
      _error = null;
      _loading = true;
      _youtube = widget.youtubeId;
    });
    if (_youtube != null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final p = await widget.load!();
      if (!mounted) return;
      switch (p.protocol) {
        case TvePlaybackProtocol.youtube:
          _youtube = youtubeIdFromUrl(p.url) ?? p.url;
        case TvePlaybackProtocol.hls:
        case TvePlaybackProtocol.audio:
          final c = VideoPlayerController.networkUrl(
            Uri.parse(p.url),
            formatHint: p.protocol == TvePlaybackProtocol.hls ? VideoFormat.hls : null,
          );
          _ctrl = c;
          await c.initialize();
          c.addListener(_onTick);
          await c.play();
        case TvePlaybackProtocol.dailymotion:
        case TvePlaybackProtocol.unknown:
          await openLink(p.url);
          throw const TveException(status: 0, code: 'playback_unavailable', title: 'Lecture externe');
      }
      if (mounted) setState(() => _loading = false);
    } catch (e, st) {
      // Détail complet dans la console (flutter run) pour le diagnostic.
      debugPrint('OuestPlayer: lecture impossible ($e)');
      debugPrintStack(stackTrace: st, maxFrames: 5);
      // Une nouvelle tentative automatique avec une URL signée fraîche.
      if (_retries < 1 && widget.load != null) {
        _retries++;
        await Future<void>.delayed(const Duration(seconds: 1));
        if (mounted) return _init();
      }
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _onTick() {
    final c = _ctrl;
    if (c == null) return;
    if (c.value.hasError && _retries < 2) {
      _retries++;
      _init();
      return;
    }
    if (mounted) setState(() {});
  }

  bool _inFullscreen = false;

  /// Plein écran : remettre le téléphone à la verticale le quitte (TveFullscreenPage).
  Future<void> _fullscreen() async {
    final c = _ctrl;
    if (c == null || _inFullscreen) return;
    _inFullscreen = true;
    await TveFullscreenPage.push(context, _Fullscreen(controller: c, isLive: widget.isLive));
    _inFullscreen = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_youtube != null) {
      return TveYoutubePlayer(key: ValueKey(_youtube), videoId: _youtube!);
    }
    final c = _ctrl;
    final ready = c != null && c.value.isInitialized;
    // Téléphone tourné à l'horizontale pendant la lecture → plein écran.
    return TveRotationWatcher(
      onLandscape: () {
        if (ready && c.value.isPlaying) _fullscreen();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready)
                    GestureDetector(
                      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                          child: VideoPlayer(c),
                        ),
                      ),
                    ),
                  if (_loading || (ready && c.value.isBuffering))
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  if (_error != null)
                    _PlayerError(
                      isLive: widget.isLive,
                      onRetry: () {
                        _retries = 0;
                        _init();
                      },
                    ),
                  if (widget.isLive) const Positioned(left: 24, top: 14, child: OuestLiveBadge()),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 4,
            child: ready && !widget.isLive
                ? VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: OuestBrand.live,
                      bufferedColor: Color(0x66F20D0D),
                      backgroundColor: Color(0xFF222222),
                    ),
                  )
                : const LinearProgressIndicator(value: 1, color: OuestBrand.live, backgroundColor: Color(0xFF222222)),
          ),
          _Controls(
            playing: ready && c.value.isPlaying,
            muted: ready && c.value.volume == 0,
            time: widget.isLive ? ouestTime(DateTime.now()) : _fmt(ready ? c.value.position : Duration.zero),
            onPlay: ready ? () => c.value.isPlaying ? c.pause() : c.play() : null,
            onMute: ready ? () => c.setVolume(c.value.volume == 0 ? 1 : 0) : null,
            onFullscreen: ready ? _fullscreen : null,
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

/// Erreur compacte, qui tient dans la zone vidéo quelle que soit sa taille.
class _PlayerError extends StatelessWidget {
  final bool isLive;
  final VoidCallback onRetry;
  const _PlayerError({required this.isLive, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.portable_wifi_off_rounded, color: Colors.white70, size: 36),
                const SizedBox(height: 10),
                Text(
                  isLive ? 'Le direct est momentanément indisponible.' : 'Lecture impossible pour le moment.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: OuestBrand.live),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool playing, muted;
  final String time;
  final VoidCallback? onPlay, onMute, onFullscreen;
  const _Controls({
    required this.playing,
    required this.muted,
    required this.time,
    this.onPlay,
    this.onMute,
    this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: playing ? 'Pause' : 'Lecture',
            iconSize: 30,
            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
            onPressed: onPlay,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(4)),
            child: Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: muted ? 'Activer le son' : 'Couper le son',
            icon: Icon(muted ? Icons.volume_off_outlined : Icons.volume_up_outlined),
            onPressed: onMute,
          ),
          IconButton(
            tooltip: 'Plein écran',
            icon: const Icon(Icons.fullscreen_rounded, size: 30),
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}

class _Fullscreen extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isLive;
  const _Fullscreen({required this.controller, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => c.value.isPlaying ? c.pause() : c.play(),
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                child: VideoPlayer(c),
              ),
            ),
          ),
          if (isLive) const Positioned(left: 24, top: 16, child: OuestLiveBadge()),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              tooltip: 'Quitter le plein écran',
              color: Colors.white,
              iconSize: 32,
              icon: const Icon(Icons.fullscreen_exit_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
