import 'package:get/get.dart';

import 'package:finway/model/service_request_model.dart';
import 'service_completed_payment_screen.dart';
import 'service_expert_assigned_screen.dart';
import 'service_finding_expert_screen.dart';
import 'service_payment_success_screen.dart';

void resumeServiceBookingFlow(ServiceRequestData booking) {
  final id = booking.id;
  if (id == null) return;

  if (booking.needsPayment) {
    Get.to(() => ServiceCompletedPaymentScreen(bookingId: id));
    return;
  }

  if (booking.isCompleted && booking.isPaid) {
    final base = booking.payableAmount;
    final taxes = booking.taxAmount ?? 0.0;
    final total = taxes > 0 ? (base + taxes) : base;
    Get.to(() => ServicePaymentSuccessScreen(
          bookingId: id,
          amountPaid: total,
          paymentMethod: booking.paymentStatus ?? 'wallet',
          initialBooking: booking,
        ));
    return;
  }

  if (booking.isCompleted && !booking.isPaid) {
    Get.to(() => ServiceCompletedPaymentScreen(bookingId: id));
    return;
  }

  if (booking.shouldShowExpertAssigned || (booking.isOngoing && !booking.isCompleted)) {
    Get.to(() => ServiceExpertAssignedScreen(bookingId: id, initialBooking: booking));
    return;
  }

  final status = (booking.status ?? '').toLowerCase();
  if (booking.isPending || status.isEmpty) {
    Get.to(() => ServiceFindingExpertScreen(bookingId: id));
    return;
  }
}
