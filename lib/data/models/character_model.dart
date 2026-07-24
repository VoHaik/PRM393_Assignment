import '../../domain/entities/character.dart';

CharacterEra parseCharacterEra(String? eraStr) {
  switch (eraStr?.toUpperCase()) {
    case 'ANCIENT':
      return CharacterEra.ancient;
    case 'MEDIEVAL':
      return CharacterEra.medieval;
    case 'MODERN':
      return CharacterEra.modern;
    case 'CONTEMPORARY':
    default:
      return CharacterEra.contemporary;
  }
}

String serializeCharacterEra(CharacterEra era) {
  switch (era) {
    case CharacterEra.ancient:
      return 'ANCIENT';
    case CharacterEra.medieval:
      return 'MEDIEVAL';
    case CharacterEra.modern:
      return 'MODERN';
    case CharacterEra.contemporary:
      return 'CONTEMPORARY';
  }
}

class CharacterContextModel extends CharacterContext {
  const CharacterContextModel({required super.id, required super.name});

  factory CharacterContextModel.fromJson(Map<String, dynamic> json) {
    // Backend returns: { "contextId": "uuid-string", "name": "..." }
    // contextId is a plain String (not a nested Map)
    final rawId = json['contextId'];
    final id = rawId is String
        ? rawId
        : rawId is Map
            ? (rawId['id'] as String? ?? rawId['_id'] as String? ?? '')
            : (json['id'] as String? ?? json['_id'] as String? ?? '');
    return CharacterContextModel(
      id: id,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'contextId': id, 'name': name};
}

class CharacterModel extends Character {
  const CharacterModel({
    required super.id,
    required super.name,
    super.title,
    super.background,
    super.imageUrl,
    super.image,
    super.modelUrl,
    super.bornYear,
    super.bornMonth,
    super.bornDay,
    super.isBornBc,
    super.deathYear,
    super.deathMonth,
    super.deathDay,
    super.isDeathBc,
    super.era,
    super.personality,
    required super.isPublished,
    required super.isActive,
    super.contexts,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    // Backend uses "characterId", not "id"
    final id = json['characterId'] as String?
        ?? json['id'] as String?
        ?? json['_id'] as String?
        ?? '';

    // Backend uses "status": "ACTIVE" / "INACTIVE" instead of isActive boolean
    final statusStr = json['status'] as String?;
    final isActive = statusStr != null
        ? statusStr.toUpperCase() == 'ACTIVE'
        : (json['isActive'] as bool? ?? false);

    // Backend uses "contexts": [{ "contextId": "uuid", "name": "..." }]
    final contextsRaw = json['contexts'] as List?;
    final contexts = contextsRaw
        ?.map((c) => CharacterContextModel.fromJson(c as Map<String, dynamic>))
        .toList();

    // Backend uses "createdDate" / "updatedDate" (not createdAt/updatedAt)
    DateTime parseDate(String? key1, String? key2) {
      final v = json[key1] ?? json[key2];
      if (v is String && v.isNotEmpty) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }

    return CharacterModel(
      id: id,
      name: json['name'] as String? ?? '',
      title: json['title'] as String?,
      background: json['background'] as String?,
      imageUrl: json['imageUrl'] as String?,
      image: json['image'] as String?,
      modelUrl: json['modelUrl'] as String?,
      bornYear: json['bornYear'] as int?,
      bornMonth: json['bornMonth'] as int?,
      bornDay: json['bornDay'] as int?,
      isBornBc: json['isBornBc'] as bool?,
      deathYear: json['deathYear'] as int?,
      deathMonth: json['deathMonth'] as int?,
      deathDay: json['deathDay'] as int?,
      isDeathBc: json['isDeathBc'] as bool?,
      era: json['era'] != null ? parseCharacterEra(json['era'] as String) : null,
      personality: json['personality'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      isActive: isActive,
      contexts: contexts,
      createdAt: parseDate('createdDate', 'createdAt'),
      updatedAt: parseDate('updatedDate', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'background': background,
      'imageUrl': imageUrl,
      'image': image,
      'modelUrl': modelUrl,
      'bornYear': bornYear,
      'bornMonth': bornMonth,
      'bornDay': bornDay,
      'isBornBc': isBornBc,
      'deathYear': deathYear,
      'deathMonth': deathMonth,
      'deathDay': deathDay,
      'isDeathBc': isDeathBc,
      'era': era != null ? serializeCharacterEra(era!) : null,
      'personality': personality,
      'isPublished': isPublished,
      'isActive': isActive,
      'contexts': contexts?.map((c) => (c as CharacterContextModel).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
