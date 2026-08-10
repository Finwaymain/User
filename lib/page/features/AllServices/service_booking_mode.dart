import 'service_style.dart';

enum ServiceBookingMode {
  /// Provider visits customer — address required.
  homeVisit,
  /// Online / remote session — no address needed.
  remote,
}

/// Decides whether the booking form should ask for a service address.
ServiceBookingMode bookingModeFor({
  required String serviceName,
  required String categoryName,
}) {
  final service = cleanServiceName(serviceName).toLowerCase();
  final category = cleanServiceName(categoryName).toLowerCase();
  final combined = '$service $category';

  if (RegExp(r'\bonline\b|\bvirtual\b|\bremote\b|\bfreelance\b|\bvideo\b').hasMatch(combined)) {
    return ServiceBookingMode.remote;
  }

  if (RegExp(r'\btutor\b|\btuition\b|\bhome tutor\b').hasMatch(combined)) {
    return ServiceBookingMode.homeVisit;
  }

  if (service == 'home tutor' || category.contains('home tutor')) {
    return ServiceBookingMode.homeVisit;
  }

  const remoteServices = {
    'language tutor',
    'music teacher',
    'dance teacher',
    'yoga trainer',
    'gym trainer',
  };
  if (remoteServices.contains(service)) {
    return ServiceBookingMode.remote;
  }

  if (category.contains('education services') && !category.contains('home tutor') && !RegExp(r'\btutor\b|\btuition\b').hasMatch(service)) {
    return ServiceBookingMode.remote;
  }

  if (category.contains('personal services')) {
    return ServiceBookingMode.remote;
  }

  return ServiceBookingMode.homeVisit;
}

bool serviceRequiresHomeVisit({
  required String serviceName,
  required String categoryName,
}) {
  return bookingModeFor(serviceName: serviceName, categoryName: categoryName) == ServiceBookingMode.homeVisit;
}
