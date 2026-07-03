import 'dart:math';

import 'package:finway/themes/custom_base_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/account_details_controller.dart';

class AccountDetails extends StatelessWidget {

     AccountDetails({super.key});
    final AccountDetailsController controller = Get.put(AccountDetailsController());
    @override
    Widget build(BuildContext context) {

        final themeChange = Provider.of<DarkThemeProvider>(context);
        final isDark = themeChange.getThem();

        return CustomBaseWidget(
            showAppBar: true,
            appBarTitle: "Smart Value Card",
            body: Obx(() {
              // Show shimmer while loading
              if (controller.isLoading.value) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildShimmerCard(isDark),
                        SizedBox(height: 30),
                        _buildShimmerAccountDetails(isDark),
                      ],
                    ),
                  ),
                );
              }

              // Show actual content when loaded
              return SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          children: [
                            // Your existing flip card code
                            GestureDetector(
                                onTap: controller.flipCard,
                                child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final screenWidth = MediaQuery.of(context).size.width;

                                      // Responsive card height
                                      double cardHeight;
                                      if (screenWidth < 360) {
                                        cardHeight = 200+25;
                                      } else if (screenWidth < 400) {
                                        cardHeight = 220+25;
                                      } else if (screenWidth < 500) {
                                        cardHeight = 240+25;
                                      } else {
                                        cardHeight = 260;
                                      }

                                      return SizedBox(
                                          height: cardHeight,
                                          child: Stack(
                                              children: [
                                                // Glow effect
                                                Positioned.fill(
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(20),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  color: Color(0xFF4CAF50).withValues(alpha: 0.3),
                                                                  blurRadius: 30,
                                                                  spreadRadius: 5
                                                              )
                                                            ]
                                                        )
                                                    )
                                                ),
                                                // Main card
                                                AnimatedBuilder(
                                                    animation: controller.flipAnimation,
                                                    builder: (context, child) {
                                                      final isFrontVisible = controller.flipAnimation.value <= pi / 2;
                                                      return Transform(
                                                          alignment: Alignment.center,
                                                          transform: Matrix4.identity()
                                                            ..setEntry(3, 2, 0.001)
                                                            ..rotateY(controller.flipAnimation.value),
                                                          child: Container(
                                                              width: double.infinity,
                                                              height: cardHeight,
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  gradient: LinearGradient(
                                                                      colors: isFrontVisible
                                                                          ? [
                                                                        Color(0xFF4CAF50),
                                                                        Color(0xFFFFEB3B),
                                                                        Color(0xFFF44336)
                                                                      ]
                                                                          : isDark
                                                                          ? [
                                                                        AppThemeData.grey800,
                                                                        AppThemeData.grey900
                                                                      ]
                                                                          : [
                                                                        AppThemeData.grey800,
                                                                        AppThemeData.grey900
                                                                      ],
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                        color: Colors.black.withValues(alpha: 0.3),
                                                                        blurRadius: 20,
                                                                        offset: Offset(0, 10)
                                                                    )
                                                                  ]
                                                              ),
                                                              child: isFrontVisible
                                                                  ? _buildFrontCard(controller, isDark)
                                                                  : _buildBackCard(controller, isDark)
                                                          )
                                                      );
                                                    }
                                                )
                                              ]
                                          )
                                      );
                                    }
                                )
                            ),

                            SizedBox(height: 30),

                            // Account Details Section
                            _buildAccountDetails(controller, isDark)
                          ]
                      )
                  )
              );
            })

        );
    }

     // Enhanced Beautiful Card UI - Replace your card section

     Widget _buildFrontCard(AccountDetailsController controller, bool isDark) {
       return LayoutBuilder(
           builder: (context, constraints) {
             final screenWidth = MediaQuery.of(context).size.width;

             final bool isSmallScreen = screenWidth < 360;
             final bool isMediumScreen = screenWidth >= 360 && screenWidth < 400;

             // Responsive sizing
             final double bankNameSize = isSmallScreen ? 15 : (isMediumScreen ? 16 : 18);
             final double accountTypeSize = isSmallScreen ? 11 : 12;
             final double cardTypeSize = isSmallScreen ? 10 : 11;
             final double balanceLabelSize = isSmallScreen ? 9 : 10;
             final double amountSize = isSmallScreen ? 22 : (isMediumScreen ? 26 : 28);
             final double cardNumberSize = isSmallScreen ? 17 : (isMediumScreen ? 19 : 20);
             final double bottomLabelSize = isSmallScreen ? 8 : 9;
             final double bottomValueSize = isSmallScreen ? 12 : 13;

             final double topPadding = isSmallScreen ? 18 : (isMediumScreen ? 22 : 24);
             final double horizontalPadding = isSmallScreen ? 18 : (isMediumScreen ? 22 : 24);

             return Stack(
                 children: [
                   // Enhanced Shimmer effect
                   AnimatedBuilder(
                       animation: controller.shimmerAnimation,
                       builder: (context, child) {
                         return Positioned.fill(
                             child: ClipRRect(
                                 borderRadius: BorderRadius.circular(20),
                                 child: Container(
                                     decoration: BoxDecoration(
                                         gradient: LinearGradient(
                                             colors: [
                                               Colors.transparent,
                                               Colors.white.withValues(alpha: 0.15),
                                               Colors.transparent
                                             ],
                                             stops: [0.0, 0.5, 1.0],
                                             begin: Alignment(-1 + controller.shimmerAnimation.value * 1.5, -1),
                                             end: Alignment(1 + controller.shimmerAnimation.value * 1.5, 1)
                                         )
                                     )
                                 )
                             )
                         );
                       }
                   ),

                   // Decorative circles
                   Positioned(
                       top: -50,
                       right: -50,
                       child: Container(
                           width: 150,
                           height: 150,
                           decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                   colors: [
                                     Colors.white.withValues(alpha: 0.08),
                                     Colors.transparent
                                   ]
                               )
                           )
                       )
                   ),

                   Positioned(
                       bottom: -30,
                       left: -30,
                       child: Container(
                           width: 100,
                           height: 100,
                           decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                   colors: [
                                     Colors.white.withValues(alpha: 0.06),
                                     Colors.transparent
                                   ]
                               )
                           )
                       )
                   ),

                   Padding(
                       padding: EdgeInsets.symmetric(
                           horizontal: horizontalPadding,
                           vertical: topPadding
                       ),
                       child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             // Header row with enhanced styling
                             Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Expanded(
                                       child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Text(
                                               controller.bank,
                                               style: TextStyle(
                                                   color: Colors.white,
                                                   fontSize: bankNameSize,
                                                   fontWeight: FontWeight.w700,
                                                   letterSpacing: 0.5,
                                                   shadows: [
                                                     Shadow(
                                                         color: Colors.black26,
                                                         offset: Offset(0, 1),
                                                         blurRadius: 2
                                                     )
                                                   ]
                                               ),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                             SizedBox(height: 3),
                                             Container(
                                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                 decoration: BoxDecoration(
                                                     color: controller.accountType.contains("Active")
                                                         ? Colors.green.withValues(alpha: 0.25)
                                                         : Colors.orange.withValues(alpha: 0.25),
                                                     borderRadius: BorderRadius.circular(12),
                                                     border: Border.all(
                                                         color: controller.accountType.contains("Active")
                                                             ? Colors.green.withValues(alpha: 0.4)
                                                             : Colors.orange.withValues(alpha: 0.4),
                                                         width: 1
                                                     )
                                                 ),
                                                 child: Text(
                                                   controller.accountType,
                                                   style: TextStyle(
                                                       color: Colors.white,
                                                       fontSize: accountTypeSize - 1,
                                                       fontWeight: FontWeight.w600
                                                   ),
                                                   maxLines: 1,
                                                   overflow: TextOverflow.ellipsis,
                                                 )
                                             )
                                           ]
                                       )
                                   ),
                                   SizedBox(width: 8),
                                   Container(
                                       padding: EdgeInsets.symmetric(
                                           horizontal: isSmallScreen ? 10 : 14,
                                           vertical: 6
                                       ),
                                       decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                               colors: [
                                                 Colors.white.withValues(alpha: 0.3),
                                                 Colors.white.withValues(alpha: 0.2)
                                               ],
                                               begin: Alignment.topLeft,
                                               end: Alignment.bottomRight
                                           ),
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(
                                               color: Colors.white.withValues(alpha: 0.3),
                                               width: 1
                                           ),
                                           boxShadow: [
                                             BoxShadow(
                                                 color: Colors.black.withValues(alpha: 0.1),
                                                 blurRadius: 4,
                                                 offset: Offset(0, 2)
                                             )
                                           ]
                                       ),
                                       child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Icon(
                                                 Icons.workspace_premium,
                                                 color: Colors.white,
                                                 size: cardTypeSize + 2
                                             ),
                                             SizedBox(width: 4),
                                             Text(
                                                 controller.cardType,
                                                 style: TextStyle(
                                                     color: Colors.white,
                                                     fontSize: cardTypeSize,
                                                     fontWeight: FontWeight.bold,
                                                     letterSpacing: 0.5
                                                 )
                                             )
                                           ]
                                       )
                                   )
                                 ]
                             ),

                             SizedBox(height: isSmallScreen ? 12 : 16),

                             // Enhanced Balance section
                             Container(
                                 padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                 decoration: BoxDecoration(
                                     gradient: LinearGradient(
                                         colors: [
                                           Colors.white.withValues(alpha: 0.15),
                                           Colors.white.withValues(alpha: 0.08)
                                         ],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight
                                     ),
                                     borderRadius: BorderRadius.circular(16),
                                     border: Border.all(
                                         color: Colors.white.withValues(alpha: 0.2),
                                         width: 1
                                     )
                                 ),
                                 child: Row(
                                     children: [
                                       // Enhanced Chip with glow
                                       Container(
                                           width: isSmallScreen ? 42 : 48,
                                           height: isSmallScreen ? 32 : 38,
                                           decoration: BoxDecoration(
                                               borderRadius: BorderRadius.circular(10),
                                               gradient: LinearGradient(
                                                   colors: [
                                                     Color(0xFFFFD700),
                                                     Color(0xFFFFA500)
                                                   ],
                                                   begin: Alignment.topLeft,
                                                   end: Alignment.bottomRight
                                               ),
                                               boxShadow: [
                                                 BoxShadow(
                                                     color: Color(0xFFFFD700).withValues(alpha: 0.5),
                                                     blurRadius: 8,
                                                     spreadRadius: 0
                                                 )
                                               ]
                                           ),
                                           child: Icon(
                                               Icons.account_balance_wallet_rounded,
                                               color: Colors.white,
                                               size: isSmallScreen ? 18 : 22
                                           )
                                       ),
                                       SizedBox(width: 12),
                                       Expanded(
                                           child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                     "AVAILABLE BALANCE",
                                                     style: TextStyle(
                                                         color: Colors.white70,
                                                         fontSize: balanceLabelSize,
                                                         letterSpacing: 1,
                                                         fontWeight: FontWeight.w600
                                                     )
                                                 ),
                                                 SizedBox(height: 2),
                                                 Text(
                                                   "₹${controller.totalAmount}",
                                                   style: TextStyle(
                                                       color: Colors.white,
                                                       fontSize: amountSize,
                                                       fontWeight: FontWeight.bold,
                                                       letterSpacing: 0.5,
                                                       shadows: [
                                                         Shadow(
                                                             color: Colors.black45,
                                                             offset: Offset(0, 2),
                                                             blurRadius: 4
                                                         )
                                                       ]
                                                   ),
                                                   maxLines: 1,
                                                   overflow: TextOverflow.ellipsis,
                                                 )
                                               ]
                                           )
                                       )
                                     ]
                                 )
                             ),

                             Spacer(),



                             SizedBox(height: isSmallScreen ? 16 : 20),

                             // Bottom row with icons
                             Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 crossAxisAlignment: CrossAxisAlignment.end,
                                 children: [
                                   Expanded(
                                       flex: 2,
                                       child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Row(
                                                 children: [
                                                   Icon(
                                                       Icons.person_outline,
                                                       color: Colors.white60,
                                                       size: bottomLabelSize + 2
                                                   ),
                                                   SizedBox(width: 4),
                                                   Text(
                                                       "CARDHOLDER",
                                                       style: TextStyle(
                                                           color: Colors.white60,
                                                           fontSize: bottomLabelSize,
                                                           letterSpacing: 0.5,
                                                           fontWeight: FontWeight.w600
                                                       )
                                                   ),
                                                 ]
                                             ),
                                             SizedBox(height: 4),
                                             Text(
                                               controller.holderName.toUpperCase(),
                                               style: TextStyle(
                                                   color: Colors.white,
                                                   fontSize: bottomValueSize,
                                                   fontWeight: FontWeight.w700,
                                                   letterSpacing: 0.5,
                                                   shadows: [
                                                     Shadow(
                                                         color: Colors.black26,
                                                         offset: Offset(0, 1),
                                                         blurRadius: 1
                                                     )
                                                   ]
                                               ),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             )
                                           ]
                                       )
                                   ),
                                   SizedBox(width: 12),
                                   Column(
                                       crossAxisAlignment: CrossAxisAlignment.end,
                                       children: [
                                         Row(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               Icon(
                                                   Icons.calendar_today_outlined,
                                                   color: Colors.white60,
                                                   size: bottomLabelSize + 2
                                               ),
                                               SizedBox(width: 4),
                                               Text(
                                                   "VALID FROM",
                                                   style: TextStyle(
                                                       color: Colors.white60,
                                                       fontSize: bottomLabelSize,
                                                       letterSpacing: 0.5,
                                                       fontWeight: FontWeight.w600
                                                   )
                                               ),
                                             ]
                                         ),
                                         SizedBox(height: 4),
                                         Text(
                                             controller.expDate,
                                             style: TextStyle(
                                                 color: Colors.white,
                                                 fontSize: bottomValueSize,
                                                 fontWeight: FontWeight.w700,
                                                 letterSpacing: 1,
                                                 shadows: [
                                                   Shadow(
                                                       color: Colors.black26,
                                                       offset: Offset(0, 1),
                                                       blurRadius: 1
                                                   )
                                                 ]
                                             )
                                         )
                                       ]
                                   )
                                 ]
                             )
                           ]
                       )
                   )
                 ]
             );
           }
       );
     }



     Widget _buildBackCard(AccountDetailsController controller, bool isDark) {
        return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(pi),
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        SizedBox(height: 20),

                        // Magnetic stripe
                        Container(
                            width: double.infinity,
                            height: 45,
                            color: Colors.black87
                        ),

                        SizedBox(height: 30),

                        // Signature panel
                        Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                    children: [
                                        Expanded(
                                            child: Container(
                                                height: double.infinity,
                                                decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(2)
                                                ),
                                                child: Center(
                                                    child: Text(
                                                        "A/c: ${controller.accountNumber}",
                                                        style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 12,
                                                            fontStyle: FontStyle.italic
                                                        )
                                                    )
                                                )
                                            )
                                        ),
                                        SizedBox(width: 10),
                                        Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(color: Colors.grey.shade300)
                                            ),
                                            child: Text(
                                                controller.cvv,
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2
                                                )
                                            )
                                        )
                                    ]
                                )
                            )
                        ),

                        Spacer(),

                        // Bottom text
                        Text(
                            "For customer service call: 1800-XXX-XXXX",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11
                            )
                        ),
                        Text(
                            "This card is property of ${controller.bank}",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11
                            )
                        )
                    ]
                )
            )
        );
    }

    Widget _buildAccountDetails(
        AccountDetailsController controller, bool isDark) {
        return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? AppThemeData.grey800Dark : AppThemeData.grey200
                ),
                boxShadow: [
                    BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4)
                    )
                ]
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        "Account Details",
                        style: TextStyle(
                            color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
                            fontSize: 18,
                            fontWeight: FontWeight.w600
                        )
                    ),
                    SizedBox(height: 20),
                    _buildDetailItem("Card Holder",
                        controller.holderName, Icons.person, isDark),
                    _buildDetailItem("Mobile Number", controller.mobile,
                        Icons.phone, isDark),
                    _buildDetailItem("Account Number", controller.accountNumber,
                        Icons.vpn_key, isDark),
                    _buildDetailItem("Valid From",
                        "${controller.expDays} Days", Icons.timer, isDark),
                    _buildDetailItem("Balance",
                        "₹${controller.amount}", Icons.account_balance_wallet, isDark),
                    _buildDetailItem("Earned Amount",
                        "₹${controller.earnAmount}", Icons.trending_up, isDark)
                ]
            )
        );
    }

    Widget _buildDetailItem(
        String title, String value, IconData icon, bool isDark) {
        return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
                children: [
                    Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppThemeData.primary300Dark.withValues(alpha: 0.2)
                                : AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Icon(
                            icon,
                            color: isDark ? AppThemeData.primary200 : AppThemeData.primary300,
                            size: 20
                        )
                    ),
                    SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    title,
                                    style: TextStyle(
                                        color: isDark ? AppThemeData.grey400 : AppThemeData.grey500,
                                        fontSize: 12
                                    )
                                ),
                                SizedBox(height: 2),
                                Text(
                                    value,
                                    style: TextStyle(
                                        color:
                                        isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500
                                    )
                                )
                            ]
                        )
                    )
                ]
            )
        );
    }


     Widget _buildShimmerCard(bool isDark) {
       return Container(
         height: 240,
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(20),
           gradient: LinearGradient(
             colors: isDark
                 ? [AppThemeData.grey800, AppThemeData.grey900]
                 : [Colors.grey.shade300, Colors.grey.shade400],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
         ),
         child: Stack(
           children: [
             // Animated shimmer effect
             AnimatedBuilder(
               animation: controller.shimmerController,
               builder: (context, child) {
                 return Positioned.fill(
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(20),
                     child: Container(
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [
                             Colors.transparent,
                             Colors.white.withValues(alpha: 0.2),
                             Colors.transparent,
                           ],
                           stops: [0.0, 0.5, 1.0],
                           begin: Alignment(-1 + controller.shimmerController.value * 2, -1),
                           end: Alignment(1 + controller.shimmerController.value * 2, 1),
                         ),
                       ),
                     ),
                   ),
                 );
               },
             ),

             // Placeholder content
             Padding(
               padding: EdgeInsets.all(24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Bank name placeholder
                   Container(
                     width: 120,
                     height: 18,
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.3),
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ),
                   SizedBox(height: 8),
                   // Account type placeholder
                   Container(
                     width: 80,
                     height: 14,
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ),

                   Spacer(),

                   // Balance section placeholder
                   Container(
                     padding: EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(
                           width: 100,
                           height: 10,
                           decoration: BoxDecoration(
                             color: Colors.white.withValues(alpha: 0.3),
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                         SizedBox(height: 8),
                         Container(
                           width: 150,
                           height: 24,
                           decoration: BoxDecoration(
                             color: Colors.white.withValues(alpha: 0.4),
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                       ],
                     ),
                   ),

                   Spacer(),

                   // Bottom info placeholders
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Container(
                             width: 70,
                             height: 10,
                             decoration: BoxDecoration(
                               color: Colors.white.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                           SizedBox(height: 4),
                           Container(
                             width: 100,
                             height: 12,
                             decoration: BoxDecoration(
                               color: Colors.white.withValues(alpha: 0.3),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                         ],
                       ),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Container(
                             width: 60,
                             height: 10,
                             decoration: BoxDecoration(
                               color: Colors.white.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                           SizedBox(height: 4),
                           Container(
                             width: 50,
                             height: 12,
                             decoration: BoxDecoration(
                               color: Colors.white.withValues(alpha: 0.3),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ],
               ),
             ),
           ],
         ),
       );
     }

     Widget _buildShimmerAccountDetails(bool isDark) {
       return Container(
         padding: EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: isDark ? AppThemeData.grey800 : Colors.white,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
             color: isDark ? AppThemeData.grey800Dark : AppThemeData.grey200,
           ),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Container(
               width: 120,
               height: 18,
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                 borderRadius: BorderRadius.circular(4),
               ),
             ),
             SizedBox(height: 20),
             ...List.generate(6, (index) =>
                 Padding(
                   padding: EdgeInsets.only(bottom: 16),
                   child: Row(
                     children: [
                       Container(
                         width: 36,
                         height: 36,
                         decoration: BoxDecoration(
                           color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Container(
                               width: 80,
                               height: 12,
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                             ),
                             SizedBox(height: 4),
                             Container(
                               width: 120,
                               height: 16,
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade400,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
             ),
           ],
         ),
       );
     }

}

/*
import 'dart:math';

import 'package:finway/themes/custom_base_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/account_details_controller.dart';

class AccountDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AccountDetailsController controller =
        Get.put(AccountDetailsController());
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: "Virtual Card",
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Card Section
              GestureDetector(
                onTap: controller.flipCard,
                child: Container(
                  height: 240,
                  child: Stack(
                    children: [
                      // Glow effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Main card
                      AnimatedBuilder(
                        animation: controller.flipAnimation,
                        builder: (context, child) {
                          final isFrontVisible =
                              controller.flipAnimation.value <= pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(controller.flipAnimation.value),
                            child: Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: isFrontVisible
                                      ? [
                                          Color(0xFF4CAF50),
                                          Color(0xFFFFEB3B),
                                          Color(0xFFF44336),
                                        ]
                                      : isDark
                                          ? [
                                              AppThemeData.grey800,
                                              AppThemeData.grey900,
                                            ]
                                          : [
                                              AppThemeData.grey800,
                                              AppThemeData.grey900,
                                            ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: isFrontVisible
                                  ? _buildFrontCard(controller, isDark)
                                  : _buildBackCard(controller, isDark),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Account Details Section
              _buildAccountDetails(controller, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(AccountDetailsController controller, bool isDark) {
    return Stack(
      children: [
        // Shimmer effect
        AnimatedBuilder(
          animation: controller.shimmerAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin:
                          Alignment(-1 + controller.shimmerAnimation.value, -1),
                      end: Alignment(1 + controller.shimmerAnimation.value, 1),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.cardData["bank"] ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        controller.cardData["accountType"] ?? "",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.cardData["cardType"] ?? "",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Chip
              Container(
                width: 45,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFEB3B), Color(0xFFF44336)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              Spacer(),

              // Digital Pocket number center
              Center(
                child: Text(
                  controller.cardData["digitalPocket"] ?? "",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CARD HOLDER",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        controller.cardData["holderName"]?.toUpperCase() ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "EXPIRES",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        controller.cardData["expDate"] ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackCard(AccountDetailsController controller, bool isDark) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // Magnetic stripe
            Container(
              width: double.infinity,
              height: 45,
              color: Colors.black87,
            ),

            SizedBox(height: 30),

            // Signature panel
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            "Authorized Signature",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        controller.cardData["cvv"] ?? "",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),

            // Bottom text
            Text(
              "For customer service call: 1800-XXX-XXXX",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              "This card is property of ${controller.cardData["bank"]}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetails(
      AccountDetailsController controller, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppThemeData.grey800Dark : AppThemeData.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Details",
            style: TextStyle(
              color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          _buildDetailItem("Card Holder",
              controller.cardData["holderName"] ?? "", Icons.person, isDark),
          _buildDetailItem("Mobile Number", controller.cardData["mobile"] ?? "",
              Icons.phone, isDark),
          _buildDetailItem("Member Code", controller.cardData["code"] ?? "",
              Icons.vpn_key, isDark),
          _buildDetailItem("Days to Expire",
              controller.cardData["expDays"] ?? "", Icons.timer, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      String title, String value, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppThemeData.primary300Dark.withOpacity(0.2)
                  : AppThemeData.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? AppThemeData.primary200 : AppThemeData.primary300,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey400 : AppThemeData.grey500,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isDark ? AppThemeData.grey50Dark : AppThemeData.grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/

