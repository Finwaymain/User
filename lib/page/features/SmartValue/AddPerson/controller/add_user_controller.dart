import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/service/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../utils/Preferences.dart';
import '../domain/contact_model.dart';

class AddUserController extends GetxController {
  final RxList<ContactModel> users = <ContactModel>[].obs;
  final RxList<ContactModel> filteredUsers = <ContactModel>[].obs;
  final RxList<ContactModel> contacts = <ContactModel>[].obs;
  final RxList<ContactModel> filteredContacts = <ContactModel>[].obs;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController contactSearchController = TextEditingController();

  final RxBool isLoadingContacts = false.obs;
  final RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    userId.value = Preferences.getInt(Preferences.userId).toString() ?? '' ; // Example value
    if (Preferences.getBoolean(Preferences.isLogin)) {
      getAllUsers();
    }
    filteredUsers.assignAll(users);
    loadRealContacts();
    searchController.addListener(filterUsers);
    contactSearchController.addListener(filterContacts);
  }


  Future<dynamic> getAllUsers() async {
    try {
      ShowToastDialog.showLoader("Please wait");

      Map<String, String> bodyParams = {
        "ac_no": "${Constant.getUserData().data?.acNo}"
      };

      final response = await http.post(
          Uri.parse(API.getAddUser),
          headers: API.header,
          body: jsonEncode(bodyParams));

      showLog("loadUsers 1=> API :: URL :: ${API.getAddUser}");
      showLog("loadUsers 1=> API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("loadUsers 1=> API :: Headers :: ${API.header} ");
      showLog("loadUsers 1=> API :: Response Status :: ${response.statusCode} ");
      showLog("loadUsers 1=> API :: Response Body :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);

      // Changed from 'success' to 'res' based on your API response
      if (responseBody['res'] == 'success') {
        ShowToastDialog.closeLoader();

        List<dynamic> data = responseBody['data'];
        users.assignAll(data.map((e) => ContactModel.fromJson(e)).toList());
        filteredUsers.assignAll(users);

        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        // Show the actual error message from API if available
        String errorMsg = responseBody['msg'] ?? 'Something went wrong. Please try again later';
        ShowToastDialog.showToast(errorMsg);
        throw Exception('Failed to load users');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> addUser() async {
    try {
      String name = nameController.text.trim();
      String mobile = numberController.text.trim();

      // Validation
      if (name.isEmpty) {
        ShowToastDialog.showToast('Please enter name');
        return;
      }

      if (mobile.isEmpty) {
        ShowToastDialog.showToast('Please enter mobile number');
        return;
      }

      ShowToastDialog.showLoader("Adding user...");



      Map<String, String> bodyParams = {
        'user_id': userId.value,
        'ac_no': "${Constant.getUserData().data?.acNo}",
        'user_type': "customer",
        'name': name,
        'mobile': mobile,
      };

      final response = await http.post(
          Uri.parse(API.addUser), // Make sure you have this endpoint in your API class
          headers: API.header,
          body: jsonEncode(bodyParams));

      showLog("addUser => API :: URL :: ${API.addUser}");
      showLog("addUser => API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("addUser => API :: Headers :: ${API.header} ");
      showLog("addUser => API :: Response Status :: ${response.statusCode} ");
      showLog("addUser => API :: Response Body :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['res'] == 'success') {
        ShowToastDialog.closeLoader();

        // Get the new user data from response
        Map<String, dynamic> userData = responseBody['data'][0];

        // Create ContactModel from response data
        ContactModel newUser = ContactModel(
          id: userData['id'].toString(),
          userId: userData['user_id'].toString(),
          name: userData['name'] ?? '',
          status: userData['status'] ?? '',
          createdAt: userData['created_at'] ?? '',
          updatedAt: userData['updated_at'] ?? '',
          number: userData['mobile'] ?? '', // API returns 'mobile' field
        );

        // Add to the lists
        users.add(newUser);
        filteredUsers.assignAll(users);

        // Show success message
        String successMsg = responseBody['msg'] ?? 'User added successfully';
        ShowToastDialog.showToast(successMsg);

        // Clear the form controllers
        nameController.clear();
        numberController.clear();

        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        String errorMsg = responseBody['msg'] ?? 'Failed to add user. Please try again.';
        ShowToastDialog.showToast(errorMsg);
        throw Exception('Failed to add user');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<void> addContactAsUser(String name, String number) async {
    try {
      // Validation
      if (name.isEmpty) {
        ShowToastDialog.showToast('Contact name is required');
        return;
      }

      if (number.isEmpty) {
        ShowToastDialog.showToast('Contact number is required');
        return;
      }

      String cleanedNumber = removeCountryCode(number);

      ShowToastDialog.showLoader("Adding contact...");

      Map bodyParams = {
        'user_id': userId.value,
        'ac_no': "${Constant.getUserData().data?.acNo}",
        'user_type': "customer",
        'name': name,
        'mobile': cleanedNumber,
      };

      final response = await http.post(
          Uri.parse(API.addUser),
          headers: API.header,
          body: jsonEncode(bodyParams));

      showLog("addContactAsUser => API :: URL :: ${API.addUser}");
      showLog("addContactAsUser => API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("addContactAsUser => API :: Headers :: ${API.header} ");
      showLog("addContactAsUser => API :: Response Status :: ${response.statusCode} ");
      showLog("addContactAsUser => API :: Response Body :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['res'] == 'success') {
        ShowToastDialog.closeLoader();

        // Get the new user data from response
        Map<String, dynamic> userData = responseBody['data'][0];

        // Create ContactModel from response data
        ContactModel newUser = ContactModel(
          id: userData['id'].toString(),
          userId: userData['user_id'].toString(),
          name: userData['name'] ?? '',
          status: userData['status'] ?? '',
          createdAt: userData['created_at'] ?? '',
          updatedAt: userData['updated_at'] ?? '',
          number: userData['mobile'] ?? '',
        );

        // Add to the lists
        users.add(newUser);
        filteredUsers.assignAll(users);

        ShowToastDialog.showToast('Contact added successfully');
      } else {
        ShowToastDialog.closeLoader();
        String errorMsg = responseBody['msg'] ?? 'Failed to add contact. Please try again.';
        ShowToastDialog.showToast(errorMsg);
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Request timeout. Please try again.');
    } on SocketException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Network error. Please check your connection.');
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('An error occurred. Please try again. $e');
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Failed to add contact. Please try again.');
    }
  }



  void filterUsers() {
    String query = searchController.text.toLowerCase();
    filteredUsers.assignAll(users
        .where((user) =>
    user.name.toLowerCase().contains(query) ||
        user.number.contains(query))
        .toList());
  }

  void filterContacts() {
    String query = contactSearchController.text.toLowerCase();
    filteredContacts.assignAll(contacts
        .where((contact) =>
    contact.name.toLowerCase().contains(query) ||
        contact.number.contains(query))
        .toList());
  }

  Future<void> loadRealContacts() async {
    isLoadingContacts.value = true;

    try {
      // Request permission
      var status = await Permission.contacts.request();
      if (status.isGranted) {
        // Fetch contacts with properties (name & phone numbers)
        final deviceContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        print('Total device contacts: ${deviceContacts.length}');

        List<ContactModel> loadedContacts = [];

        for (var contact in deviceContacts) {
          if (contact.phones.isEmpty) continue;

          String contactName = '';
          if (contact.displayName.isNotEmpty) {
            contactName = contact.displayName;
          } else if (contact.name.first.isNotEmpty) {
            contactName = contact.name.first;
          } else if (contact.name.last.isNotEmpty) {
            contactName = contact.name.last;
          } else {
            contactName = 'Unknown';
          }

          String phoneNumber = contact.phones.first.number;

          loadedContacts.add(ContactModel(
            name: contactName,
            number: phoneNumber,
          ));
        }

        print('Filtered contacts: ${loadedContacts.length}');

        contacts.assignAll(loadedContacts);
        filteredContacts.assignAll(loadedContacts);
      } else {
        Get.showSnackbar(GetSnackBar(
          message: 'Contacts permission denied',
          backgroundColor: Color(0xFFFF6B6B),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      print('Error loading contacts: $e');
      Get.showSnackbar(GetSnackBar(
        message: 'Error loading contacts: $e',
        backgroundColor: Color(0xFFFF6B6B),
        duration: Duration(seconds: 2),
      ));
    }

    isLoadingContacts.value = false;
  }



  void deleteUser(ContactModel user) {
    users.remove(user);
    filterUsers();
    Get.showSnackbar(GetSnackBar(
      message: 'User deleted successfully',
      backgroundColor: Color(0xFFFF6B6B),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    numberController.dispose();
    contactSearchController.dispose();
    super.onClose();
  }

  String removeCountryCode(String phoneNumber) {
    // Remove + symbol and all non-digit characters
    String cleanedNumber = phoneNumber.replaceAll('+', '').replaceAll(RegExp(r'[^0-9]'), '');

    // Common country codes to remove
    List<String> countryCodes = [
      '91',   // India
      '1',    // US/Canada
      '44',   // UK
      '86',   // China
      '81',   // Japan
      '33',   // France
      '49',   // Germany
      '61',   // Australia
      // Add more country codes as needed
    ];

    // Check and remove country codes
    for (String code in countryCodes) {
      if (cleanedNumber.startsWith(code)) {
        // For India (91), ensure the remaining number is 10 digits
        if (code == '91' && cleanedNumber.length == 12) {
          return cleanedNumber.substring(2);
        }
        // For US/Canada (1), ensure the remaining number is 10 digits
        else if (code == '1' && cleanedNumber.length == 11) {
          return cleanedNumber.substring(1);
        }
        // For other country codes, remove if it makes sense
        else if (cleanedNumber.length > code.length + 7) {
          return cleanedNumber.substring(code.length);
        }
      }
    }

    // If no country code found or number is already in correct format, return as is
    return cleanedNumber;
  }
}
