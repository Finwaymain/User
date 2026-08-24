import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/controller/service_history_controller.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_completed_payment_screen.dart';
import 'service_expert_assigned_screen.dart';

class _SearchStep {
  final String label;
  final IconData icon;

  const _SearchStep(this.label, this.icon);
}

class ServiceFindingExpertScreen extends StatefulWidget {
  final int bookingId;

  const ServiceFindingExpertScreen({super.key, required this.bookingId});

  @override
  State<ServiceFindingExpertScreen> createState() => _ServiceFindingExpertScreenState();
}

class _ServiceFindingExpertScreenState extends State<ServiceFindingExpertScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final ServiceBookingController _controller;
  late final AnimationController _pulseController;
  late final AnimationController _sweepController;
  Timer? _stepTimer;
  Timer? _countdownTimer;
  int _activeStep = 0;
  int _remainingSeconds = 60;
  bool _searchTimedOut = false;
  bool _cancelling = false;
  bool _showUrgentBanner = false;
  bool _navigatedToExpert = false;
  Worker? _bookingWorker;

  static const _steps = [
    _SearchStep('Searching nearby experts...', Icons.search_rounded),
    _SearchStep('Checking expert availability...', Icons.verified_user_outlined),
    _SearchStep('Sending service request...', Icons.send_rounded),
    _SearchStep('Waiting for confirmation...', Icons.hourglass_top_rounded),
  ];

  Color _accent(bool isDarkMode) => isDarkMode ? AppThemeData.primary300Dark : AppThemeData.primary200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Get.put(ServiceBookingController(), tag: 'finding_${widget.bookingId}');
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _sweepController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _startSearchCountdown();

    _bookingWorker = ever(_controller.booking, (ServiceRequestData? item) {
      if (item != null) _handleUpdate(item);
    });

    _controller.refreshBooking(widget.bookingId).then((item) {
      if (item != null) _handleUpdate(item);
    });
  }

  void _startSearchCountdown() {
    _stepTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = 60;
      _searchTimedOut = false;
      _activeStep = 0;
    });

    _stepTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_activeStep < _steps.length - 1) {
        setState(() => _activeStep++);
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
        _stepTimer?.cancel();
        _controller.stopPolling();
        setState(() => _searchTimedOut = true);
      }
    });

    _controller.startPolling(widget.bookingId, onUpdate: _handleUpdate);
  }

  void _retrySearch() {
    _startSearchCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_navigatedToExpert && !_cancelling && !_searchTimedOut) {
      _controller.refreshBooking(widget.bookingId).then((item) {
        if (item != null) _handleUpdate(item);
      });
    }
  }

  void _goToExpertAssigned(ServiceRequestData item) {
    if (!mounted || _navigatedToExpert || _cancelling) return;
    _navigatedToExpert = true;
    _countdownTimer?.cancel();
    _stepTimer?.cancel();
    _controller.stopPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.off(() => ServiceExpertAssignedScreen(bookingId: widget.bookingId, initialBooking: item));
    });
  }

  void _handleUpdate(ServiceRequestData item) {
    if (!mounted || _navigatedToExpert) return;

    final desc = (item.description ?? '').toUpperCase();
    if (desc.contains('[VERY URGENT]') && !_showUrgentBanner) {
      setState(() => _showUrgentBanner = true);
    }

    final status = (item.status ?? '').toLowerCase();
    if (status == 'cancelled' || status == 'canceled') {
      _countdownTimer?.cancel();
      _stepTimer?.cancel();
      _controller.stopPolling();
      Get.offAll(() => const MainDashboard());
      return;
    }

    if (item.shouldShowExpertAssigned) {
      _goToExpertAssigned(item);
    } else if (item.needsPayment) {
      _countdownTimer?.cancel();
      _stepTimer?.cancel();
      _controller.stopPolling();
      Get.off(() => ServiceCompletedPaymentScreen(bookingId: widget.bookingId));
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking?'.tr),
        content: Text('Are you sure you want to cancel this service request?'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No'.tr)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes, Cancel'.tr)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    _countdownTimer?.cancel();
    _stepTimer?.cancel();
    _controller.stopPolling();
    final ok = await _controller.cancelBooking(bookingId: widget.bookingId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      await ServiceHistoryController.refreshAll();
      Get.offAll(() => const MainDashboard());
    } else {
      _startSearchCountdown();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bookingWorker?.dispose();
    _stepTimer?.cancel();
    _pulseController.dispose();
    _sweepController.dispose();
    _controller.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final accent = _accent(isDarkMode);

    return Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            onPressed: _cancelling ? null : () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finding Expert'.tr,
                style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 17, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
              ),
              Text(
                _searchTimedOut ? 'Search window ended'.tr : 'We are finding the best expert for you'.tr,
                style: TextStyle(fontSize: 11, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500, fontFamily: AppThemeData.regular),
              ),
            ],
          ),
          actions: [
            if (!_searchTimedOut)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_remainingSeconds}s',
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _searchTimedOut
              ? _buildNoExpertState(context, isDarkMode, accent)
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            _radarWidget(accent),
                            const SizedBox(height: 24),
                            Text(
                              'Finding Service Expert...'.tr,
                              style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 22, color: accent),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please wait while we connect you with the best available expert near you.'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500, height: 1.45),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                children: List.generate(_steps.length, (index) => _stepRow(isDarkMode, accent, index)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: Colors.amber.shade700, size: 26),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Need it very urgent?'.tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: accent)),
                                        Text(
                                          _showUrgentBanner
                                              ? 'Your urgent request is prioritized for faster matching.'.tr
                                              : 'Enable Very Urgent option for faster service.'.tr,
                                          style: TextStyle(fontSize: 11.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: ButtonThem.buildBorderButton(
                        context,
                        title: _cancelling ? 'Cancelling...'.tr : 'Cancel Booking'.tr,
                        btnColor: Colors.white,
                        btnBorderColor: accent,
                        txtColor: accent,
                        onPress: _cancelling ? () {} : _cancelBooking,
                      ),
                    ),
                  ],
                ),
        ),
    );
  }

  Widget _buildNoExpertState(BuildContext context, bool isDarkMode, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.person_search_outlined,
                size: 64,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Experts are Busy".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 22,
              color: isDarkMode ? Colors.white : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "All service professionals are currently busy with other orders. Would you like to search again?".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              fontSize: 13.5,
              height: 1.45,
              color: isDarkMode ? Colors.white70 : AppThemeData.grey500,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _retrySearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Retry Search".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelBooking,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              "Cancel Request".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _radarWidget(Color accent) {
    return SizedBox(
      height: 220,
      width: 220,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _sweepController]),
        builder: (context, _) {
          final pulse = _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(200, accent.withValues(alpha: 0.06)),
              _ring(160 + pulse * 12, accent.withValues(alpha: 0.1)),
              _ring(120 + pulse * 8, accent.withValues(alpha: 0.14)),
              Transform.rotate(
                angle: _sweepController.value * 2 * math.pi,
                child: CustomPaint(size: const Size(200, 200), painter: _RadarSweepPainter(accent)),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: accent.withValues(alpha: 0.25), width: 3),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 2)],
                ),
                child: Icon(Icons.engineering_rounded, size: 44, color: accent),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
    );
  }

  Widget _stepRow(bool isDarkMode, Color accent, int index) {
    final step = _steps[index];
    final isDone = index < _activeStep;
    final isActive = index == _activeStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isActive || isDone) ? accent.withValues(alpha: 0.1) : (isDarkMode ? AppThemeData.grey200Dark : const Color(0xFFF5F7FA)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(step.icon, size: 18, color: isActive || isDone ? accent : AppThemeData.grey400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label.tr,
              style: TextStyle(
                fontSize: 13.5,
                fontFamily: isActive ? AppThemeData.semiBold : AppThemeData.regular,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
          ),
          if (isActive)
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: accent))
          else if (isDone)
            Icon(Icons.check_circle, size: 18, color: accent)
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final Color color;

  _RadarSweepPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.25)],
        stops: const [0.0, 0.15],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
