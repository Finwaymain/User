import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/card_data.dart';
import '../data/cards_data.dart';

class MedicalCardController extends GetxController {
  var availableCards = <CardData>[].obs;
  var purchasedCards = <PurchasedCard>[].obs;
  var selectedCardIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  void loadCards() {
    availableCards.value = cardsJsonData
        .map((json) => CardData.fromJson(json))
        .toList();
  }

  void purchaseCard(CardData card) {
    final newCard = PurchasedCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardData: card,
      cardNumber: card.cardDesign.cardNumber.replaceAll(
        'XX',
        (DateTime.now().millisecond % 100).toString().padLeft(2, '0'),
      ),
      balance: card.limit,
      purchaseDate: DateTime.now(),
    );
    purchasedCards.add(newCard);

    Get.snackbar(
      'Success',
      '${card.type} successfully purchased!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 2),
    );
  }

  bool isPurchased(int cardId) {
    return purchasedCards.any((c) => c.cardData.id == cardId);
  }

  void submitClaim(PurchasedCard card, ClaimRecord claim) {
    final index = purchasedCards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      purchasedCards[index].addClaim(claim);
      purchasedCards.refresh();
    }
  }

  PurchasedCard? getCardById(String id) {
    try {
      return purchasedCards.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
