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
      // Pour les vidéos des flux YouTube (`feed` : videos, popular-videos…),
      // l'API renvoie l'heure de synchronisation, pas la date de publication :
      // on ne l'affiche pas. Les vidéos des playlists ont la vraie date.
      publishedAt = v.feed == null ? v.publishedAt : null,
      vod = null,
      external = v;

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
  final TveClient api;
  final TveGroup group;
  final TveConfig config;
  OuestContent(this.api, this.group, this.config);

  factory OuestContent.of(TveScope tve) => OuestContent(tve.api, tve.group, tve.config);

  static const railSize = 10;
  static const maxShowRails = 12;

  /// Nombre de rangées de l'accueil préchargées pendant le splash.
  static const preloadedRails = 4;

  // Résultats du préchargement, servis une seule fois (les rechargements
  // suivants, ex. tirer pour rafraîchir, repartent de l'API).
  static List<OuestRail>? _preloadedHome;
  static final Map<String, List<OuestVideo>> _preloadedItems = {};

  /// Précharge l'accueil (liste des rangées + premières vidéos) pendant le splash.
  static Future<void> preload(TveClient api, TveGroup group, TveConfig config) async {
    final rails = await OuestContent(api, group, config).all();
    await Future.wait(
      rails.take(preloadedRails).map((r) async {
        try {
          _preloadedItems[r.id] = await r.load();
        } catch (_) {}
      }),
    );
    _preloadedHome = rails;
  }

  OuestRail _rail(String id, String title, Future<List<OuestVideo>> Function() load) =>
      OuestRail(id: id, title: title, load: () async => _preloadedItems.remove(id) ?? await load());

  TveClient get _api => api;
  List<String>? get _ch => config.channelFilter;
  bool get _vod => group.has('videos');
  bool get _yt => group.has('external-videos');

  OuestRail get latest => _rail('latest', 'DERNIÈRES VIDÉOS', () async {
    if (_vod) {
      final p = await _api.listVideos(channel: _ch, limit: railSize);
      return p.items.map(OuestVideo.vod).toList();
    }
    if (_yt) {
      // Flux « vidéos » de la chaîne YouTube (sans les lives) ; à défaut, tout.
      var p = await _api.listExternalVideos(feed: const ['videos'], channel: _ch, limit: railSize);
      if (p.items.isEmpty) p = await _api.listExternalVideos(channel: _ch, limit: railSize);
      return p.items.map(OuestVideo.external).toList();
    }
    return const [];
  });

  /// Rangées thématiques (émissions ou playlists).
  Future<List<OuestRail>> topics() async {
    if (_vod && group.has('shows')) {
      final p = await _api.listShows(channel: _ch, limit: maxShowRails);
      return [
        for (final s in p.items)
          _rail(
            'show:${s.slug}',
            s.title.toUpperCase(),
            () async => (await _api.listVideos(show: [s.slug], limit: railSize)).items.map(OuestVideo.vod).toList(),
          ),
      ];
    }
    if (_yt && group.has('external-playlists')) {
      final p = await _api.listExternalPlaylists(channel: _ch, limit: maxShowRails);
      return [
        for (final pl in p.items.where((e) => e.itemCount != 0 && !_isAutoPlaylist(e.title)))
          _rail(
            'playlist:${pl.id}',
            pl.title.toUpperCase(),
            () async => (await _api.listExternalVideos(
              playlist: pl.id,
              limit: railSize,
            )).items.map(OuestVideo.external).toList(),
          ),
      ];
    }
    return const [];
  }

  /// Playlists automatiques de YouTube, sans intérêt éditorial.
  static bool _isAutoPlaylist(String title) =>
      const {'favorites', 'favoris', 'liked videos', 'vidéos j\'aime'}.contains(title.trim().toLowerCase());

  /// Toutes les rangées de l'accueil (celles du préchargement, la première fois).
  Future<List<OuestRail>> all() async {
    final pre = _preloadedHome;
    _preloadedHome = null;
    return pre ?? [latest, ...await topics().catchError((_) => <OuestRail>[])];
  }

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

  /// Chaîne à jouer en direct : celle de l'app (aCAS) ou `defaultChannel`,
  /// sinon la première chaîne TV.
  Future<TveChannel?> liveChannel() async {
    final wanted = config.preferredChannel;
    if (wanted != null) {
      try {
        return await _api.getChannel(wanted);
      } on TveException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    final p = await _api.listChannels(kind: const ['tv', 'webtv', 'acas', 'cinema'], limit: 100);
    final items = _ch == null ? p.items : p.items.where((c) => _ch!.contains(c.slug)).toList();
    return items.firstOrNull;
  }
}
