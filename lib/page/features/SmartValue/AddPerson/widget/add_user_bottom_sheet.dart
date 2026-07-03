
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/add_user_controller.dart';

class AddUserBottomSheet extends StatelessWidget {
  const AddUserBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddUserController>();
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppThemeData.primary200,
                    radius: 26,
                    child: Icon(Icons.person_add, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Add New User",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Name Field
              TextField(
                controller: controller.nameController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon:
                  Icon(Icons.person, color: AppThemeData.primary200),
                  filled: true,
                  fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  // border: OutlineInputBorder(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Phone Field
              TextField(
                controller: controller.numberController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone, color: AppThemeData.primary200),
                  filled: true,
                  fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.addUser,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    "Add User",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
