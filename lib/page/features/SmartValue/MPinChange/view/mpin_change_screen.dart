import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/mpin_change_controller.dart';

class MPinChangeScreen extends StatelessWidget {
  const MPinChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MPinChangeController());
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      showAppBar: true,
      // Dynamic app bar title based on mode
      appBarTitle: controller.isSetMode.value ? 'Set M-PIN' : 'Change M-PIN',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Header Section
                      FadeTransition(
                        opacity: controller.fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(controller.slideAnimation),
                          child: Column(
                            children: [
                              // Lock Icon - Dynamic based on mode
                              Obx(() => Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppThemeData.primary200.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  controller.isSetMode.value ? Icons.lock_outline : Icons.lock_reset,
                                  size: 40,
                                  color: AppThemeData.primary200,
                                ),
                              )),

                              const SizedBox(height: 24),

                              // Title and Description - Updated for both modes
                              Obx(() => Column(
                                children: [
                                  Text(
                                    _getStepTitle(controller.currentStep.value, controller.isSetMode.value),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getStepDescription(controller.currentStep.value, controller.isSetMode.value),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Step Indicator - Updated for both modes
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildStepIndicator(controller.currentStep.value, controller.isSetMode.value),
                      )),

                      const SizedBox(height: 40),

                      // PIN Input Section
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Obx(() => _buildPinInputSection(
                            controller, isDark, controller.currentStep.value)),
                      ),

                      const SizedBox(height: 40),

                      // Security Tips - Updated for both modes
                      Obx(() => _shouldShowSecurityTips(controller.currentStep.value, controller.isSetMode.value)
                          ? FadeTransition(
                        opacity: controller.fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppThemeData.primary200.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppThemeData.primary200.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 20,
                                    color: AppThemeData.primary200,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Security Tips',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppThemeData.primary200,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(() => Text(
                                controller.isSetMode.value
                                    ? '• Choose a unique 4-digit combination\n'
                                    '• Avoid using obvious numbers like 1234\n'
                                    '• Don\'t use your birth year or phone number\n'
                                    '• Keep your M-PIN confidential'
                                    : '• Make sure you\'re in a secure environment\n'
                                    '• Choose a unique 4-digit combination\n'
                                    '• Avoid using obvious numbers like 1234\n'
                                    '• Keep your new M-PIN confidential',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black,
                                  height: 1.5,
                                ),
                              )),
                            ],
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              const SizedBox(height: 20),

              Column(
                children: [
                  // Main Action Button
                  Obx(() => Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeData.primary200,
                          AppThemeData.primary200.withValues(alpha: 0.8)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeData.primary200.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                        HapticFeedback.lightImpact();
                        if (controller.currentStep.value < 2) {
                          controller.proceedToNextStep();
                        } else {
                          controller.changeMPin();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        _getButtonText(controller.currentStep.value, controller.isSetMode.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )),

                  const SizedBox(height: 12),

                  // Secondary Actions - Updated for both modes
                  Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Show back button only when appropriate
                      _shouldShowBackButton(controller.currentStep.value, controller.isSetMode.value)
                          ? TextButton(
                        onPressed: controller.goBackToPreviousStep,
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                      TextButton(
                        onPressed: controller.resetPin,
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: AppThemeData.primary200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to determine step titles based on mode
  String _getStepTitle(int step, bool isSetMode) {
    if (isSetMode) {
      switch (step) {
        case 1:
          return 'Set Your M-PIN';
        case 2:
          return 'Confirm Your M-PIN';
        default:
          return 'Set M-PIN';
      }
    } else {
      switch (step) {
        case 0:
          return 'Enter Current PIN';
        case 1:
          return 'Enter New PIN';
        case 2:
          return 'Confirm New PIN';
        default:
          return 'Change M-PIN';
      }
    }
  }

  // Helper method to determine step descriptions based on mode
  String _getStepDescription(int step, bool isSetMode) {
    if (isSetMode) {
      switch (step) {
        case 1:
          return 'Create a secure 4-digit M-PIN for your transactions';
        case 2:
          return 'Re-enter your M-PIN to confirm';
        default:
          return 'Set up your M-PIN';
      }
    } else {
      switch (step) {
        case 0:
          return 'Please enter your current 4-digit M-PIN to continue';
        case 1:
          return 'Enter your new 4-digit M-PIN';
        case 2:
          return 'Re-enter your new PIN to confirm';
        default:
          return 'Change your M-PIN';
      }
    }
  }

  // Helper method to determine button text based on mode
  String _getButtonText(int step, bool isSetMode) {
    if (isSetMode) {
      switch (step) {
        case 1:
          return 'Continue';
        case 2:
          return 'Set M-PIN';
        default:
          return 'Continue';
      }
    } else {
      switch (step) {
        case 0:
          return 'Verify Current PIN';
        case 1:
          return 'Continue';
        case 2:
          return 'Change PIN';
        default:
          return 'Continue';
      }
    }
  }

  // Helper method to build step indicators based on mode
  List<Widget> _buildStepIndicator(int currentStep, bool isSetMode) {
    if (isSetMode) {
      // In set mode, show only 2 steps (1: New PIN, 2: Confirm PIN)
      return List.generate(2, (index) {
        final actualStep = index + 1; // Steps 1 and 2
        final isActive = actualStep == currentStep;
        final isCompleted = actualStep < currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? AppThemeData.primary200
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                  '$actualStep',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (index < 1)
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        );
      });
    } else {
      // In change mode, show all 3 steps
      return List.generate(3, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? AppThemeData.primary200
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        );
      });
    }
  }

  // Helper method to determine when to show security tips
  bool _shouldShowSecurityTips(int currentStep, bool isSetMode) {
    if (isSetMode) {
      return currentStep == 1; // Show on first step of set mode (new PIN)
    } else {
      return currentStep == 0; // Show on first step of change mode (current PIN)
    }
  }

  // Helper method to determine when to show back button
  bool _shouldShowBackButton(int currentStep, bool isSetMode) {
    if (isSetMode) {
      return currentStep == 2; // Show back button only on confirm step in set mode
    } else {
      return currentStep > 0; // Show back button after first step in change mode
    }
  }

  Widget _buildPinInputSection(
      MPinChangeController controller, bool isDark, int step) {
    late List<TextEditingController> controllers;
    late List<FocusNode> focusNodes;
    late bool isVisible;
    late VoidCallback toggleVisibility;

    switch (step) {
      case 0:
        controllers = controller.currentPinControllers;
        focusNodes = controller.currentPinFocusNodes;
        isVisible = controller.isCurrentPinVisible.value;
        toggleVisibility = controller.toggleCurrentPinVisibility;
        break;
      case 1:
        controllers = controller.newPinControllers;
        focusNodes = controller.newPinFocusNodes;
        isVisible = controller.isNewPinVisible.value;
        toggleVisibility = controller.toggleNewPinVisibility;
        break;
      case 2:
        controllers = controller.confirmPinControllers;
        focusNodes = controller.confirmPinFocusNodes;
        isVisible = controller.isConfirmPinVisible.value;
        toggleVisibility = controller.toggleConfirmPinVisibility;
        break;
    }

    return Column(
      key: ValueKey(step),
      children: [
        // PIN Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getPinFieldBorderColor(controller, index, step, isDark),
                  width: 2,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => controller.onKeyPressed(event, index, step),
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: !isVisible,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) {
                    controller.onPinChanged(value, index, step);
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Show/Hide PIN Toggle - Fixed to properly update visibility
        GestureDetector(
          onTap: toggleVisibility,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppThemeData.primary200,
              ),
              const SizedBox(width: 8),
              Text(
                isVisible ? 'Hide PIN' : 'Show PIN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemeData.primary200,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get PIN field border color based on focus and input state
  Color _getPinFieldBorderColor(
      MPinChangeController controller, int index, int step, bool isDark) {
    late List<FocusNode> focusNodes;
    late List<TextEditingController> controllers;

    switch (step) {
      case 0:
        focusNodes = controller.currentPinFocusNodes;
        controllers = controller.currentPinControllers;
        break;
      case 1:
        focusNodes = controller.newPinFocusNodes;
        controllers = controller.newPinControllers;
        break;
      case 2:
        focusNodes = controller.confirmPinFocusNodes;
        controllers = controller.confirmPinControllers;
        break;
    }

    // Check if this field is focused
    if (focusNodes[index].hasFocus) {
      return AppThemeData.primary200;
    }

    // Check if this field has content
    if (controllers[index].text.isNotEmpty) {
      return Colors.green.withValues(alpha: 0.6);
    }

    // Default border color
    return isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.3);
  }
}