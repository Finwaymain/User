import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/pin_entry_controller.dart';

class PinEntryScreen extends StatefulWidget {
  final String paymentData;
  final String amount;
  final bool isQRPayment;

  const PinEntryScreen({
    super.key,
    required this.paymentData,
    required this.amount,
    required this.isQRPayment,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final PinEntryController controller = Get.put(PinEntryController());
  late final FocusNode pinFocusNode;
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    pinFocusNode = FocusNode();
    textController = TextEditingController();

    // Request focus when screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          pinFocusNode.requestFocus();
        }
      });
    });

    // Listen to PIN changes to refocus after clearing
    ever(controller.pin, (value) {
      if (value.isEmpty && mounted) {
        // When PIN is cleared (wrong attempt), refocus after small delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            textController.clear();
            pinFocusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    pinFocusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      appBarTitle: 'Enter PIN',
      showAppBar: true,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Instruction
              Text(
                'Enter your 4-digit PIN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // PIN Dots Display
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < controller.pin.value.length
                          ? AppThemeData.primary200
                          : (isDark ? Colors.grey[600] : Colors.grey[300]),
                    ),
                  );
                }),
              )),

              const SizedBox(height: 40),

              // Hidden TextField for PIN input
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: textController,
                    focusNode: pinFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (value) {
                      controller.pin.value = value;
                      // Removed auto-submit - user must click Confirm button
                    },
                    onSubmitted: (value) {
                      // Keyboard Done button closes keyboard but doesn't submit
                      pinFocusNode.unfocus();
                    },
                  ),
                ),
              ),

              const Spacer(),

              // Tap to focus instruction
              GestureDetector(
                onTap: () {
                  pinFocusNode.requestFocus();
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to enter PIN',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (controller.pin.value.length == 4 &&
                      !controller.isLoading.value)
                      ? () {
                    pinFocusNode.unfocus();
                    controller.processPayment(widget.paymentData,
                        widget.amount, widget.isQRPayment);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm Payment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../themes/constant_colors.dart';
// import '../../../../../themes/custom_base_widget.dart';
// import '../../../../../utils/dark_theme_provider.dart';
// import '../controller/pin_entry_controller.dart';
//
// class PinEntryScreen extends StatelessWidget {
//   final String paymentData;
//   final String amount;
//   final bool isQRPayment;
//   final PinEntryController controller = Get.put(PinEntryController());
//
//   PinEntryScreen({
//     Key? key,
//     required this.paymentData,
//     required this.amount,
//     required this.isQRPayment,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     final isDark = themeChange.getThem();
//
//     final List<String> numbers = [
//       '1',
//       '2',
//       '3',
//       '4',
//       '5',
//       '6',
//       '7',
//       '8',
//       '9',
//       '<',
//       '0',
//       '✓',
//     ];
//
//     return CustomBaseWidget(
//       appBarTitle: 'Enter PIN',
//       showAppBar: true,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Scrollable instruction + PIN dots
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 30),
//
//                     // Instruction
//                     Text(
//                       'Enter your 4-digit PIN',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: isDark ? Colors.white : Colors.black87,
//                       ),
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     // PIN Dots
//                     Obx(() => Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(4, (index) {
//                         return Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 8),
//                           width: 20,
//                           height: 20,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: index < controller.pin.value.length
//                                 ? AppThemeData.primary200
//                                 : (isDark
//                                 ? Colors.grey[600]
//                                 : Colors.grey[300]),
//                           ),
//                         );
//                       }),
//                     )),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Fixed Number Pad at bottom
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.black : Colors.white,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(30),
//                   topRight: Radius.circular(30),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: GridView.builder(
//                 physics: const NeverScrollableScrollPhysics(),
//                 shrinkWrap: true,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   childAspectRatio: 1.5,
//                   mainAxisSpacing: 15,
//                   crossAxisSpacing: 10,
//                 ),
//                 itemCount: numbers.length,
//                 itemBuilder: (context, index) {
//                   final number = numbers[index];
//
//                   return GestureDetector(
//                     onTap: () {
//                       if (number == '<') {
//                         controller.removeDigit();
//                       } else if (number == '✓') {
//                         if (controller.pin.value.length == 4) {
//                           controller.processPayment(
//                               paymentData, amount, isQRPayment);
//                         }
//                       } else if (number.isNotEmpty) {
//                         controller.addDigit(number);
//                       }
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: number == '✓'
//                             ? (controller.pin.value.length == 4
//                             ? Colors.black
//                             : Colors.grey[300])
//                             : (isDark ? Colors.grey[700] : Colors.white),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 5,
//                             spreadRadius: 1,
//                           )
//                         ],
//                       ),
//                       child: number == '<'
//                           ? Icon(Icons.backspace,
//                           color: isDark ? Colors.white : Colors.black87)
//                           : number == '✓'
//                           ? Icon(Icons.check,
//                           size: 50,
//                           color: controller.pin.value.length == 4
//                               ? AppThemeData.primary200
//                               : Colors.white)
//                           : Text(
//                         number,
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color:
//                           isDark ? Colors.white : Colors.black87,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
