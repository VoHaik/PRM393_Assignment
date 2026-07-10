import 'character.dart';

enum ContextCategory { war, politics, culture, science, religion, other }

class ContextCharacter {
  final String id;
  final String name;
  final String? title;
  final String? imageUrl;
  final String? image;
  final CharacterEra? era;

  const ContextCharacter({
    required this.id,
    required this.name,
    this.title,
    this.imageUrl,
    this.image,
    this.era,
  });
}

class HistoricalContext {
  final String id;
  final String name;
  final String? description;
  final CharacterEra era;
  final ContextCategory? category;
  final int? year;
  final int? startYear;
  final int? endYear;
  final bool? isBC;
  final String? period;
  final String? location;
  final String? image;
  final String? videoUrl;
  final List<ContextCharacter> characterIds;
  final bool isPublished;
  final bool isActive;
  final String? yearLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HistoricalContext({
    required this.id,
    required this.name,
    this.description,
    required this.era,
    this.category,
    this.year,
    this.startYear,
    this.endYear,
    this.isBC,
    this.period,
    this.location,
    this.image,
    this.videoUrl,
    required this.characterIds,
    required this.isPublished,
    required this.isActive,
    this.yearLabel,
    required this.createdAt,
    required this.updatedAt,
  });
}
