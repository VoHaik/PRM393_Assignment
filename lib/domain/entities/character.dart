enum CharacterEra { ancient, medieval, modern, contemporary }

class CharacterContext {
  final String id;
  final String name;

  const CharacterContext({
    required this.id,
    required this.name,
  });
}

class Character {
  final String id;
  final String name;
  final String? title;
  final String? background;
  final String? imageUrl;
  final String? image;
  final String? modelUrl;
  final int? bornYear;
  final int? bornMonth;
  final int? bornDay;
  final bool? isBornBc;
  final int? deathYear;
  final int? deathMonth;
  final int? deathDay;
  final bool? isDeathBc;
  final CharacterEra? era;
  final String? personality;
  final bool isPublished;
  final bool isActive;
  final List<CharacterContext>? contexts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Character({
    required this.id,
    required this.name,
    this.title,
    this.background,
    this.imageUrl,
    this.image,
    this.modelUrl,
    this.bornYear,
    this.bornMonth,
    this.bornDay,
    this.isBornBc,
    this.deathYear,
    this.deathMonth,
    this.deathDay,
    this.isDeathBc,
    this.era,
    this.personality,
    required this.isPublished,
    required this.isActive,
    this.contexts,
    required this.createdAt,
    required this.updatedAt,
  });
}
