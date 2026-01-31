class Country {
  final String id;
  final String name;
  final String slug;

  const Country({required this.id, required this.name, required this.slug});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['_id'].toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'slug': slug};
  }
}
