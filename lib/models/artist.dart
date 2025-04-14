class Artist {
  final String id;
  final String name;
  final String uri;

  Artist({required this.id, required this.name, required this.uri});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      uri: json['uri'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}