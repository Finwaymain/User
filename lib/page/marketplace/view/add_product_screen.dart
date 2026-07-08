import 'dart:io';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controller/marketplace_controller.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _selectedCondition = "New";
  String _deliveryType = "Local"; 
  final MarketplaceController _controller = Get.find<MarketplaceController>();

  final List<String> _stepTitles = ["Category", "Sub-Cat", "Details", "Photos"];

  // Form Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: "1");
  final TextEditingController _descController = TextEditingController();

  final List<String> _localImagePaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _localImagePaths.add(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      Get.snackbar("Error", "Failed to pick image", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _submitProduct(bool isDark) async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final priceStr = _priceController.text.trim();
    final stockStr = _stockController.text.trim();

    if (title.isEmpty) {
      Get.snackbar("Required", "Please enter a product title", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (priceStr.isEmpty || double.tryParse(priceStr) == null || double.parse(priceStr) < 0) {
      Get.snackbar("Required", "Please enter a valid price", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (stockStr.isEmpty || int.tryParse(stockStr) == null || int.parse(stockStr) < 1) {
      Get.snackbar("Required", "Please enter a valid stock quantity (min 1)", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (desc.isEmpty) {
      Get.snackbar("Required", "Please enter a description for your item", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_localImagePaths.isEmpty) {
      Get.snackbar("Required", "Please upload at least 1 photo of your item", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isPosting = true);

    final success = await _controller.postProduct(
      title: title,
      description: desc,
      price: double.parse(priceStr),
      stockQuantity: int.parse(stockStr),
      condition: _selectedCondition,
      deliveryType: _deliveryType,
      categoryName: _selectedCategory!,
      subCategoryName: _selectedSubCategory ?? 'All',
      imagePaths: _localImagePaths,
    );

    setState(() => _isPosting = false);

    if (success) {
      _showSuccessDialog(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Sell Your Item",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildProgressHeader(isDark),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildCategoryGrid(isDark)),
                SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildSubCategoryList(isDark)),
                SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildDetailsStep(isDark)),
                SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildPhotoStep(isDark)),
              ],
            ),
          ),
          _buildBottomButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          bool isCompleted = index < _currentPage;
          bool isActive = index == _currentPage;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive ? AppThemeData.primary200 : (isDark ? Colors.white10 : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12, fontFamily: AppThemeData.bold)),
                  ),
                ),
                if (index < _stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: index < _currentPage ? AppThemeData.primary200 : (isDark ? Colors.white10 : Colors.grey[200]),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: AppThemeData.primary200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("BACK", style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold)),
              ),
            ),
            const SizedBox(width: 15),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isPosting ? null : () {
                if (_currentPage == 0 && _selectedCategory == null) {
                  Get.snackbar("Required", "Please select a category", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                if (_currentPage == 1 && _selectedSubCategory == null) {
                  Get.snackbar("Required", "Please select a sub-category", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                if (_currentPage < 3) {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  _submitProduct(isDark);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isPosting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentPage == 3 ? "POST MY AD" : "CONTINUE", 
                      style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, letterSpacing: 1)
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What are you selling?", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 5),
        Text("Select the best category for your item", style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 25),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.9),
          itemCount: _controller.categories.length,
          itemBuilder: (context, index) {
            final cat = _controller.categories[index];
            final name = cat['name'] as String;
            final isSel = _selectedCategory == name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = name;
                  _selectedSubCategory = null;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSel ? AppThemeData.primary200.withValues(alpha: 0.1) : (isDark ? AppThemeData.grey800 : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? AppThemeData.primary200 : (isDark ? Colors.white10 : Colors.grey[200]!), width: 1.5),
                  boxShadow: [if(!isSel) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getIconForCategory(cat['icon']), color: isSel ? AppThemeData.primary200 : (isDark ? Colors.white54 : Colors.grey[400]), size: 35),
                    const SizedBox(height: 12),
                    Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: isSel ? AppThemeData.primary200 : (isDark ? Colors.white70 : Colors.black87))),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubCategoryList(bool isDark) {
    if (_selectedCategory == null) return const Center(child: Text("Select category first"));
    final catData = _controller.categories.firstWhere((c) => c['name'] == _selectedCategory);
    final subs = List<String>.from(catData['subCategories'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getIconForCategory(catData['icon']), color: AppThemeData.primary200, size: 20),
            const SizedBox(width: 10),
            Text(_selectedCategory!, style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold)),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Choose a sub-category", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 25),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final sub = subs[index];
            final isSel = _selectedSubCategory == sub;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSel ? AppThemeData.primary200.withValues(alpha: 0.1) : (isDark ? AppThemeData.grey800 : Colors.white),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSel ? AppThemeData.primary200 : (isDark ? Colors.white10 : Colors.grey[200]!)),
                boxShadow: [if(!isSel) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                title: Text(sub, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 15, color: isSel ? AppThemeData.primary200 : null)),
                trailing: isSel ? Icon(Icons.check_circle, color: AppThemeData.primary200) : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                onTap: () => setState(() => _selectedSubCategory = sub),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Item Details", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 25),
        _inputField("What are you selling?", Icons.edit_note_rounded, isDark, controller: _titleController),
        const SizedBox(height: 15),
        _inputField("Price", Icons.currency_rupee_rounded, isDark, controller: _priceController, keyboardType: TextInputType.number),
        const SizedBox(height: 15),
        _inputField("Stock Quantity", Icons.numbers_rounded, isDark, controller: _stockController, keyboardType: TextInputType.number),
        const SizedBox(height: 25),
        
        const Text("Condition", style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 12),
        _buildChoiceRow(["New", "Used"], _selectedCondition, (val) {
          setState(() {
            _selectedCondition = val;
            if (val == "Used") _deliveryType = "Local";
          });
        }, isDark),
        
        const SizedBox(height: 25),
        const Text("Delivery Type", style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 12),
        _buildChoiceRow(_selectedCondition == "New" ? ["Local", "Pan India", "Both"] : ["Local"], _deliveryType, (val) {
          setState(() => _deliveryType = val);
        }, isDark),

        const SizedBox(height: 25),
        _inputField("A few lines about your item...", Icons.description_outlined, isDark, controller: _descController, maxLines: 4),
      ],
    );
  }

  Widget _buildPhotoStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Photos", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
        const SizedBox(height: 5),
        Text("Ads with photos get up to 5x more responses", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 30),
        if (_localImagePaths.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: _localImagePaths.length + 1,
            itemBuilder: (context, idx) {
              if (idx == _localImagePaths.length) {
                if (_localImagePaths.length >= 5) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppThemeData.grey800 : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: AppThemeData.primary200),
                  ),
                );
              }
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(File(_localImagePaths[idx]), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => setState(() => _localImagePaths.removeAt(idx)),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ] else ...[
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!, style: BorderStyle.solid),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(color: AppThemeData.primary200.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.add_a_photo_outlined, color: AppThemeData.primary200, size: 45),
                  ),
                  const SizedBox(height: 20),
                  Text("Add up to 5 photos", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: AppThemeData.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("Clear photos help buyers decide faster", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIconForCategory(dynamic icon) {
    final String iconName = icon.toString();
    switch (iconName) {
      case 'devices': return Icons.devices_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      case 'face': return Icons.face_rounded;
      case 'chair': return Icons.chair_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      default: return Icons.category_rounded;
    }
  }

  Widget _inputField(String hint, IconData icon, bool isDark, {required TextEditingController controller, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: AppThemeData.primary200, size: 22),
        filled: true,
        fillColor: isDark ? AppThemeData.grey800 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppThemeData.primary200)),
      ),
    );
  }

  Widget _buildChoiceRow(List<String> options, String currentSelection, Function(String) onSelect, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSel = currentSelection == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
            decoration: BoxDecoration(
              color: isSel ? AppThemeData.primary200 : (isDark ? AppThemeData.grey800 : Colors.white),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSel ? AppThemeData.primary200 : (isDark ? Colors.white10 : Colors.grey[300]!)),
              boxShadow: [if(isSel) BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Text(
              opt,
              style: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontFamily: AppThemeData.bold, fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSuccessDialog(bool isDark) {
    Get.dialog(
      barrierDismissible: false,
      Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey900 : Colors.white, 
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: AppThemeData.primary200.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: AppThemeData.primary200, size: 85),
              ),
              const SizedBox(height: 25),
              const Text("Ad Successfully Posted!", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontFamily: AppThemeData.bold)),
              const SizedBox(height: 15),
              Text(
                "Your product is now live. Buyers can see your listing and contact you for the $_deliveryType delivery.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey[500], height: 1.5)
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Close screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text("GREAT, THANKS!", style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
