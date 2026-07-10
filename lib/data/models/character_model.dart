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
    // Check if contextId is nested or flat
    final idMap = json['contextId'];
    if (idMap is Map) {
      return CharacterContextModel(
        id: idMap['id'] as String? ?? idMap['_id'] as String? ?? '',
        name: json['name'] as String? ?? idMap['name'] as String? ?? '',
      );
    }
    return CharacterContextModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contextId': {
        'id': id,
        'name': name,
      },
      'name': name,
    };
  }
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
    return CharacterModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
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
      isActive: json['isActive'] as bool? ?? false,
      contexts: json['contexts'] != null
          ? (json['contexts'] as List)
              .map((c) => CharacterContextModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
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
