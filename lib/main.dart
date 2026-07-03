import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/settings_controller.dart';
import 'package:finway/firebase_options.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/page/features/SmartValue/MPinChange/controller/mpin_change_controller.dart';
import 'package:finway/page/features/SmartValue/Medical/controllers/medical_card_controller.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/features/SmartValue/AddPerson/controller/add_user_controller.dart';
import 'package:finway/themes/styles.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'page/chats_screen/conversation_screen.dart';
import 'page/completed_ride_screens/trip_history_screen.dart';
import 'page/auth_screens/phone_entry_screen.dart';
import 'page/on_boarding_screen.dart';
import 'service/localization_service.dart';
import 'utils/Preferences.dart';
import 'package:finway/controller/searching_driver_controller.dart';


class FirebaseService {
    static Future<void> initialize() async {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform
        );

        await FirebaseAppCheck.instance.activate(
            webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.appAttest
        );
    }

    static Future<void> setupMessaging() async {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true
        );

        await FirebaseMessaging.instance.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true
        );
    }

    static Future<void> setupInteractedMessage(BuildContext context) async {
        await NotificationService.initialize(context);
        await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");

        RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
            await _handleNotificationTap(initialMessage);
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
                if (Get.isRegistered<SearchingDriverController>()) {
                    Get.find<SearchingDriverController>().handleFCMMessage(message);
                }
                if (message.notification != null) {
                    NotificationService.display(message);
                }
            }
        );

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
                if (Get.isRegistered<SearchingDriverController>()) {
                    Get.find<SearchingDriverController>().handleFCMMessage(message);
                }
                await _handleNotificationTap(message);
            }
        );
    }

    static Future<void> _handleNotificationTap(RemoteMessage message) async {
        try {
            if (message.data['status'] == "done") {
                await Get.to(ConversationScreen(), arguments: {
                        'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
                        'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
                        'receiverName': json.decode(message.data['message'])['senderName'].toString(),
                        'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString()
                    }
                );
            }
            else if (message.data['statut'] == "confirmed" || message.data['statut'] == "driver_rejected") {
                if (Get.isRegistered<SearchingDriverController>()) {
                    Get.find<SearchingDriverController>().handleFCMMessage(message);
                } else {
                    if (message.data['statut'] == "confirmed") {
                        var argumentData = {'type': 'confirmed'.tr, 'data': RideData.fromJson(message.data)};
                        if (Constant.selectedMapType == 'osm') {
                            Get.to(const RouteOsmViewScreen(), arguments: argumentData);
                        } else {
                            Get.to(const RouteViewScreen(), arguments: argumentData);
                        }
                    } else {
                        DashBoardController dashBoardController = Get.put(DashBoardController());
                        dashBoardController.selectedDrawerIndex.value = 1;
                        await Get.to(MainDashboard());
                    }
                }
            }
            else if (message.data['statut'] == "on ride") {
                var argumentData = {'type': 'on_ride'.tr, 'data': RideData.fromJson(message.data)};

                if (Constant.selectedMapType == 'osm') {
                    Get.to(const RouteOsmViewScreen(), arguments: argumentData);
                }
                else {
                    Get.to(const RouteViewScreen(), arguments: argumentData);
                }
            }
            else if (message.data['statut'] == "completed") {
                Get.to(TripHistoryScreen(), arguments: {
                        "rideData": RideData.fromJson(message.data)
                    }
                );
            }
        }
        catch (e) {
            log('Error handling notification tap: $e');
        }
    }
}

class NotificationService {
    static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    static Future<void> initialize(BuildContext context) async {
        AndroidNotificationChannel channel = const AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.high
        );

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        var iosInitializationSettings = const DarwinInitializationSettings();

        final InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: iosInitializationSettings
        );

        await _flutterLocalNotificationsPlugin.initialize(
            initializationSettings,
            onDidReceiveNotificationResponse: (NotificationResponse response) async {
                if (response.payload != null && response.payload!.isNotEmpty) {
                    try {
                        Map<String, dynamic> data = jsonDecode(response.payload!);
                        RemoteMessage message = RemoteMessage(data: data);
                        await FirebaseService._handleNotificationTap(message);
                    } catch (e) {
                        log('Error handling local notification click: $e');
                    }
                }
            }
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
    }

    static void display(RemoteMessage message) async {
        try {
            final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

            const NotificationDetails notificationDetails = NotificationDetails(
                android: AndroidNotificationDetails(
                    "01",
                    "cabme",
                    importance: Importance.max,
                    priority: Priority.high
                )
            );

            await _flutterLocalNotificationsPlugin.show(
                id,
                message.notification!.title,
                message.notification!.body,
                notificationDetails,
                payload: jsonEncode(message.data)
            );
        }
        on Exception catch (e) {
            log('Notification display error: $e');
        }
    }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform
    );
}

class AppInitialization {
    static Future<void> initializeApp() async {
        WidgetsFlutterBinding.ensureInitialized();

        // Initialize Firebase
        await FirebaseService.initialize();

        // Set preferred orientations
        await _setOrientations();

        // Initialize preferences
        await Preferences.initPref();

        // Setup Firebase messaging
        await FirebaseService.setupMessaging();

        // Platform specific initialization
        await _platformSpecificInit();
    }

    static Future<void> _setOrientations() async {
        SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown
            ]);
    }

    static Future<void> _platformSpecificInit() async {
        if (!Platform.isIOS) {
            // Set background message handler
            FirebaseMessaging.onBackgroundMessage(
                firebaseMessagingBackgroundHandler
            );

            // Android Maps configuration
            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            if (androidInfo.version.sdkInt > 28) {
                AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
            }
        }
    }
}

class ThemeService with WidgetsBindingObserver {
    DarkThemeProvider themeChangeProvider = DarkThemeProvider();

    void initialize() {
        WidgetsBinding.instance.addObserver(this);
        getCurrentAppTheme();
    }

    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        getCurrentAppTheme();
    }

    void getCurrentAppTheme() async {
        themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
    }

    DarkThemeProvider get provider => themeChangeProvider;
}

class InitialBinding extends Bindings {
    @override
    void dependencies() {
        Get.put(SettingsController());
        Get.lazyPut(() => AddUserController());
        Get.lazyPut(() => MedicalCardController());
        Get.lazyPut(() => MPinChangeController());
    }
}

class AppRoutes {
    static Widget getInitialScreen() {
        return GetBuilder(
            init: SettingsController(),
            builder: (controller) {
                // Check if language is selected
                if (Preferences.getString(Preferences.languageCodeKey).toString().isEmpty) {
                    Preferences.setString(Preferences.languageCodeKey, 'en');
                }

                // Check if onboarding is finished
                if (!Preferences.getBoolean(Preferences.isFinishOnBoardingKey)) {
                    return const OnBoardingScreen();
                }

                // Check if user is logged in
                if (Preferences.getBoolean(Preferences.isLogin)) {
                    return MainDashboard();
                }

                // Not logged in → new OTP auth flow (phone number first)
                return const PhoneEntryScreen(mode: 'signup');
            }
        );
    }
}

void main() async {
    // Initialize the app
    await AppInitialization.initializeApp();

    // Run the app
    runApp(const MyApp());
}

class MyApp extends StatefulWidget {
    const MyApp({super.key});

    @override
    State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
    final ThemeService _themeService = ThemeService();

    @override
    void initState() {
        super.initState();
        _themeService.initialize();
    }

    @override
    void dispose() {
        _themeService.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        // Setup Firebase messaging interactions
        FirebaseService.setupInteractedMessage(context);

        // Setup localization with delay
        _setupLocalization();

        return ChangeNotifierProvider(
            create: (_) => _themeService.provider,
            child: Consumer<DarkThemeProvider>(
                builder: (context, themeProvider, child) {
                    return GetMaterialApp(
                        title: Constant.appName!,
                        debugShowCheckedModeBanner: false,
                        theme: Styles.themeData(
                            themeProvider.darkTheme == 0
                                ? true
                                : themeProvider.darkTheme == 1
                                    ? false
                                    : themeProvider.getSystemThem(),
                            context
                        ),
                        locale: LocalizationService.locale,
                        fallbackLocale: LocalizationService.locale,
                        translations: LocalizationService(),
                        initialBinding: InitialBinding(),
                        builder: EasyLoading.init(),
                        home: AppRoutes.getInitialScreen()
                    );
                }
            )
        );
    }

    void _setupLocalization() {
        Future.delayed(const Duration(seconds: 3), () {
                String languageCode = Preferences.getString(Preferences.languageCodeKey);
                if (languageCode.isNotEmpty) {
                    LocalizationService().changeLocale(languageCode);
                }
            }
        );
    }
}

// // ignore_for_file: deprecated_member_use
//
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:finway/constant/constant.dart';
// import 'package:finway/controller/dash_board_controller.dart';
// import 'package:finway/controller/settings_controller.dart';
// import 'package:finway/firebase_options.dart';
// import 'package:finway/model/ride_model.dart';
// import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
// import 'package:finway/page/localization_screens/localization_screen.dart';
// import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
// import 'package:finway/page/route_view_screen/route_view_screen.dart';
// import 'package:finway/page/services/SmartValue/AddPerson/controller/add_user_controller.dart';
// import 'package:finway/themes/styles.dart';
// import 'package:finway/utils/dark_theme_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import 'page/auth_screens/login_screen.dart';
// import 'page/chats_screen/conversation_screen.dart';
// import 'page/completed_ride_screens/trip_history_screen.dart';
// import 'page/home_screen/view/home_screen.dart';
// import 'page/services/Texi/texi_dash_board.dart';
// import 'page/on_boarding_screen.dart';
// import 'service/localization_service.dart';
// import 'utils/Preferences.dart';
//
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   await FirebaseAppCheck.instance.activate(
//     webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
//     androidProvider: AndroidProvider.playIntegrity,
//     appleProvider: AppleProvider.appAttest,
//   );
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//
//   await Preferences.initPref();
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
//
//   await FirebaseMessaging.instance.requestPermission(
//     alert: true,
//     announcement: false,
//     badge: true,
//     carPlay: false,
//     criticalAlert: false,
//     provisional: false,
//     sound: true,
//   );
//
//   if (!Platform.isIOS) {
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     if (androidInfo.version.sdkInt > 28) {
//       AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
//     }
//   }
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   DarkThemeProvider themeChangeProvider = DarkThemeProvider();
//
//   @override
//   void initState() {
//     WidgetsBinding.instance.addObserver(this);
//     getCurrentAppTheme();
//     super.initState();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     getCurrentAppTheme();
//   }
//
//   void getCurrentAppTheme() async {
//     themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
//   }
//
//   Future<void> setupInteractedMessage(BuildContext context) async {
//     initialize(context);
//     await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");
//     RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {}
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.notification != null) {
//         display(message);
//       }
//     });
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//       if (message.notification != null) {
//         if (message.data['status'] == "done") {
//           await Get.to(ConversationScreen(), arguments: {
//             'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
//             'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
//             'receiverName': json.decode(message.data['message'])['senderName'].toString(),
//             'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString(),
//           });
//         } else if (message.data['statut'] == "confirmed" || message.data['statut'] == "driver_rejected") {
//           DashBoardController dashBoardController = Get.put(DashBoardController());
//           dashBoardController.selectedDrawerIndex.value = 1;
//           await Get.to(MainDashboard());
//           // await Get.to(TexiDashboard());
//         } else if (message.data['statut'] == "on ride") {
//           var argumentData = {'type': 'on_ride'.tr, 'data': RideData.fromJson(message.data)};
//
//           if (Constant.selectedMapType == 'osm') {
//             Get.to(const RouteOsmViewScreen(), arguments: argumentData);
//           } else {
//             Get.to(const RouteViewScreen(), arguments: argumentData);
//           }
//         } else if (message.data['statut'] == "completed") {
//           Get.to(TripHistoryScreen(), arguments: {
//             "rideData": RideData.fromJson(message.data),
//           });
//         }
//       }
//     });
//   }
//
//   Future<void> initialize(BuildContext context) async {
//     AndroidNotificationChannel channel = const AndroidNotificationChannel(
//       'high_importance_channel', // id
//       'High Importance Notifications', // title
//       importance: Importance.high,
//     );
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     var iosInitializationSettings = const DarwinInitializationSettings();
//     final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: iosInitializationSettings);
//     await FlutterLocalNotificationsPlugin().initialize(initializationSettings, onDidReceiveNotificationResponse: (payload) async {});
//
//     await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
//   }
//
//   void display(RemoteMessage message) async {
//     try {
//       final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//       const NotificationDetails notificationDetails = NotificationDetails(
//           android: AndroidNotificationDetails(
//         "01",
//         "cabme",
//         importance: Importance.max,
//         priority: Priority.high,
//       ));
//
//       await FlutterLocalNotificationsPlugin().show(
//         id,
//         message.notification!.title,
//         message.notification!.body,
//         notificationDetails,
//         payload: jsonEncode(message.data),
//       );
//     } on Exception catch (e) {
//       log(e.toString());
//     }
//   }
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     setupInteractedMessage(context);
//     Future.delayed(const Duration(seconds: 3), () {
//       if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
//         LocalizationService().changeLocale(Preferences.getString(Preferences.languageCodeKey).toString());
//       }
//     });
//     Get.put(AddUserController());
//
//     return ChangeNotifierProvider(create: (_) {
//       return themeChangeProvider;
//     }, child: Consumer<DarkThemeProvider>(builder: (context, value, child) {
//       return GetMaterialApp(
//         title: Constant.appName! ,
//         debugShowCheckedModeBanner: false,
//         theme: Styles.themeData(
//             themeChangeProvider.darkTheme == 0
//                 ? true
//                 : themeChangeProvider.darkTheme == 1
//                     ? false
//                     : themeChangeProvider.getSystemThem(),
//             context),
//         locale: LocalizationService.locale,
//         fallbackLocale: LocalizationService.locale,
//         translations: LocalizationService(),
//         builder: EasyLoading.init(),
//         // home: GetBuilder(
//         //     init: SettingsController(),
//         //     builder: (controller) {
//         //       return Preferences.getString(Preferences.languageCodeKey).toString().isEmpty
//         //           ? const LocalizationScreens(intentType: "main")
//         //           : Preferences.getBoolean(Preferences.isFinishOnBoardingKey)
//         //               ? Preferences.getBoolean(Preferences.isLogin)
//         //                   ? TexiDashboard()
//         //                   : const LoginScreen()
//         //                : const OnBoardingScreen();
//         //     }),
//         home: GetBuilder(
//             init: SettingsController(),
//             builder: (controller) {
//               return Preferences.getString(Preferences.languageCodeKey).toString().isEmpty
//                   ? const LocalizationScreens(intentType: "main")
//                   : Preferences.getBoolean(Preferences.isFinishOnBoardingKey)
//                   ? Preferences.getBoolean(Preferences.isLogin)
//                   ? MainDashboard()
//                   : const MainDashboard()
//                   : const OnBoardingScreen();
//             }),
//       );
//     }));
//   }
// }
