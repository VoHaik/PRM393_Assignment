import '../../domain/entities/historical_context.dart';
import 'character_model.dart';

ContextCategory parseContextCategory(String? catStr) {
  switch (catStr?.toUpperCase()) {
    case 'WAR':
      return ContextCategory.war;
    case 'POLITICS':
      return ContextCategory.politics;
    case 'CULTURE':
      return ContextCategory.culture;
    case 'SCIENCE':
      return ContextCategory.science;
    case 'RELIGION':
      return ContextCategory.religion;
    case 'OTHER':
    default:
      return ContextCategory.other;
  }
}

String serializeContextCategory(ContextCategory cat) {
  switch (cat) {
    case ContextCategory.war:
      return 'WAR';
    case ContextCategory.politics:
      return 'POLITICS';
    case ContextCategory.culture:
      return 'CULTURE';
    case ContextCategory.science:
      return 'SCIENCE';
    case ContextCategory.religion:
      return 'RELIGION';
    case ContextCategory.other:
      return 'OTHER';
  }
}

class ContextCharacterModel extends ContextCharacter {
  const ContextCharacterModel({
    required super.id,
    required super.name,
    super.title,
    super.imageUrl,
    super.image,
    super.era,
  });

  factory ContextCharacterModel.fromJson(Map<String, dynamic> json) {
    return ContextCharacterModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String?,
      imageUrl: json['imageUrl'] as String?,
      image: json['image'] as String?,
      era: json['era'] != null ? parseCharacterEra(json['era'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'imageUrl': imageUrl,
      'image': image,
      'era': era != null ? serializeCharacterEra(era!) : null,
    };
  }
}

class HistoricalContextModel extends HistoricalContext {
  const HistoricalContextModel({
    required super.id,
    required super.name,
    super.description,
    required super.era,
    super.category,
    super.year,
    super.startYear,
    super.endYear,
    super.isBC,
    super.period,
    super.location,
    super.image,
    super.videoUrl,
    required super.characterIds,
    required super.isPublished,
    required super.isActive,
    super.yearLabel,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HistoricalContextModel.fromJson(Map<String, dynamic> json) {
    // Backend uses "contextId" not "id"
    final id = json['contextId'] as String?
        ?? json['id'] as String?
        ?? json['_id'] as String?
        ?? '';

    // Backend uses "status": "ACTIVE" not isActive boolean
    final statusStr = json['status'] as String?;
    final isActive = statusStr != null
        ? statusStr.toUpperCase() == 'ACTIVE'
        : (json['isActive'] as bool? ?? false);

    // Backend uses "imageUrl" for context images (not "image")
    final image = json['imageUrl'] as String? ?? json['image'] as String?;

    // Backend uses "createdDate" / "updatedDate"
    DateTime parseDate(String key1, String key2) {
      final v = json[key1] ?? json[key2];
      if (v is String && v.isNotEmpty) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }

    return HistoricalContextModel(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      era: parseCharacterEra(json['era'] as String?),
      category: json['category'] != null
          ? parseContextCategory(json['category'] as String)
          : null,
      year: json['year'] as int?,
      startYear: json['startYear'] as int?,
      endYear: json['endYear'] as int?,
      isBC: json['isBC'] as bool?,
      period: json['period'] as String?,
      location: json['location'] as String?,
      image: image,
      videoUrl: json['videoUrl'] as String?,
      characterIds: json['characterIds'] != null
          ? (json['characterIds'] as List)
              .map((c) => ContextCharacterModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      isPublished: json['isPublished'] as bool? ?? false,
      isActive: isActive,
      yearLabel: json['yearLabel'] as String?,
      createdAt: parseDate('createdDate', 'createdAt'),
      updatedAt: parseDate('updatedDate', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'era': serializeCharacterEra(era),
      'category': category != null ? serializeContextCategory(category!) : null,
      'year': year,
      'startYear': startYear,
      'endYear': endYear,
      'isBC': isBC,
      'period': period,
      'location': location,
      'image': image,
      'videoUrl': videoUrl,
      'characterIds': characterIds
          .map((c) => (c as ContextCharacterModel).toJson())
          .toList(),
      'isPublished': isPublished,
      'isActive': isActive,
      'yearLabel': yearLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
