import 'package:finway/page/wallet/utils/wallet_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskWalletAccount', () {
    test('masks account numbers keeping last four digits', () {
      expect(maskWalletAccount('1234567890'), '**** **** **** 7890');
    });

    test('returns placeholder when empty', () {
      expect(maskWalletAccount(''), '**** **** **** ****');
    });

    test('returns short values unchanged', () {
      expect(maskWalletAccount('1234'), '1234');
    });
  });
}
