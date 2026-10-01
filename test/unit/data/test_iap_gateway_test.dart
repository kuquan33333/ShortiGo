import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/iap/test_iap_gateway.dart';
import 'package:shortigo/data/iap/test_vip_entitlement_store.dart';
import 'package:shortigo/data/local/shortigo_database.dart';

void main() {
  late ShortigoDatabase database;
  late String? accountId;

  setUp(() {
    database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    accountId = 'account-a';
  });

  tearDown(() => database.close());

  TestIapGateway gatewayForCurrentAccount() {
    return TestIapGateway(
      TestVipEntitlementStore(database: database, accountId: () => accountId),
    );
  }

  test('offers local monthly and yearly test packages', () async {
    final offerings = await gatewayForCurrentAccount().getOfferings();
    final packageIds = offerings
        .expand((offering) => offering.packages)
        .map((package) => package.identifier)
        .toList();

    expect(
      packageIds,
      containsAll(<String>['vip_monthly_test', 'vip_yearly_test']),
    );
    expect(packageIds, everyElement(contains('test')));
  });

  test(
    'purchase persists, restore works, and reset clears local VIP',
    () async {
      final gateway = gatewayForCurrentAccount();

      expect(await gateway.purchase('vip_monthly_test'), isTrue);
      expect(await gatewayForCurrentAccount().restorePurchases(), isTrue);

      final recreatedGateway = gatewayForCurrentAccount();
      expect(await recreatedGateway.restorePurchases(), isTrue);
      await recreatedGateway.store.reset();
      expect(await gatewayForCurrentAccount().restorePurchases(), isFalse);
    },
  );

  test('test entitlement is isolated for accounts and guest', () async {
    expect(
      await gatewayForCurrentAccount().purchase('vip_yearly_test'),
      isTrue,
    );

    accountId = 'account-b';
    expect(await gatewayForCurrentAccount().restorePurchases(), isFalse);

    accountId = null;
    expect(await gatewayForCurrentAccount().restorePurchases(), isFalse);

    accountId = 'account-a';
    expect(await gatewayForCurrentAccount().restorePurchases(), isTrue);
  });
}
