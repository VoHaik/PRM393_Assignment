import '../entities/historical_context.dart';

abstract class HistoricalContextRepository {
  Future<List<HistoricalContext>> getContexts();
  Future<HistoricalContext> getContextById(String id);
}
