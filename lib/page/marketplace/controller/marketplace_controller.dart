import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:finway/service/api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finway/constant/constant.dart';

class MarketplaceController extends GetxController {
  var isLoading = false.obs;
  var products = <Map<String, dynamic>>[].obs;
  var categories = <Map<String, dynamic>>[].obs;
  var selectedTab = 0.obs;
  final List<String> tabs = ["All", "New", "Used"];
  
  // Cart Logic
  var cartItems = <Map<String, dynamic>>[].obs;

  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    // Check if the product already exists in the cart
    final existingItemIndex = cartItems.indexWhere((item) => item['id'] == product['id']);

    if (existingItemIndex != -1) {
      // If it exists, update its quantity
      cartItems[existingItemIndex]['quantity'] = (cartItems[existingItemIndex]['quantity'] ?? 1) + quantity;
      cartItems.refresh(); // Notify listeners that the item has changed
      Get.snackbar(
        "Updated Cart",
        "${product['title']} quantity updated to ${cartItems[existingItemIndex]['quantity']}.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeData.primary200,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } else {
      // If it doesn't exist, add it with the specified quantity
      final productWithQuantity = Map<String, dynamic>.from(product);
      productWithQuantity['quantity'] = quantity;
      cartItems.add(productWithQuantity);
      Get.snackbar(
        "Added to Cart",
        "${product['title']} has been added.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeData.primary200,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } 
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item['id'] == productId);
  }

  void updateQuantity(String productId, int delta) {
    final index = cartItems.indexWhere((item) => item['id'] == productId);
    if (index != -1) {
      int newQty = (cartItems[index]['quantity'] ?? 1) + delta;
      if (newQty <= 0) {
        cartItems.removeAt(index);
      } else {
        cartItems[index]['quantity'] = newQty;
        cartItems.refresh();
      }
    }
  }

  double get cartSubtotal {
    double total = 0;
    for (var item in cartItems) {
      final price = item['price'].toString();
      final priceStr = price.replaceAll('₹', '').replaceAll('\$', '').replaceAll(',', '');
      final quantity = item['quantity'] ?? 1;
      total += (double.tryParse(priceStr) ?? 0) * quantity;
    }
    return total;
  }

  var banners = <Map<String, dynamic>>[].obs;
  var selectedCategory = "".obs;
  var selectedSubCategory = "".obs;
  var rawCategories = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMarketplaceData();
    fetchMyMarketplaceProducts();
  }

  Future<void> fetchMarketplaceData() async {
    isLoading.value = true;

    // Local Dummy Fallbacks
    final dummyBanners = [
      {
        'title': '#FASHION DAY',
        'discount': '80% OFF',
        'subtitle': 'Discover fashion that suits to your style',
        'image': 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e12?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'title': '#SUMMER VIBES',
        'discount': '50% OFF',
        'subtitle': 'Hot deals on cool clothes',
        'image': 'https://images.unsplash.com/photo-1523381210434-271b8be1f52b?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'title': '#GADGET WEEK',
        'discount': '40% OFF',
        'subtitle': 'Latest electronics at best prices',
        'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'title': '#HOME COMFORT',
        'discount': '30% OFF',
        'subtitle': 'Premium furniture and decor',
        'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=2070',
      }
    ];

    final dummyCategories = [
      {'name': 'Electronics', 'icon': 'devices', 'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&q=80&w=2070', 'subCategories': ['All', 'Mobiles', 'Laptops', 'Audio']},
      {'name': 'Clothing', 'icon': 'checkroom', 'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&q=80&w=2071', 'subCategories': ['All', 'Men', 'Women', 'Kids']},
      {'name': 'Beauty', 'icon': 'face', 'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc4033c8?auto=format&fit=crop&q=80&w=2070', 'subCategories': ['All', 'Skincare', 'Makeup']},
      {'name': 'Furniture', 'icon': 'chair', 'image': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=2070', 'subCategories': ['All', 'Living Room', 'Bedroom']},
      {'name': 'Books', 'icon': 'menu_book', 'image': 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&q=80&w=2070', 'subCategories': ['All', 'Fiction', 'Academic']},
    ];

    final dummyProducts = [
      {
        'id': '1',
        'title': "Essentials Men's Short-Sleeve Crewneck T-Shirt",
        'subtitle': "Shirt",
        'price': '₹12.00',
        'rating': '4.9',
        'reviews': '2356',
        'sold': '2.9k + Sold',
        'brand': 'ChArmkpR',
        'color': 'Aprikot',
        'condition': 'New',
        'mainCategory': 'Clothing',
        'subCategory': 'Men',
        'images': [
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=2080',
          'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?auto=format&fit=crop&q=80&w=2080',
        ],
        'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=2080'
      },
      {
        'id': '2',
        'title': "iPhone 13 Pro Max - Space Grey",
        'subtitle': "Smartphone",
        'price': '₹699.00',
        'rating': '4.8',
        'reviews': '152',
        'sold': '45 Sold',
        'brand': 'Apple',
        'color': 'Space Grey',
        'condition': 'Used',
        'mainCategory': 'Electronics',
        'subCategory': 'Mobiles',
        'images': [
          'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?auto=format&fit=crop&q=80&w=2080',
        ],
        'image': 'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?auto=format&fit=crop&q=80&w=2080'
      },
      {
        'id': '3',
        'title': "MacBook M2 Air (2022) - Silver",
        'subtitle': "Laptop",
        'price': '₹999.00',
        'rating': '5.0',
        'reviews': '85',
        'sold': '12 Sold',
        'brand': 'Apple',
        'color': 'Silver',
        'condition': 'New',
        'mainCategory': 'Electronics',
        'subCategory': 'Laptops',
        'images': [
          'https://images.unsplash.com/photo-1611186871348-b1ec696e52c9?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&q=80&w=2070',
      },
      {
        'id': '4',
        'title': "Nike Air Jordan 1 Retro",
        'subtitle': "Shoes",
        'price': '₹180.00',
        'rating': '4.9',
        'reviews': '3400',
        'sold': '1.5k + Sold',
        'brand': 'Nike',
        'color': 'Red/White',
        'condition': 'New',
        'mainCategory': 'Clothing',
        'subCategory': 'Men',
        'images': [
          'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&q=80&w=2080',
        ],
        'image': 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&q=80&w=2080'
      },
      {
        'id': '5',
        'title': "Used Gaming Console - PS4 Slim",
        'subtitle': "Console",
        'price': '₹150.00',
        'rating': '4.5',
        'reviews': '890',
        'sold': '200+ Sold',
        'brand': 'Sony',
        'color': 'Black',
        'condition': 'Used',
        'mainCategory': 'Electronics',
        'subCategory': 'Audio',
        'images': [
          'https://images.unsplash.com/photo-1486401899868-0e435ed85128?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1486401899868-0e435ed85128?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '6',
        'title': "Essentials Regular-Fit Long-Sleeve Oxford...",
        'subtitle': "Shirt",
        'price': '₹22.00',
        'rating': '4.9',
        'reviews': '1520',
        'sold': '1.2k + Sold',
        'brand': 'Oxford',
        'color': 'Blue',
        'condition': 'Used',
        'mainCategory': 'Clothing',
        'subCategory': 'Men',
        'images': [
          'https://images.unsplash.com/photo-1598033129183-c4f50c717658?auto=format&fit=crop&q=80&w=2071',
        ],
        'image': 'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?auto=format&fit=crop&q=80&w=2071',
      },
      {
        'id': '7',
        'title': "Modern Hoodie with Contrast Pocket",
        'subtitle': "Hoodie",
        'price': '₹18.00',
        'rating': '4.8',
        'reviews': '850',
        'sold': '500+ Sold',
        'brand': 'UrbanFit',
        'color': 'Beige/Black',
        'condition': 'New',
        'mainCategory': 'Clothing',
        'subCategory': 'Women',
        'images': [
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '8',
        'title': "Vintage Denim Jacket - Limited Edition",
        'subtitle': "Jacket",
        'price': '₹45.00',
        'rating': '4.7',
        'reviews': '420',
        'sold': '100+ Sold',
        'brand': 'LeviVibe',
        'color': 'Indigo',
        'condition': 'Used',
        'mainCategory': 'Clothing',
        'subCategory': 'Women',
        'images': [
          'https://images.unsplash.com/photo-1544441893-675973e31985?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1544441893-675973e31985?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '9',
        'title': "Eco-Friendly Cotton Summer Dress",
        'subtitle': "Dress",
        'price': '₹35.00',
        'rating': '4.9',
        'reviews': '120',
        'sold': '300+ Sold',
        'brand': 'GreenWear',
        'color': 'Sage Green',
        'condition': 'New',
        'mainCategory': 'Clothing',
        'subCategory': 'Kids',
        'images': [
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '10',
        'title': "Luxury Sofa Set - 3 Seater",
        'subtitle': "Sofa",
        'price': '₹1200.00',
        'rating': '4.9',
        'reviews': '50',
        'sold': '10+ Sold',
        'brand': 'ComfortHome',
        'color': 'Grey',
        'condition': 'New',
        'mainCategory': 'Furniture',
        'subCategory': 'Living Room',
        'images': [
          'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '11',
        'title': "Classic Wooden Dining Table",
        'subtitle': "Table",
        'price': '₹450.00',
        'rating': '4.7',
        'reviews': '80',
        'sold': '25+ Sold',
        'brand': 'WoodCraft',
        'color': 'Brown',
        'condition': 'Used',
        'mainCategory': 'Furniture',
        'subCategory': 'Living Room',
        'images': [
          'https://images.unsplash.com/photo-1519947292023-2675b77907c8?auto=format&fit=crop&q=80&w=2070',
        ],
        'image': 'https://images.unsplash.com/photo-1519947292023-2675b77907c8?auto=format&fit=crop&q=80&w=2070'
      },
      {
        'id': '12',
        'title': "Bestseller Novel - 'The Midnight Library'",
        'subtitle': "Book",
        'price': '₹15.00',
        'rating': '4.9',
        'reviews': '5000',
        'sold': '10k+ Sold',
        'brand': 'Penguin Books',
        'color': 'N/A',
        'condition': 'New',
        'mainCategory': 'Books',
        'subCategory': 'Fiction',
        'images': [
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd87?auto=format&fit=crop&q=80&w=1974',
        ],
        'image': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd87?auto=format&fit=crop&q=80&w=1974'
      }
    ];

    try {
      // 1. Fetch Categories
      final catResponse = await http.get(Uri.parse(API.getMarketplaceCategories), headers: API.header);
      // 2. Fetch Products
      final prodResponse = await http.get(Uri.parse(API.getMarketplaceProducts), headers: API.header);

      if (catResponse.statusCode == 200 && prodResponse.statusCode == 200) {
        final catJson = json.decode(catResponse.body);
        final prodJson = json.decode(prodResponse.body);

        if (catJson['success'] == 'Success' && prodJson['success'] == 'Success') {
          // Store Raw Categories for ID lookup
          final List<dynamic> catList = catJson['data'] ?? [];
          rawCategories.value = List<Map<String, dynamic>>.from(catList);

          // Map Categories
          final mappedCategories = catList.map((cat) {
            final List<dynamic> subList = cat['subcategories'] ?? [];
            final List<String> subNames = ['All'] + subList.map((s) => (s['name'] ?? '').toString()).toList();
            return {
              'name': cat['name'] ?? '',
              'icon': cat['icon_name'] ?? 'category',
              'image': cat['image_path'] ?? '',
              'subCategories': subNames,
            };
          }).toList();

          // Map Products
          final List<dynamic> prodList = prodJson['data'] ?? [];
          final mappedProducts = prodList.map((prod) {
            final List<dynamic> imgList = prod['images'] ?? [];
            final List<String> imageUrls = imgList.map((img) => (img['image_path'] ?? '').toString()).toList();
            final String primaryImage = imageUrls.isNotEmpty ? imageUrls.first : '';

            return {
              'id': prod['id'].toString(),
              'title': prod['title'] ?? '',
              'description': prod['description'] ?? '',
              'price': '₹${prod['price']}',
              'condition': prod['condition'] ?? 'New',
              'mainCategory': prod['category']?['name'] ?? '',
              'subCategory': prod['subcategory']?['name'] ?? '',
              'image': primaryImage,
              'images': imageUrls,
              'rating': '4.8',
              'reviews': '12',
              'sold': '5+ Sold',
              'brand': 'Generic',
              'color': 'N/A',
            };
          }).toList();

          banners.value = dummyBanners; // Banners are visual/promotional, fallback is best
          categories.value = mappedCategories;
          products.value = mappedProducts;
          isLoading.value = false;
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching API data: $e");
    }

    // Fallback to local dummy data if API fails
    banners.value = dummyBanners;
    categories.value = dummyCategories;
    products.value = dummyProducts;
    isLoading.value = false;
  }

  // ID Lookups
  int? getCategoryId(String name) {
    final cat = rawCategories.firstWhereOrNull((c) => c['name'] == name);
    return cat?['id'];
  }

  int? getSubCategoryId(String catName, String subName) {
    final cat = rawCategories.firstWhereOrNull((c) => c['name'] == catName);
    if (cat == null) return null;
    final List<dynamic> subs = cat['subcategories'] ?? [];
    final sub = subs.firstWhereOrNull((s) => s['name'] == subName);
    return sub?['id'];
  }

  // User Products Fetching
  var myProducts = <Map<String, dynamic>>[].obs;
  var isMyProductsLoading = false.obs;

  Future<void> fetchMyMarketplaceProducts() async {
    isMyProductsLoading.value = true;
    try {
      final response = await http.get(Uri.parse(API.getMyMarketplaceProducts), headers: API.header);
      if (response.statusCode == 200) {
        final jsonDec = json.decode(response.body);
        if (jsonDec['success'] == 'Success') {
          final List<dynamic> prodList = jsonDec['data'] ?? [];
          final mappedProducts = prodList.map((prod) {
            final List<dynamic> imgList = prod['images'] ?? [];
            final List<String> imageUrls = imgList.map((img) => (img['image_path'] ?? '').toString()).toList();
            final String primaryImage = imageUrls.isNotEmpty ? imageUrls.first : '';

            return {
              'id': prod['id'].toString(),
              'title': prod['title'] ?? '',
              'description': prod['description'] ?? '',
              'price': '₹${prod['price']}',
              'condition': prod['condition'] ?? 'New',
              'status': prod['status'] ?? 'pending_verification',
              'mainCategory': prod['category']?['name'] ?? '',
              'subCategory': prod['subcategory']?['name'] ?? '',
              'image': primaryImage,
              'images': imageUrls,
              'progress': prod['progress'] ?? 0,
            };
          }).toList();
          myProducts.value = mappedProducts;
          isMyProductsLoading.value = false;
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching my products: $e");
    }
    isMyProductsLoading.value = false;
  }

  // Upload/Post Product Listing
  Future<bool> postProduct({
    required String title,
    required String description,
    required double price,
    required int stockQuantity,
    required String condition,
    required String deliveryType,
    required String categoryName,
    required String subCategoryName,
    required List<String> imagePaths,
  }) async {
    try {

      // 1. Upload images via server middleware (server proxies to ImageKit)
      final List<String> uploadedUrls = [];
      for (String path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) {
          throw Exception("File does not exist: $path");
        }
        
        try {
          final uploadUri = Uri.parse(API.uploadMarketplaceImage);
          final uploadRequest = http.MultipartRequest('POST', uploadUri);
          
          // Add authentication headers
          API.header.forEach((key, val) {
            uploadRequest.headers[key] = val;
          });
          // Remove content-type for multipart (http package sets it automatically)
          uploadRequest.headers.remove('content-type');
          
          uploadRequest.fields['folder'] = '/marketplace/products';
          uploadRequest.files.add(await http.MultipartFile.fromPath('image', file.path));
          
          final uploadResponse = await uploadRequest.send();
          final uploadBody = await uploadResponse.stream.bytesToString();
          final uploadJson = json.decode(uploadBody);
          
          if (uploadResponse.statusCode == 200 && uploadJson['success'] == 'Success') {
            uploadedUrls.add(uploadJson['url']);
          } else {
            throw Exception(uploadJson['error'] ?? "Server upload failed (${uploadResponse.statusCode})");
          }
        } catch (e) {
          debugPrint("Server image upload failed: $e");
          rethrow;
        }
      }

      final uri = Uri.parse(API.createMarketplaceProduct);
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication headers
      API.header.forEach((key, val) {
        request.headers[key] = val;
      });

      // Find Category ID & SubCategory ID
      final catId = getCategoryId(categoryName);
      final subCatId = getSubCategoryId(categoryName, subCategoryName);

      if (catId == null) {
        Get.snackbar("Error", "Selected category is invalid.", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      request.fields['category_id'] = catId.toString();
      if (subCatId != null) {
        request.fields['subcategory_id'] = subCatId.toString();
      }
      request.fields['condition'] = condition;
      request.fields['delivery_type'] = deliveryType;

      // Add server-uploaded image URLs
      for (int i = 0; i < uploadedUrls.length; i++) {
        request.fields['image_urls[$i]'] = uploadedUrls[i];
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final respBody = await response.stream.bytesToString();
        final jsonDec = json.decode(respBody);
        if (jsonDec['success'] == 'Success') {
          // Refresh products lists
          fetchMarketplaceData();
          fetchMyMarketplaceProducts();
          return true;
        } else {
          Get.snackbar("Error", jsonDec['error'] ?? "Failed to create product listing.", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        final respBody = await response.stream.bytesToString();
        final jsonDec = json.decode(respBody);
        Get.snackbar("Error", jsonDec['error'] ?? "Server error (${response.statusCode})", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint("Error posting product: $e");
      Get.snackbar("Error", e.toString().replaceAll("Exception: ", ""), backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> list = products.toList();

    // Filter by Category
    if (selectedCategory.value.isNotEmpty) {
      list = list.where((p) => p['mainCategory']?.toString() == selectedCategory.value).toList();
    }

    // Filter by SubCategory
    if (selectedSubCategory.value.isNotEmpty && selectedSubCategory.value != "All") {
      list = list.where((p) => p['subCategory']?.toString() == selectedSubCategory.value).toList();
    }

    // Filter by Tab (New/Used)
    if (selectedTab.value == 1) {
      list = list.where((p) => (p['condition']?.toString() ?? "") == "New").toList();
    } else if (selectedTab.value == 2) {
      list = list.where((p) => (p['condition']?.toString() ?? "") == "Used").toList();
    }

    return list;
  }
}

