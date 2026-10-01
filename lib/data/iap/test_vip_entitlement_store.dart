import '../local/shortigo_database.dart';

typedef TestVipAccountId = String? Function();

class TestVipEntitlementStore {
  TestVipEntitlementStore({required this.database, required this.accountId});

  final ShortigoDatabase database;
  final TestVipAccountId accountId;

  String get _key {
    final id = accountId()?.trim();
    return 'vipTest:${id == null || id.isEmpty ? 'guest' : id}';
  }

  Future<bool> isActive() async {
    final value = await database.readSetting(_key);
    return value != null && value.isNotEmpty;
  }

  Future<void> activate(String packageIdentifier) {
    return database.writeSetting(_key, packageIdentifier);
  }

  Future<void> reset() => database.deleteSetting(_key);
}
