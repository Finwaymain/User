import 'package:finway/page/wallet/utils/wallet_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet formatter masks account numbers', () {
    expect(maskWalletAccount('9876543210'), '**** **** **** 3210');
  });
}
