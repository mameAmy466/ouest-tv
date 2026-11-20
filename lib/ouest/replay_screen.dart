import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'player.dart';
import 'shell.dart';
import 'widgets.dart';

/// Maquette « replay player ». Sans [video], joue la dernière vidéo publiée.
class OuestReplayScreen extends StatelessWidget {
  final OuestVideo? video;
  const OuestReplayScreen({super.key, this.video});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final shell = OuestShell.of(context);
    final content = OuestContent(tve);
    return Scaffold(
      backgroundColor: OuestBrand.background,
      appBar: OuestAppBar(title: 'Replay TV', onMenu: shell.openMenu),
      body: TveFuture<(OuestVideo?, List<OuestRail>)>(
        load: () async {
          final v = video ?? (await content.latest.load()).firstOrNull;
          final topics = await content.topics().catchError((_) => <OuestRail>[]);
          return (v, topics);
        },
        builder: (context, data, _) {
          final (v, topics) = data;
          if (v == null) return const TveEmptyView(icon: Icons.video_library_outlined);
          void open(OuestVideo next, List<OuestVideo> _) => shell.openVideo(next);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _player(tve, v),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Text(
                  v.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: OuestBrand.text,
                  ),
                ),
              ),
              OuestFollowBar(shareText: [v.title, v.shareUrl].whereType<String>().join('\n')),
              const SizedBox(height: 16),
              OuestCollapsibleRail(rail: content.similar(v), initiallyExpanded: true, playing: v, onOpen: open),
              for (final r in topics) OuestCollapsibleRail(rail: r, playing: v, onOpen: open),
            ],
          );
        },
      ),
    );
  }

  /// Le lecteur dépend du type de la vidéo :
  /// - vidéo YouTube synchronisée, ou vidéo de l'API de source `youtube` → lecteur YouTube ;
  /// - vidéo VOD de l'API → lecteur natif (URL de lecture signée de l'API).
  Widget _player(TveScope tve, OuestVideo v) {
    final ext = v.external;
    if (ext != null) return OuestPlayer(key: ValueKey(v.id), youtubeId: ext.externalId);
    final vod = v.vod!;
    final ytId = vod.isYoutube ? vod.externalId : null;
    if (ytId != null) return OuestPlayer(key: ValueKey(v.id), youtubeId: ytId);
    // VOD (ou YouTube sans id connu : l'API renvoie alors un descripteur `youtube`).
    return OuestPlayer(key: ValueKey(v.id), load: () => tve.api.getVideoPlayback(vod.slug));
  }
}
