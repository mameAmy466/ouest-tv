import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'player.dart';
import 'shell.dart';
import 'widgets.dart';

/// Page « direct » : lecteur, carte de la chaîne (programme en cours / à suivre
/// quand la grille est disponible), carte « Suivez-nous », puis les rangées.
class OuestLiveScreen extends StatelessWidget {
  const OuestLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final shell = OuestShell.of(context);
    final content = OuestContent.of(tve);
    return Scaffold(
      backgroundColor: OuestBrand.background,
      appBar: OuestAppBar(title: '${tve.appName} en direct', onMenu: shell.openMenu),
      body: TveFuture<(TveChannel?, List<OuestRail>)>(
        load: () async {
          final r = await Future.wait([content.liveChannel(), content.topics().catchError((_) => <OuestRail>[])]);
          return (r[0] as TveChannel?, r[1] as List<OuestRail>);
        },
        builder: (context, data, _) {
          final (channel, topics) = data;
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              if (channel == null)
                const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: TveEmptyView(icon: Icons.live_tv_rounded),
                )
              else
                OuestPlayer(
                  key: ValueKey(channel.slug),
                  isLive: true,
                  load: () => tve.api.getChannelLive(channel.slug),
                ),
              const SizedBox(height: 14),
              _LiveInfoCard(channel: channel),
              const SizedBox(height: 12),
              OuestFollowBar(shareText: '${tve.appName} en direct'),
              const SizedBox(height: 18),
              OuestCollapsibleRail(rail: content.latest, initiallyExpanded: true, onOpen: (v, _) => shell.openVideo(v)),
              for (final r in topics) OuestCollapsibleRail(rail: r, onOpen: (v, _) => shell.openVideo(v)),
            ],
          );
        },
      ),
    );
  }
}

/// Carte de la chaîne : logo, nom, « En direct » pulsant, slogan, et
/// « En ce moment » (avec progression) / « À suivre » si la grille existe.
class _LiveInfoCard extends StatefulWidget {
  final TveChannel? channel;
  const _LiveInfoCard({required this.channel});

  @override
  State<_LiveInfoCard> createState() => _LiveInfoCardState();
}

class _LiveInfoCardState extends State<_LiveInfoCard> {
  Future<TveChannelNow?>? _now;
  Timer? _tick;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_now != null) return;
    final tve = TveScope.of(context);
    final ch = widget.channel;
    if (ch != null && tve.group.has('shows')) {
      _now = tve.api
          .listScheduleNow(channel: [ch.slug])
          .then<TveChannelNow?>((l) => l.firstOrNull, onError: (Object _) => null);
      // Rafraîchit la barre de progression du programme en cours.
      _tick = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    return OuestPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
                child: Image.asset(OuestBrand.logo, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tve.appName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: OuestBrand.text),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: OuestBrand.live.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OuestLiveDot(size: 7),
                          SizedBox(width: 6),
                          Text(
                            'En direct',
                            style: TextStyle(color: OuestBrand.live, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(OuestBrand.tagline, style: TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.35)),
          if (_now != null)
            FutureBuilder<TveChannelNow?>(
              future: _now,
              builder: (context, snap) {
                final n = snap.data;
                if (n == null || (n.current == null && n.next == null)) return const SizedBox.shrink();
                return Column(
                  children: [
                    const Divider(height: 26, color: Color(0xFFEFEFEF)),
                    if (n.current != null) _Slot(label: 'EN CE MOMENT', slot: n.current!, current: true),
                    if (n.current != null && n.next != null) const SizedBox(height: 12),
                    if (n.next != null) _Slot(label: 'À SUIVRE', slot: n.next!),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final TveScheduleSlot slot;
  final bool current;
  const _Slot({required this.label, required this.slot, this.current = false});

  @override
  Widget build(BuildContext context) {
    final total = slot.endsAt.difference(slot.startsAt).inSeconds;
    final done = DateTime.now().difference(slot.startsAt).inSeconds;
    final progress = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Row(
      children: [
        TveImage(slot.showLogo ?? slot.showPoster, width: 52, height: 52, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                  color: current ? OuestBrand.live : const Color(0xFF8A8A8A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slot.showTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OuestBrand.text),
              ),
              const SizedBox(height: 4),
              if (current)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: OuestBrand.live,
                          backgroundColor: const Color(0xFFF1E3E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ouestTime(slot.startsAt)} – ${ouestTime(slot.endsAt)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B6B)),
                    ),
                  ],
                )
              else
                Text('à ${ouestTime(slot.startsAt)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B6B))),
            ],
          ),
        ),
      ],
    );
  }
}
