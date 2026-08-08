class Flashcard {
  final String id;
  final String front;
  final String back;
  final int simPage;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.simPage,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      simPage: json['simPage'] as int,
    );
  }
}

class Topic {
  final String id;
  final String title;
  final List<Flashcard> cards;

  const Topic({required this.id, required this.title, required this.cards});

  factory Topic.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['cards'] as List<dynamic>;
    return Topic(
      id: json['id'] as String,
      title: json['title'] as String,
      cards: cardsJson
          .map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Deck {
  final String id;
  final String title;
  final String simEdition;
  final String disclaimer;
  final List<Topic> topics;

  const Deck({
    required this.id,
    required this.title,
    required this.simEdition,
    required this.disclaimer,
    required this.topics,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    final topicsJson = json['topics'] as List<dynamic>;
    return Deck(
      id: json['id'] as String,
      title: json['title'] as String,
      simEdition: json['simEdition'] as String,
      disclaimer: json['disclaimer'] as String,
      topics: topicsJson
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  List<Flashcard> get allCards =>
      topics.expand((topic) => topic.cards).toList();
}
