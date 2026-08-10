import 'dart:io';

import 'package:finway/utils/Preferences.dart';

class API {
  // static const baseUrl = "https://cabme.siswebapp.com/api/v1/"; // live
  // static const baseUrl = "https://staging.cabme.siswebapp.com/api/v1/"; // live
  // static const apiKey = "base64:tq7mTyHl6IUuVbnPZBgAxlzB9lM6QV+zNVpmJcAjs4k=";
  // static const baseUrl = "https://cabbooking.nexttech.fun/api/v1/"; // live cabbooking
  // static const apiKey = "base64:nTfofcBByTDenJQYlsRbH0JjeVFW5lWsIIyXtq8/9sU="; // live cabbooking

  // static const baseUrl = "https://fiinway.nexttech.fun/api/v1/"; // live
  // static const apiKey = "base64:nTfofcBByTDenJQYlsRbH0JjeVFW5lWsIIyXtq8/9sU=";
  // static const baseUrl = "https://api.fiinway.com/api/v1/"; // live
  // static const baseUrl = "http://192.168.1.34:8000/api/v1/"; // local dev
  static const baseUrl = "https://fiinway.online/api/v1/"; // Live VPS
  static const apiKey = "base64:nTfofcBByTDenJQYlsRbH0JjeVFW5lWsIIyXtq8/9sU=";

  static Map<String, String> get authheader => {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    'apikey': apiKey,
  };
  static Map<String, String> get header => {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    'apikey': apiKey,
    'accesstoken': Preferences.getString(Preferences.accesstoken)
  };

  static const userSignUP = "${baseUrl}user";
  static const editProfile = "${baseUrl}update-user-profile";
  static const bannerHome = "${baseUrl}get-banners";
  static const userLogin = "${baseUrl}user-login";
  static const sendResetPasswordOtp = "${baseUrl}reset-password-otp";
  static const resetPasswordOtp = "${baseUrl}resert-password";
  static const getProfileByPhone = "${baseUrl}profilebyphone";
  static const getExistingUserOrNot = "${baseUrl}existing-user";
  static const updateUserNic = "${baseUrl}update-user-nic";
  static const uploadUserPhoto = "${baseUrl}user-photo";
  static const updateUserEmail = "${baseUrl}update-user-email";
  static const updateUserAlternatePhone = "${baseUrl}user-alternate-phone";
  static const userToggleMarketplace = "${baseUrl}user-toggle-marketplace";
  static const changePassword = "${baseUrl}update-user-mdp";
  static const updatePreName = "${baseUrl}user-pre-name";
  static const updateLastName = "${baseUrl}user-name";
  static const updateAddress = "${baseUrl}user-address";
  static const contactUs = "${baseUrl}contact-us";
  static const updateToken = "${baseUrl}update-fcm";
  static const favorite = "${baseUrl}favorite";
  static const rentVehicle = "${baseUrl}vehicle-get";
  static const transaction = "${baseUrl}transaction";
  static const wallet = "${baseUrl}wallet";
  static const amount = "${baseUrl}amount";
  static const getFcmToken = "${baseUrl}fcm-token";
  static const deleteFavouriteRide = "${baseUrl}delete-favorite-ride";
  static const rejectRide = "${baseUrl}set-rejected-requete";
  static const dispatchCheckTimeout = "${baseUrl}dispatch/check-timeout/";
  static const dispatchRetry = "${baseUrl}dispatch/retry/";

  static const onBoarding = "${baseUrl}on-boarding?type=Customer";
  static const getRideReview = "${baseUrl}get-ride-review";
  static const taxi = "${baseUrl}taxi";
  static const userPendingPayment = "${baseUrl}user-pending-payment";
  static const setFavouriteRide = "${baseUrl}favorite-ride";
  static const getVehicleCategory = "${baseUrl}Vehicle-category";
  static const driverDetails = "${baseUrl}driver";
  static const getPaymentMethod = "${baseUrl}payment-method";
  static const bookRides = "${baseUrl}requete-register";
  static const userAllRides = "${baseUrl}user-all-rides";
  static const newRide = "${baseUrl}requete-userapp";
  static const confirmedRide = "${baseUrl}user-confirmation";
  static const onRide = "${baseUrl}user-ride";
  static const completedRide = "${baseUrl}user-complete";
  static const canceledRide = "${baseUrl}user-cancel";
  static const driverConfirmRide = "${baseUrl}driver-confirm";
  static const feelSafeAtDestination = "${baseUrl}feel-safe";
  static const sos = "${baseUrl}storesos";
  static const bookRide = "${baseUrl}set-Location";
  static const getRentedData = "${baseUrl}location";
  static const cancelRentedVehicle = "${baseUrl}canceled-location";
  static const paymentSetting = "${baseUrl}payment-settings";
  static const payRequestWallet = "${baseUrl}pay-requete-wallet";
  static const payRequestCash = "${baseUrl}payment-by-cash";
  static const payRequestTransaction = "${baseUrl}pay-requete";
  static const addReview = "${baseUrl}note";
  static const addComplaint = "${baseUrl}complaints";
  static const getComplaint = "${baseUrl}complaintsList";
  static const discountList = "${baseUrl}discount-list";
  static const rideDetails = "${baseUrl}ridedetails";
  static const getLanguage = "${baseUrl}language";
  static const deleteUser = "${baseUrl}user-delete?user_id=";
  static const settings = "${baseUrl}settings";
  static const privacyPolicy = "${baseUrl}privacy-policy";
  static const termsOfCondition = "${baseUrl}terms-of-condition";
  static const referralAmount = "${baseUrl}get-referral";
  static const referralStats = "${baseUrl}referral/stats";
  static const referralHistory = "${baseUrl}referral/history";

  //Parcel API
  static const getParcelCategory = "${baseUrl}get-parcel-category";
  static const bookParcel = "${baseUrl}parcel-register";
  static const parcelReject = "${baseUrl}parcel-rejected";
  static const parcelCanceled = "${baseUrl}parcel-canceled";

  static const getParcel = "${baseUrl}get-user-parcel-orders";
  static const parcelPayByWallet = "${baseUrl}parcel-pay-requete-wallet";
  static const parcelPayByCase = "${baseUrl}parcel-payment-by-cash";
  static const parcelPaymentRequest = "${baseUrl}parcel-payment-requete";
  static const getParcelDetails = "${baseUrl}get-parcel-detail";

  // Smart Value
  static const accountDetails = "${baseUrl}get_profile/smart-value";
  static const showWalletAmount = "${baseUrl}show_wallet_amount/smart-value";
  static const showTransactionHistory = "${baseUrl}show_transaction_history/smart-value";
  static const getAddUser = "${baseUrl}showadduser/smart-value";
  static const addUser = "${baseUrl}adduser/smart-value";
  static const transferToWallet = "${baseUrl}transfer_to_wallet/smart-value";
  static const userSetMPin = "${baseUrl}user_changepasswordset/smart-value";
  static const withdrawWallet = "${baseUrl}withdrawWallet/smart-value";

  // Marketplace API Endpoints
  static const getMarketplaceProducts = "${baseUrl}marketplace/products";
  static const getMarketplaceProductDetails = "${baseUrl}marketplace/products/"; // + id
  static const getMarketplaceCategories = "${baseUrl}marketplace/categories";
  static const getMyMarketplaceProducts = "${baseUrl}marketplace/my-products";
  static const getMarketplaceProductProgress = "${baseUrl}marketplace/products/"; // + id + /progress
  static const createMarketplaceProduct = "${baseUrl}marketplace/products";
  static const uploadMarketplaceImage = "${baseUrl}marketplace/upload-image";
  static const updateMarketplaceProduct = "${baseUrl}marketplace/products/"; // + id + /update
  static const deleteMarketplaceProduct = "${baseUrl}marketplace/products/"; // + id + /delete

  // Marketplace Order APIs
  static const createMarketplaceOrder = "${baseUrl}marketplace/orders";
  static const getMarketplaceBuyerOrders = "${baseUrl}marketplace/orders/buyer";
  static const getMarketplaceSellerOrders = "${baseUrl}marketplace/orders/seller";
  static const getMarketplaceOrderDetails = "${baseUrl}marketplace/orders/"; // + id
  static const updateMarketplaceOrderStatus = "${baseUrl}marketplace/orders/"; // + id + /status

  // ── OTP Auth Flow (new phone+email login system) ───────────────────────────
  static const authSendPhoneOtp         = "${baseUrl}auth/send-phone-otp";
  static const authVerifyPhoneOtp       = "${baseUrl}auth/verify-phone-otp";
  static const authSendEmailOtp         = "${baseUrl}auth/send-email-otp";
  static const authVerifyEmailRegister  = "${baseUrl}auth/verify-email-otp-register";
  static const authLoginByPhone         = "${baseUrl}auth/login-by-phone";
  static const authVerifyLoginEmailOtp  = "${baseUrl}auth/verify-login-email-otp";
  // Conditional Login / MPIN flow
  static const authCheckUser            = "${baseUrl}auth/check-user";
  static const authLoginByMpin          = "${baseUrl}auth/login-by-mpin";
  static const authResetMpin            = "${baseUrl}auth/reset-mpin";
  static const authRegisterSimple       = "${baseUrl}auth/register-simple";
  // ───────────────────────────────────────────────────────────────────────────

  // All Services catalog ("More" section)
  static const getServiceCategories = "${baseUrl}service-categories";
  static const bookService = "${baseUrl}book-service";
  static const serviceHistory = "${baseUrl}service-history";
  static const serviceBookingDetail = "${baseUrl}service-booking/";
  static const servicePriceEstimate = "${baseUrl}service-price-estimate";
  static const payServiceBooking = "${baseUrl}service-booking/pay";
  static const cancelServiceBooking = "${baseUrl}service-booking/cancel";

  // Subscription API Endpoints
  static const getSubscriptionPlans = "${baseUrl}get-consumer-plans";
  static const setSubscription = "${baseUrl}set-consumer-subscription";
  static const getSubscriptionHistory = "${baseUrl}get-subscription-history";
}
