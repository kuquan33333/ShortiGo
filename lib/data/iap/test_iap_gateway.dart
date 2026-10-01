import '../../domain/interfaces/iap_gateway.dart';
import 'test_vip_entitlement_store.dart';

class TestIapGateway implements IapGateway {
  TestIapGateway(this.store);

  final TestVipEntitlementStore store;

  static final _offerings = <IapOffering>[
    IapOffering(
      identifier: 'shortigo_test_vip',
      packages: [
        IapPackage(identifier: 'vip_monthly_test', priceString: 'TEST'),
        IapPackage(identifier: 'vip_yearly_test', priceString: 'TEST'),
      ],
    ),
  ];

  @override
  Future<void> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {}

  @override
  Future<List<IapOffering>> getOfferings() async {
    return _offerings
        .map(
          (offering) => IapOffering(
            identifier: offering.identifier,
            packages: offering.packages
                .map(
                  (package) => IapPackage(
                    identifier: package.identifier,
                    priceString: package.priceString,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<bool> purchase(String packageIdentifier) async {
    final knownPackage = _offerings
        .expand((offering) => offering.packages)
        .any((package) => package.identifier == packageIdentifier);
    if (!knownPackage) {
      return false;
    }
    await store.activate(packageIdentifier);
    return true;
  }

  @override
  Future<bool> restorePurchases() => store.isActive();
}
