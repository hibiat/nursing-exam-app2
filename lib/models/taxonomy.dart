class TaxonomyDomain {
  const TaxonomyDomain({
    required this.id,
    required this.name,
    required this.subdomains,
  });

  final String id;
  final String name;
  final List<TaxonomySubdomain> subdomains;

  factory TaxonomyDomain.fromJson(Map<String, dynamic> json) {
    final subdomainsJson = json['subdomains'] as List<dynamic>? ?? [];
    return TaxonomyDomain(
      id: json['id'] as String,
      name: json['name'] as String,
      subdomains: subdomainsJson
          .map((item) => TaxonomySubdomain.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TaxonomySubdomain {
  const TaxonomySubdomain({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory TaxonomySubdomain.fromJson(Map<String, dynamic> json) {
    return TaxonomySubdomain(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
