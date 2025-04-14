class Track {
  final String id;
  final String name;
  final String uri;
  final String albumId;
  final List<String> artistIds;

  Track({required this.id, required this.name, required this.uri, required this.albumId, required this.artistIds});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      uri: json['uri'],
      albumId: json['album']['id'],
      artistIds: List<String>.from(json['artists'].map((a) => a['id'])),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Track && id == other.id;

  @override
  int get hashCode => id.hashCode;
}