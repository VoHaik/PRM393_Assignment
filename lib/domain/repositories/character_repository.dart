import '../entities/character.dart';

abstract class CharacterRepository {
  Future<List<Character>> getCharacters();
  Future<Character> getCharacterById(String id);
  Future<List<Character>> getCharactersByContext(String contextId);
}
