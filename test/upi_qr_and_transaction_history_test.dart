import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/model/transaction_model.dart';
import 'package:finway/page/wallet/utils/transaction_history_display.dart';

import 'package:finway/page/features/SmartValue/MyQR/controller/qr_controller.dart';

void main() {
  group('QRController UPI Sanitization & Formatting', () {
    test('converts raw 12-digit account number into valid NPCI UPI intent URI', () {
      final upiUri = QRController.sanitizeUpiQr('708012345678', name: 'Rahul Sharma');
      expect(upiUri, startsWith('upi://pay?'));
      expect(upiUri, contains('pa=fiinway782717.rzp@rxairtel'));
      expect(upiUri, contains('tr=708012345678'));
      expect(upiUri, contains('tn=Fiinway%20Wallet%20708012345678'));
      expect(upiUri, contains('mc=5817'));
      expect(upiUri, contains('mode=19'));
      expect(upiUri, contains('cu=INR'));
    });

    test('preserves already-formatted UPI URI', () {
      const existingUri = 'upi://pay?pa=custom@razorpay&pn=Fiinway&tr=708012345678&cu=INR';
      final result = QRController.sanitizeUpiQr(existingUri, acNo: '708012345678');
      expect(result, existingUri);
    });

    test('generates UPI URI when rawData is null using user acNo', () {
      final upiUri = QRController.sanitizeUpiQr(null, acNo: '708099887766', name: 'Priya');
      expect(upiUri, startsWith('upi://pay?'));
      expect(upiUri, contains('tr=708099887766'));
      expect(upiUri, contains('pn=Fiinway%20-%20Priya'));
    });
  });

  group('User Model upiQrData serialization', () {
    test('User.fromJson parses upi_qr_data correctly', () {
      final json = {
        'id': '10',
        'ac_no': '708012345678',
        'nom': 'Sharma',
        'prenom': 'Rahul',
        'upi_qr_data': 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Rahul&tr=708012345678&cu=INR',
      };

      final user = User.fromJson(json);

      expect(user.acNo, '708012345678');
      expect(user.upiQrData, 'upi://pay?pa=fiinway@icici&pn=Fiinway+-+Rahul&tr=708012345678&cu=INR');
    });

    test('User.toJson preserves upi_qr_data correctly', () {
      final user = User(
        id: '10',
        acNo: '708012345678',
        nom: 'Sharma',
        prenom: 'Rahul',
        upiQrData: 'upi://pay?pa=fiinway@icici&pn=Fiinway&tr=708012345678&cu=INR',
      );

      final json = user.toJson();

      expect(json['ac_no'], '708012345678');
      expect(json['upi_qr_data'], 'upi://pay?pa=fiinway@icici&pn=Fiinway&tr=708012345678&cu=INR');
    });

    test('User.fromJson handles null upi_qr_data safely', () {
      final json = {
        'id': '11',
        'ac_no': '708087654321',
      };

      final user = User.fromJson(json);

      expect(user.acNo, '708087654321');
      expect(user.upiQrData, isNull);
    });
  });

  group('TransactionHistoryDisplay UPI formatting', () {
    test('renders UPI icon, sky-blue color, and container styling for UPI transaction', () {
      final txn = TransactionData(
        id: '0000105',
        amount: '500.00',
        paymentMethod: 'UPI',
        categoryTitle: 'UPI Payment Received',
        counterpartyName: 'From Sagar',
        iconType: 'upi',
        statusLabel: 'Paid',
        deductionType: '1',
      );

      expect(TransactionHistoryDisplay.categoryTitle(txn), 'UPI Payment Received');
      expect(TransactionHistoryDisplay.counterpartyName(txn), 'From Sagar');
      expect(TransactionHistoryDisplay.iconType(txn), 'upi');
      expect(TransactionHistoryDisplay.iconFor('upi'), Icons.qr_code_2_rounded);
      expect(TransactionHistoryDisplay.iconColorFor('upi'), const Color(0xFF0284C7));
      expect(TransactionHistoryDisplay.iconBackgroundFor('upi'), const Color(0xFFE0F2FE));
      expect(TransactionHistoryDisplay.statusLabel(txn), 'Paid');
      expect(TransactionHistoryDisplay.statusBackground('Paid'), const Color(0xFFDCFCE7));
    });

    test('fallback logic handles raw UPI transaction without pre-enriched fields', () {
      final txn = TransactionData(
        id: '0000106',
        amount: '200.00',
        paymentMethod: 'UPI',
        description: 'Payment from user B via UPI',
        paymentStatus: 'success',
        deductionType: '1',
      );

      expect(TransactionHistoryDisplay.categoryTitle(txn), 'Wallet Top-up');
      expect(TransactionHistoryDisplay.statusLabel(txn), 'Paid');
      expect(TransactionHistoryDisplay.counterpartyName(txn), 'user B');
    });
  });
}
