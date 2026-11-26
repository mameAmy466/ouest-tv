import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tve_kit/tve_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Identité visuelle et textes fixes de l'app Ouest TV (d'après les maquettes).
abstract final class OuestBrand {
  static const name = 'OUEST TV';
  static const tagline = "la chaîne d'information de l'Afrique de l'Ouest";

  /// Brun du bas du splash, couleur principale de l'app.
  static const primary = Color(0xFF6E2316);

  /// Accents orange (chevrons du menu, puce de date, icônes sociales).
  static const accent = Color(0xFFE5732A);

  /// Rouge du badge / bouton « EN DIRECT » et de la barre de progression.
  static const live = Color(0xFFF20D0D);

  static const background = Color(0xFFF6F6F6);
  static const text = Color(0xFF1B1B1B);

  static const logo = 'assets/images/logo.png';

  /// Message quand la chaîne n'a aucune vidéo disponible.
  static const noVideos = "Les vidéos d'Ouest TV ne sont pas disponibles pour le moment. Revenez un peu plus tard.";

  /// Image jointe au partage (logo + slogan, 1200×630).
  static const shareImage = 'assets/images/share_card.png';
}

/// Liens des réseaux sociaux.
///
/// Les valeurs non nulles ici sont prioritaires sur celles de l'API (`social.*`),
/// et le splash (affiché avant le chargement de l'API) n'utilise que celles-ci.
/// TODO(ouest-tv) : renseigner les vrais liens.
abstract final class OuestLinks {
  static const String? facebook = null;
  static const String? instagram = null;
  static const String? twitter = null;
  static const String? whatsapp = null;
  static const String? youtube = null;
  static const String? linkedin = null;
  static const website = 'https://www.ouest.tv';
}

enum OuestSocial { facebook, instagram, twitter, whatsapp, youtube, linkedin, website }

extension OuestSocialX on OuestSocial {
  FaIconData get icon => switch (this) {
    OuestSocial.facebook => FontAwesomeIcons.facebookF,
    OuestSocial.instagram => FontAwesomeIcons.instagram,
    OuestSocial.twitter => FontAwesomeIcons.xTwitter,
    OuestSocial.whatsapp => FontAwesomeIcons.whatsapp,
    OuestSocial.youtube => FontAwesomeIcons.youtube,
    OuestSocial.linkedin => FontAwesomeIcons.linkedinIn,
    OuestSocial.website => FontAwesomeIcons.globe,
  };

  String get label => switch (this) {
    OuestSocial.facebook => 'Facebook',
    OuestSocial.instagram => 'Instagram',
    OuestSocial.twitter => 'X',
    OuestSocial.whatsapp => 'WhatsApp',
    OuestSocial.youtube => 'YouTube',
    OuestSocial.linkedin => 'LinkedIn',
    OuestSocial.website => 'Site web',
  };

  /// Lien fixe de l'app, sinon celui de l'API (si [social] est fourni).
  String? url([TveSocial? social]) => switch (this) {
    OuestSocial.facebook => OuestLinks.facebook ?? social?.facebook,
    OuestSocial.instagram => OuestLinks.instagram ?? social?.instagram,
    OuestSocial.twitter => OuestLinks.twitter ?? social?.twitter,
    OuestSocial.whatsapp => OuestLinks.whatsapp,
    OuestSocial.youtube => OuestLinks.youtube ?? social?.youtube,
    OuestSocial.linkedin => OuestLinks.linkedin,
    OuestSocial.website => OuestLinks.website,
  };
}

Future<void> openLink(String? url) async {
  if (url == null || url.isEmpty) return;
  final u = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
  if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
}

/// « Aujourd'hui », « Hier » ou « 12/10/2021 ».
String ouestDay(DateTime? d, {DateTime? now}) {
  if (d == null) return '';
  final l = d.toLocal();
  final n = now ?? DateTime.now();
  final day = DateTime(l.year, l.month, l.day);
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Hier';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}

/// « 16:30 ».
String ouestTime(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
