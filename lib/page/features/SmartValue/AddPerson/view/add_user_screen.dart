import 'package:finway/core/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/add_user_controller.dart';
import '../widget/add_user_bottom_sheet.dart';
import '../widget/contact_picker_bottom_sheet.dart';

class AddUserScreen extends StatelessWidget {
  const AddUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final controller = Get.find<AddUserController>();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: 'Add User',
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color:
                        isDark ? Colors.grey[400] : AppThemeData.primary200,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                      isDark ? AppThemeData.grey800 : Colors.grey[50],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppThemeData.primary200,
                              AppThemeData.primary200.withValues(alpha: 0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeData.primary200.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Get.bottomSheet(
                            AddUserBottomSheet(),
                            isScrollControlled: true,
                            backgroundColor:
                            isDark ? AppThemeData.grey800 : Colors.white,
                          ),
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text(
                            'Add New',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppThemeData.primary200
                              : AppThemeData.primary200,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          var status = await Permission.contacts.request();
                          if (status.isGranted) {
                            await controller.loadRealContacts();
                            Get.bottomSheet(
                              ContactPickerBottomSheet(),
                              isScrollControlled: true,
                              backgroundColor:
                              isDark ? AppThemeData.grey800 : Colors.white,
                            );
                          } else {
                            Get.showSnackbar(GetSnackBar(
                              message: 'Contacts permission denied',
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ));
                          }
                        },
                        child: Icon(
                          Icons.contacts,
                          color: isDark
                              ? AppThemeData.primary200
                              : AppThemeData.primary200,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => controller.filteredUsers.isEmpty
                ? Center(
              child: Text(
                'No users found',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: controller.filteredUsers.length,
              itemBuilder: (context, index) {
                final user = controller.filteredUsers[index];
                return Card(
                  color: isDark ? AppThemeData.grey800 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeData.primary200,
                            AppThemeData.primary200.withValues(alpha: 0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      user.name.toCapitalizeFirst(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      user.number,
                      style: TextStyle(
                        color:
                        isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    // trailing: IconButton(
                    //   icon: Icon(
                    //     Icons.delete,
                    //     color: Colors.red,
                    //   ),
                    //   onPressed: () => controller.deleteUser(user),
                    // ),
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
