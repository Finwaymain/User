/// Fiinway User App — Food module entry (Phase 2)
/// Wire this from home/services grid: FoodOrderingScreen()
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodOrderingScreen extends StatefulWidget {
  const FoodOrderingScreen({super.key});

  @override
  State<FoodOrderingScreen> createState() => _FoodOrderingScreenState();
}

class _FoodOrderingScreenState extends State<FoodOrderingScreen> {
  final search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiinway Food')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search restaurants or dishes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nearby restaurants (15 km)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.store)),
            title: Text('Connect API: GET /api/v1/food/customer/nearby'),
            subtitle: Text('Pass lat/lng • filter open restaurants'),
          ),
          const Divider(),
          const Text('Flow', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('1. Nearby list → Restaurant menu\n2. Cart → Address → Wallet/UPI/COD\n3. Live track → Rate → Reorder'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Get.snackbar('Food', 'Hook CustomerFoodController APIs from Fiinway-main'),
            child: const Text('Browse Food'),
          ),
        ],
      ),
    );
  }
}
