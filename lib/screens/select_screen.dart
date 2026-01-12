import 'package:flutter/material.dart';

import '../models/taxonomy.dart';
import '../services/taxonomy_service.dart';
import 'study_screen.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key, required this.mode});

  final String mode;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final TaxonomyService taxonomyService = TaxonomyService();

  Future<List<TaxonomyDomain>> _loadDomains() {
    final asset = widget.mode == 'required'
        ? 'assets/taxonomy_required.json'
        : 'assets/taxonomy_general.json';
    return taxonomyService.loadDomains(asset);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaxonomyDomain>>(
      future: _loadDomains(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('分類データの読み込みに失敗しました'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final domains = snapshot.data!;
        if (domains.isEmpty) {
          return const Center(child: Text('分類データがありません'));
        }
        return ListView.builder(
          itemCount: domains.length,
          itemBuilder: (context, index) {
            final domain = domains[index];
            return ExpansionTile(
              title: Text(domain.name),
              children: domain.subdomains
                  .map(
                    (subdomain) => ListTile(
                      title: Text(subdomain.name),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudyScreen(
                              mode: widget.mode,
                              domainId: domain.id,
                              subdomainId: subdomain.id,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}
