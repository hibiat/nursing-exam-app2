import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/taxonomy.dart';

class TaxonomyService {
  Future<List<TaxonomyDomain>> loadDomains(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final domainsJson = data['domains'] as List<dynamic>? ?? [];
    return domainsJson
        .map((item) => TaxonomyDomain.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
