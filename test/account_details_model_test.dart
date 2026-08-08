import 'package:finway/page/features/SmartValue/AccountDetails/model/account_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AccountData parses string id from API payload', () {
    final data = AccountData.fromJson({
      'id': '24',
      'ac_no': 'AC123456',
      'nom': 'Kumar',
      'prenom': 'Aditya',
      'phone': '9876543210',
      'amount': '150.50',
      'earn_amount': '25',
      'is_verified': '1',
      'statut': 'yes',
    });

    expect(data.id, 24);
    expect(data.acNo, 'AC123456');
    expect(data.amount, '150.50');
    expect(data.isVerified, 1);
  });
}
