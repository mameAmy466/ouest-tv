import 'package:tve_kit/tve_kit.dart';

/// Une vidéo affichable dans l'app, qu'elle vienne des vidéos VOD de l'API
/// (`/videos`) ou des vidéos YouTube synchronisées (`/external-videos`).
class OuestVideo {
  final String id;
  final String title;
  final String? thumbnail;
  final DateTime? publishedAt;
  final TveVideo? vod;
  final TveExternalVideo? external;

  OuestVideo.vod(TveVideo v)
    : id = 'vod:${v.slug}',
      title = v.title,
      thumbnail = v.thumbnail,
      publishedAt = v.publishedAt,
      vod = v,
      external = null;

  OuestVideo.external(TveExternalVideo v)
    : id = v.id,
      title = v.title,
      thumbnail = v.thumbnail,
      publishedAt = v.publishedAt,
      vod = null,
      external = v;

  /// Lien public, pour le partage.
  String? get shareUrl => external?.watchUrl;

  @override
  bool operator ==(Object other) => other is OuestVideo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Une rangée de vidéos (« DERNIÈRES VIDÉOS », une émission, une playlist…).
class OuestRail {
  final String id;
  final String title;
  final Future<List<OuestVideo>> Function() load;

  const OuestRail({required this.id, required this.title, required this.load});
}

/// Construit les rangées à partir de ce que l'API déclare pour le groupe :
/// - vidéos VOD : « Dernières vidéos » puis une rangée par émission ;
/// - sinon vidéos YouTube : « Dernières vidéos » puis une rangée par playlist.
class OuestContent {
  final TveScope tve;
  OuestContent(this.tve);

  static const railSize = 10;
  static const maxShowRails = 12;

  TveClient get _api => tve.api;
  List<String>? get _ch => tve.channelFilter;
  bool get _vod => tve.group.has('videos');
  bool get _yt => tve.group.has('external-videos');

  OuestRail get latest => OuestRail(
    id: 'latest',
    title: 'DERNIÈRES VIDÉOS',
    load: () async {
      if (_vod) {
        final p = await _api.listVideos(channel: _ch, limit: railSize);
        return p.items.map(OuestVideo.vod).toList();
      }
      if (_yt) {
        final p = await _api.listExternalVideos(channel: _ch, limit: railSize);
        return p.items.map(OuestVideo.external).toList();
      }
      return const [];
    },
  );

  /// Rangées thématiques (émissions ou playlists).
  Future<List<OuestRail>> topics() async {
    if (_vod && tve.group.has('shows')) {
      final p = await _api.listShows(channel: _ch, limit: maxShowRails);
      return [
        for (final s in p.items)
          OuestRail(
            id: 'show:${s.slug}',
            title: s.title.toUpperCase(),
            load: () async =>
                (await _api.listVideos(show: [s.slug], limit: railSize)).items.map(OuestVideo.vod).toList(),
          ),
      ];
    }
    if (_yt && tve.group.has('external-playlists')) {
      final p = await _api.listExternalPlaylists(channel: _ch, limit: maxShowRails);
      return [
        for (final pl in p.items.where((e) => e.itemCount != 0))
          OuestRail(
            id: 'playlist:${pl.id}',
            title: pl.title.toUpperCase(),
            load: () async => (await _api.listExternalVideos(
              playlist: pl.id,
              limit: railSize,
            )).items.map(OuestVideo.external).toList(),
          ),
      ];
    }
    return const [];
  }

  /// Toutes les rangées de l'accueil.
  Future<List<OuestRail>> all() async => [latest, ...await topics().catchError((_) => <OuestRail>[])];

  /// « Vidéos similaires » à [v].
  OuestRail similar(OuestVideo v) => OuestRail(
    id: 'similar:${v.id}',
    title: 'VIDÉOS SIMILAIRES',
    load: () async {
      final List<OuestVideo> items;
      if (v.vod != null) {
        items = (await _api.listVideos(relatedTo: v.vod!.slug, limit: railSize + 1)).items.map(OuestVideo.vod).toList();
      } else {
        final e = v.external!;
        items = (await _api.listExternalVideos(
          feed: e.feed == null ? null : [e.feed!],
          channel: e.channel == null ? null : [e.channel!.slug],
          limit: railSize + 1,
        )).items.map(OuestVideo.external).toList();
      }
      return items.where((x) => x != v).take(railSize).toList();
    },
  );

  /// Chaîne TV à jouer en direct (config `defaultChannel`, sinon la première).
  Future<TveChannel?> liveChannel() async {
    final p = await _api.listChannels(kind: const ['tv', 'webtv'], limit: 100);
    final items = _ch == null ? p.items : p.items.where((c) => _ch!.contains(c.slug)).toList();
    if (items.isEmpty) return null;
    final wanted = tve.config.defaultChannel;
    return items.firstWhere((c) => c.slug == wanted, orElse: () => items.first);
  }
}
