class PlexArtist {
  final String ratingKey;
  final String title; // Strict Album Artist
  final String? thumbUrl;
  final String? summary;
  final int albumCount;

  const PlexArtist({
    required this.ratingKey,
    required this.title,
    this.thumbUrl,
    this.summary,
    this.albumCount = 0,
  });
}

class PlexAlbum {
  final String ratingKey;
  final String title;
  final String artistName; // Album Artist
  final int? year;
  final String? thumbUrl;
  final String? spineColorHex;

  const PlexAlbum({
    required this.ratingKey,
    required this.title,
    required this.artistName,
    this.year,
    this.thumbUrl,
    this.spineColorHex,
  });
}

class PlexTrack {
  final String ratingKey;
  final String title;
  final String artistName;
  final String albumTitle;
  final String albumRatingKey;
  final int index;
  final int durationMs;
  final String? thumbUrl;
  final String streamUrl;
  final String? codec;
  final int? bitrate;

  const PlexTrack({
    required this.ratingKey,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.albumRatingKey,
    required this.index,
    required this.durationMs,
    this.thumbUrl,
    required this.streamUrl,
    this.codec,
    this.bitrate,
  });
}

class PlexPlaylist {
  final String ratingKey;
  final String title;
  final int leafCount;
  final String? thumbUrl;

  const PlexPlaylist({
    required this.ratingKey,
    required this.title,
    required this.leafCount,
    this.thumbUrl,
  });
}

enum OutputProtocol {
  localDevice,
  bluetooth,
  bluOS,
  googleCast,
  sonos,
  alexa,
  airPlay,
}

class AudioOutputTarget {
  final String id;
  final String name;
  final OutputProtocol protocol;
  final String? ipAddress;
  final int? port;
  final bool isSupportedOnAndroid;
  final String? note;

  const AudioOutputTarget({
    required this.id,
    required this.name,
    required this.protocol,
    this.ipAddress,
    this.port,
    this.isSupportedOnAndroid = true,
    this.note,
  });
}
