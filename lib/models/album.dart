class Album {
  final String id;
  final String name;
  final String uri;
  final List<String> artistIds;

  Album({required this.id, required this.name, required this.uri, required this.artistIds});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      uri: json['uri'],
      artistIds: List<String>.from(json['artists'].map((a) => a['id'])),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Album && id == other.id;

  @override
  int get hashCode => id.hashCode;
}