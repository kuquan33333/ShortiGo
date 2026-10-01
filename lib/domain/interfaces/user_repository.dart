import '../../domain/entities/user.dart';
import '../entities/watch_history_entry.dart';
import '../entities/transaction.dart';

abstract class UserRepository {
  Future<AppUser> byId(String id);
  Stream<AppUser> watch(String id);
  Future<void> createIfMissing(AppUser user);
  Future<void> setDailyCheckIn(String userId, DateTime at);
  Future<void> saveSeries({required String userId, required String seriesId});
  Future<void> unsaveSeries({required String userId, required String seriesId});
  Future<void> deletePersonalData(String userId);
  Future<List<WatchHistoryEntry>> readWatchHistory(String userId);
  Future<void> saveWatchHistory(String userId, WatchHistoryEntry entry);
  Future<void> grantDemoBonus({
    required String userId,
    required TxType type,
    required int amount,
    required String reference,
    DateTime? dailyCheckInAt,
  });
}
