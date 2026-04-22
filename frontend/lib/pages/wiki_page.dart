import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/wiki_model.dart';

class WikiPage extends StatefulWidget {
  const WikiPage({super.key});

  @override
  State<WikiPage> createState() => _WikiPageState();
}

class _WikiPageState extends State<WikiPage> {
  late final Future<List<WikiCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
  }

  Future<List<WikiCategory>> _loadCategories() async {
    final rawJson = await rootBundle.loadString('assets/data/wiki.json');
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((entry) => WikiCategory.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/text_transparent.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        backgroundColor: AppTheme.surfaceOlive,
        foregroundColor: AppTheme.wikilocGreen,
        elevation: 0,
      ),
      body: FutureBuilder<List<WikiCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.wikilocGreen),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Wiki verileri yüklenemedi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            );
          }

          final categories = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceOlive,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceMoss),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wifi_off, color: AppTheme.wikilocGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu wiki sayfası internetsiz çalışır. Kısa ve pratik tarım notlarını hızlıca okuyabilirsiniz.',
                        style: TextStyle(
                          color: AppTheme.textBlack,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map(
                (category) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOlive,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceMoss),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkGreen.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: AppTheme.wikilocGreen,
                    collapsedIconColor: AppTheme.wikilocGreen,
                    title: Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    children: [
                      ...category.topics.map(
                        (topic) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.surfaceMoss.withValues(alpha: 0.7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                topic.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textBlack,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
