import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'player.dart';
import 'shell.dart';
import 'widgets.dart';

/// Maquette « live player ».
class OuestLiveScreen extends StatelessWidget {
  const OuestLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final shell = OuestShell.of(context);
    final content = OuestContent(tve);
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
            padding: const EdgeInsets.only(bottom: 24),
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
              const Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 16), child: OuestChannelCard(boxed: false)),
              OuestFollowBar(shareText: '${tve.appName} en direct'),
              const SizedBox(height: 16),
              OuestCollapsibleRail(rail: content.latest, initiallyExpanded: true, onOpen: (v, _) => shell.openVideo(v)),
              for (final r in topics) OuestCollapsibleRail(rail: r, onOpen: (v, _) => shell.openVideo(v)),
            ],
          );
        },
      ),
    );
  }
}
