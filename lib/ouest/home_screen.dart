import 'package:flutter/material.dart';
import 'package:tve_kit/tve_kit.dart';

import 'brand.dart';
import 'content.dart';
import 'shell.dart';
import 'widgets.dart';

/// Maquette « accueil » : carte de la chaîne (EN DIRECT clignotant), carrousel
/// animé « Dernières vidéos », puis une rangée par émission / playlist.
class OuestHomeScreen extends StatelessWidget {
  const OuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tve = TveScope.of(context);
    final shell = OuestShell.of(context);
    return Scaffold(
      backgroundColor: OuestBrand.background,
      appBar: OuestAppBar(title: 'Accueil', uppercase: true, onMenu: shell.openMenu),
      body: TveFuture<List<OuestRail>>(
        load: () => OuestContent(tve).all(),
        builder: (context, rails, reload) => RefreshIndicator(
          onRefresh: () async {
            tve.api.clearCache();
            await reload();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: OuestChannelCard(
                  subtitle: 'Suivez votre chaîne ${tve.appName} en direct.',
                  onLive: () => shell.go(OuestPage.live),
                ),
              ),
              for (final (i, r) in rails.indexed)
                i == 0
                    ? OuestFeaturedRail(rail: r, onOpen: (v, _) => shell.openVideo(v))
                    : OuestRailSection(rail: r, onOpen: (v, _) => shell.openVideo(v)),
            ],
          ),
        ),
      ),
    );
  }
}
