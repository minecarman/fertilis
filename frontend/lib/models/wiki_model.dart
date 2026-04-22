class WikiTopic {
  const WikiTopic({required this.title, required this.content});

  final String title;
  final String content;

  factory WikiTopic.fromJson(Map<String, dynamic> json) {
    return WikiTopic(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}

class WikiCategory {
  const WikiCategory({required this.title, required this.topics});

  final String title;
  final List<WikiTopic> topics;

  factory WikiCategory.fromJson(Map<String, dynamic> json) {
    final topicsJson = json['topics'] as List<dynamic>;

    return WikiCategory(
      title: json['title'] as String,
      topics: topicsJson
          .map((entry) => WikiTopic.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}