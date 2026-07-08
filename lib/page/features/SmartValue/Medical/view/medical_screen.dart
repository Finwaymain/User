
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../color_utils.dart';
import '../controllers/medical_card_controller.dart';
import '../models/card_data.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/hexagon_pattern_painter.dart';
import '../widgets/medical_icons_widget.dart';

class CardDetailsScreen extends StatelessWidget {
    final PurchasedCard purchasedCard;
    final MedicalCardController controller = Get.find<MedicalCardController>();

    CardDetailsScreen({super.key, required this.purchasedCard});

    @override
    Widget build(BuildContext context) {
        final gradientColors = purchasedCard.cardData.gradientColors
            .map((hex) => ColorUtils.hexToColor(hex))
            .toList();

        return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Get.back()
                ),
                title: Text(
                    'Card Details',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold
                    )
                )
            ),
            body: SingleChildScrollView(
                child: Column(
                    children: [
                        // Card Display
                        Padding(
                            padding: EdgeInsets.all(20),
                            child: Card3DWidget(
                                purchasedCard: purchasedCard,
                                isPurchased: true
                            )
                        ),

                        // Card Info
                        Container(
                            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4)
                                    )
                                ]
                            ),
                            child: Column(
                                children: [
                                    _buildInfoRow(
                                        'Card Type',
                                        purchasedCard.cardData.type,
                                        Icons.credit_card,
                                        gradientColors[0]
                                    ),
                                    Divider(height: 30),
                                    _buildInfoRow(
                                        'Total Limit',
                                        '${purchasedCard.cardData.limit.toStringAsFixed(0)}',
                                        Icons.account_balance_wallet,
                                        gradientColors[0]
                                    ),
                                    Divider(height: 30),
                                    _buildInfoRow(
                                        'Available Balance',
                                        '${purchasedCard.balance.toStringAsFixed(0)}',
                                        Icons.account_balance,
                                        Colors.green
                                    ),
                                    Divider(height: 30),
                                    _buildInfoRow(
                                        'Purchase Date',
                                        '${purchasedCard.purchaseDate.day}/${purchasedCard.purchaseDate.month}/${purchasedCard.purchaseDate.year}',
                                        Icons.calendar_today,
                                        gradientColors[0]
                                    )
                                ]
                            )
                        ),

                        // Claims History
                        if (purchasedCard.claims.isNotEmpty)
                        Container(
                            margin: EdgeInsets.all(20),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4)
                                    )
                                ]
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        'Claims History',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87
                                        )
                                    ),
                                    SizedBox(height: 16),
                                    ...purchasedCard.claims.map((claim) => _buildClaimItem(claim, gradientColors[0]))
                                ]
                            )
                        ),

                        // Claim Button
                        Padding(
                            padding: EdgeInsets.all(20),
                            child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                    onPressed: () {
                                        Get.to(() => ClaimFormScreen(purchasedCard: purchasedCard));
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: gradientColors[0],
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)
                                        ),
                                        elevation: 4,
                                        shadowColor: gradientColors[0].withValues(alpha: 0.4)
                                    ),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Icon(Icons.add_circle_outline, size: 24),
                                            SizedBox(width: 12),
                                            Text(
                                                'Submit New Claim',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5
                                                )
                                            )
                                        ]
                                    )
                                )
                            )
                        )
                    ]
                )
            )
        );
    }

    Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
        return Row(
            children: [
                Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(icon, color: color, size: 20)
                ),
                SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                label,
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13
                                )
                            ),
                            SizedBox(height: 4),
                            Text(
                                value,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                )
                            )
                        ]
                    )
                )
            ]
        );
    }

    Widget _buildClaimItem(ClaimRecord claim, Color color) {
        return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!)
            ),
            child: Column(
                children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                '${claim.approvedAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: color
                                )
                            ),
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: _getStatusColor(claim.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                child: Text(
                                    claim.status.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                        color: _getStatusColor(claim.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold
                                    )
                                )
                            )
                        ]
                    ),
                    SizedBox(height: 8),
                    Row(
                        children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Text(
                                '${claim.fromDate.day}/${claim.fromDate.month}/${claim.fromDate.year} - ${claim.toDate.day}/${claim.toDate.month}/${claim.toDate.year}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]
                                )
                            )
                        ]
                    )
                ]
            )
        );
    }

    Color _getStatusColor(ClaimStatus status) {
        switch (status) {
            case ClaimStatus.approved:
                return Colors.green;
            case ClaimStatus.pending:
                return Colors.orange;
            case ClaimStatus.rejected:
                return Colors.red;
        }
    }
}

class ClaimFormScreen extends StatefulWidget {
    final PurchasedCard purchasedCard;

    const ClaimFormScreen({super.key, required this.purchasedCard});

    @override
    _ClaimFormScreenState createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
    final MedicalCardController controller = Get.find<MedicalCardController>();
    final _formKey = GlobalKey<FormState>();
    final ImagePicker _picker = ImagePicker();

    File? prescriptionFile;
    File? menuFile;
    File? dischargeDocFile;

    final TextEditingController amountController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;

    @override
    void dispose() {
        amountController.dispose();
        super.dispose();
    }

    Future<void> _pickDocument(String type) async {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
            setState(() {
                    switch (type) {
                        case 'prescription':
                            prescriptionFile = File(image.path);
                            break;
                        case 'menu':
                            menuFile = File(image.path);
                            break;
                        case 'discharge':
                            dischargeDocFile = File(image.path);
                            break;
                    }
                }
            );
        }
    }

    Future<void> _selectDate(BuildContext context, bool isFromDate) async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now().subtract(Duration(days: 365)),
            lastDate: DateTime.now(),
            builder: (context, child) {
                return Theme(
                    data: ThemeData.light().copyWith(
                        primaryColor: ColorUtils.hexToColor(widget.purchasedCard.cardData.gradientColors[0]),
                        colorScheme: ColorScheme.light(
                            primary: ColorUtils.hexToColor(widget.purchasedCard.cardData.gradientColors[0])
                        )
                    ),
                    child: child!
                );
            }
        );

        if (picked != null) {
            setState(() {
                    if (isFromDate) {
                        fromDate = picked;
                    }
                    else {
                        toDate = picked;
                    }
                }
            );
        }
    }

    void _submitClaim() {
        if (_formKey.currentState!.validate() &&
            prescriptionFile != null &&
            menuFile != null &&
            dischargeDocFile != null &&
            fromDate != null &&
            toDate != null) {

            final claim = ClaimRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                prescriptionPath: prescriptionFile!.path,
                menuPath: menuFile!.path,
                dischargeDocPath: dischargeDocFile!.path,
                claimAmount: double.parse(amountController.text),
                approvedAmount: double.parse(amountController.text), // Auto-approve for demo
                fromDate: fromDate!,
                toDate: toDate!,
                submittedDate: DateTime.now(),
                status: ClaimStatus.approved
            );

            controller.submitClaim(widget.purchasedCard, claim);

            Get.back();
            Get.back();

            Get.snackbar(
                'Success',
                'Claim submitted successfully! ${claim.approvedAmount.toStringAsFixed(0)} added to your balance.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                margin: EdgeInsets.all(16),
                borderRadius: 12,
                duration: Duration(seconds: 3)
            );
        }
        else {
            Get.snackbar(
                'Error',
                'Please fill all fields and upload all documents',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                margin: EdgeInsets.all(16),
                borderRadius: 12
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        final gradientColors = widget.purchasedCard.cardData.gradientColors
            .map((hex) => ColorUtils.hexToColor(hex))
            .toList();

        return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Get.back()
                ),
                title: Text(
                    'Submit Claim',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold
                    )
                )
            ),
            body: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Header
                            Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: gradientColors),
                                    borderRadius: BorderRadius.circular(16)
                                ),
                                child: Row(
                                    children: [
                                        Icon(Icons.medical_services, color: Colors.white, size: 32),
                                        SizedBox(width: 16),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text(
                                                        widget.purchasedCard.cardData.type,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold
                                                        )
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                        'Available: ${widget.purchasedCard.balance.toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                            color: Colors.white.withValues(alpha: 0.9),
                                                            fontSize: 14
                                                        )
                                                    )
                                                ]
                                            )
                                        )
                                    ]
                                )
                            ),

                            SizedBox(height: 24),

                            // Document Uploads
                            Text(
                                'Upload Documents',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                )
                            ),
                            SizedBox(height: 16),

                            _buildDocumentUpload(
                                'Prescription',
                                'Upload your prescription',
                                Icons.description,
                                prescriptionFile,
                                () => _pickDocument('prescription'),
                                gradientColors[0]
                            ),

                            SizedBox(height: 12),

                            _buildDocumentUpload(
                                'Medical Menu/Bill',
                                'Upload menu or bill',
                                Icons.receipt_long,
                                menuFile,
                                () => _pickDocument('menu'),
                                gradientColors[0]
                            ),

                            SizedBox(height: 12),

                            _buildDocumentUpload(
                                'Discharge Document',
                                'Upload discharge summary',
                                Icons.assignment,
                                dischargeDocFile,
                                () => _pickDocument('discharge'),
                                gradientColors[0]
                            ),

                            SizedBox(height: 24),

                            // Claim Amount
                            Text(
                                'Claim Details',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                )
                            ),
                            SizedBox(height: 16),

                            TextFormField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: 'Claim Amount',
                                    prefixText: '',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    filled: true,
                                    fillColor: Colors.white
                                ),
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                                        return 'Please enter claim amount';
                                    }
                                    return null;
                                }
                            ),

                            SizedBox(height: 16),

                            // Date Range
                            Row(
                                children: [
                                    Expanded(
                                        child: _buildDateField(
                                            'From Date',
                                            fromDate,
                                            () => _selectDate(context, true)
                                        )
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _buildDateField(
                                            'To Date',
                                            toDate,
                                            () => _selectDate(context, false)
                                        )
                                    )
                                ]
                            ),

                            SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                    onPressed: _submitClaim,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: gradientColors[0],
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)
                                        ),
                                        elevation: 4
                                    ),
                                    child: Text(
                                        'Submit Claim',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5
                                        )
                                    )
                                )
                            )
                        ]
                    )
                )
            )
        );
    }

    Widget _buildDocumentUpload(
        String title,
        String subtitle,
        IconData icon,
        File? file,
        VoidCallback onTap,
        Color color
    ) {
        return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: file != null ? color : Colors.grey[300]!,
                        width: file != null ? 2 : 1
                    )
                ),
                child: Row(
                    children: [
                        Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: file != null ? color.withValues(alpha: 0.1) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Icon(
                                file != null ? Icons.check_circle : icon,
                                color: file != null ? color : Colors.grey[600],
                                size: 24
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87
                                        )
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                        file != null ? 'Document uploaded' : subtitle,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600]
                                        )
                                    )
                                ]
                            )
                        ),
                        Icon(
                            Icons.upload_file,
                            color: Colors.grey[400]
                        )
                    ]
                )
            )
        );
    }

    Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
        return InkWell(
            onTap: onTap,
            child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!)
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            label,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]
                            )
                        ),
                        SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                    date != null
                                        ? '${date.day}/${date.month}/${date.year}'
                                        : 'Select date',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: date != null ? Colors.black87 : Colors.grey[500]
                                    )
                                ),
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[400])
                            ]
                        )
                    ]
                )
            )
        );
    }
}

class MedicalScreen extends StatelessWidget {
    final MedicalCardController controller = Get.find<MedicalCardController>();

  MedicalScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: CustomScrollView(
                slivers: [
                    // Custom App Bar
                    AppBarWidget(),

                    // My Cards Section
                    Obx(() => controller.purchasedCards.isNotEmpty
                            ? MyCardsSection()
                            : SliverToBoxAdapter(child: SizedBox.shrink())),

                    // Available Cards Section
                    AvailableCardsSection(),

                    SliverToBoxAdapter(child: SizedBox(height: 20))
                ]
            )
        );
    }
}

class MyCardsSection extends StatelessWidget {
    final MedicalCardController controller = Get.find<MedicalCardController>();

  MyCardsSection({super.key});

    @override
    Widget build(BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return SliverToBoxAdapter(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Section Header
                    Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            'My Cards',
                                            style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1F2937),
                                                letterSpacing: -0.5
                                            )
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                            'Active medical cashback cards',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF6B7280),
                                                fontWeight: FontWeight.w500
                                            )
                                        )
                                    ]
                                ),
                                Obx(() => Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                                BoxShadow(
                                                    color: Color(0xFF2563EB).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 4)
                                                )
                                            ]
                                        ),
                                        child: Row(
                                            children: [
                                                Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                        color: Colors.greenAccent,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                            BoxShadow(
                                                                color: Colors.greenAccent.withValues(alpha: 0.5),
                                                                blurRadius: 4,
                                                                spreadRadius: 1
                                                            )
                                                        ]
                                                    )
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                    '${controller.purchasedCards.length} Active',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                        letterSpacing: 0.5
                                                    )
                                                )
                                            ]
                                        )
                                    ))
                            ]
                        )
                    ),

                    SizedBox(height: 20),

                    // ViewPager Style Cards with Eye Button
                    Obx(() => SizedBox(
                            height: 286,
                            child: PageView.builder(
                                controller: PageController(
                                    viewportFraction: 0.85, // Center card visible with side cards peeking
                                    initialPage: 0
                                ),
                                itemCount: controller.purchasedCards.length,
                                itemBuilder: (context, index) {
                                    final card = controller.purchasedCards[index];
                                    return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                        child: Stack(
                                            children: [
                                                // Card - Clickable for flip
                                                Card3DWidget(
                                                    purchasedCard: card,
                                                    isPurchased: true
                                                )

                                            ]
                                        )
                                    );
                                }
                            )
                        ))

                ]
            )
        );
    }
}

class AvailableCardsSection extends StatelessWidget {
    final MedicalCardController controller = Get.find<MedicalCardController>();

  AvailableCardsSection({super.key});

    @override
    Widget build(BuildContext context) {
        return SliverToBoxAdapter(
            child: Obx(() => Padding(
                    padding: EdgeInsets.fromLTRB(
                        20,
                        controller.purchasedCards.isEmpty ? 20 : 24,
                        20,
                        20
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                controller.purchasedCards.isEmpty
                                    ? 'Available Medical Cards'
                                    : 'More Cards',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                )
                            ),
                            SizedBox(height: 8),
                            Text(
                                'Choose the perfect medical card for your needs',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14
                                )
                            ),
                            SizedBox(height: 20),
                            ...controller.availableCards
                                .map((card) => CardItemWidget(card: card))
                                
                        ]
                    )
                ))
        );
    }
}

class Card3DWidget extends StatefulWidget {
  final PurchasedCard? purchasedCard;
  final CardData? cardData;
  final bool isPurchased;

  const Card3DWidget({
    super.key,
    this.purchasedCard,
    this.cardData,
    this.isPurchased = false,
  }) : assert(purchasedCard != null || cardData != null,
  'Either purchasedCard or cardData must be provided');

  @override
  _Card3DWidgetState createState() => _Card3DWidgetState();
}

class _Card3DWidgetState extends State<Card3DWidget>
    with TickerProviderStateMixin {
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  late AnimationController _shimmerController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this
    );
    _elevationAnimation = Tween<double>(begin: 8, end: 20).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );

    _shimmerController = AnimationController(
        duration: Duration(seconds: 3),
        vsync: this
    )..repeat();

    _flipController = AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this
    );

    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
    }
    else {
      _flipController.forward();
    }
  }

  CardData get card => widget.purchasedCard?.cardData ?? widget.cardData!;

  @override
  Widget build(BuildContext context) {
    final gradientColors = card.gradientColors
        .map((hex) => ColorUtils.hexToColor(hex))
        .toList();

    return Container(
        margin: EdgeInsets.only(bottom: 20),
        child: GestureDetector(
            onTap: _handleFlip, // CHANGED: Always flip on tap
            child: MouseRegion(
                onEnter: (_) => _animationController.forward(),
                onExit: (_) {
                  _animationController.reverse();
                  setState(() {
                    _rotationX = 0;
                    _rotationY = 0;
                  }
                  );
                },
                onHover: (event) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  final centerX = box.size.width / 2;
                  final centerY = box.size.height / 2;

                  setState(() {
                    _rotationY = (localPosition.dx - centerX) / centerX * 0.08;
                    _rotationX = -(localPosition.dy - centerY) / centerY * 0.08;
                  }
                  );
                },
                child: AnimatedBuilder(
                    animation: Listenable.merge([_animationController, _flipAnimation]),
                    builder: (context, child) {
                      final angle = _flipAnimation.value;
                      final isFrontVisible = angle < math.pi / 2;

                      return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle)
                            ..rotateX(_rotationX)
                            ..rotateY(_rotationY),
                          alignment: Alignment.center,
                          child: isFrontVisible
                              ? _buildCardFront(gradientColors)
                              : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: _buildCardBack(gradientColors)
                          )
                      );
                    }
                )
            )
        )
    );
  }

  Widget _buildCardFront(List<Color> gradientColors) {
    return Container(
        height: 240,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                  spreadRadius: 2
              ),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: Offset(0, 8)
              )
            ]
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
                children: [
                  // Gradient Background
                  Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                          )
                      )
                  ),

                  // Hexagon Pattern
                  if (card.cardDesign.hasPattern)
                    CustomPaint(
                        painter: HexagonPatternPainter(),
                        size: Size.infinite
                    ),

                  // Animated Shimmer Effect
                  Positioned.fill(
                      child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment(-1.0, -0.3),
                                        end: Alignment(1.0, 0.3),
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.transparent
                                        ],
                                        stops: [
                                          _shimmerController.value - 0.3,
                                          _shimmerController.value,
                                          _shimmerController.value + 0.3
                                        ]
                                    )
                                )
                            );
                          }
                      )
                  ),

                  // Hover Shine Effect
                  Positioned.fill(
                      child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Container(
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                        center: Alignment(_rotationY * 2, _rotationX * 2),
                                        radius: 1.5,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.2 * _animationController.value),
                                          Colors.transparent
                                        ]
                                    )
                                )
                            );
                          }
                      )
                  ),

                  // Medical Icons
                  if (card.cardDesign.showIcons)
                    Positioned(
                        right: 20,
                        top: 35,
                        child: Opacity(
                            opacity: 0.4,
                            child: MedicalIconsWidget()
                        )
                    ),

                  // Card Content
                  Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Section
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      child: Text(
                                          'FIINWAY',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2
                                          )
                                      )
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                      card.name,
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600
                                      )
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                height: 1.2
                                            )
                                        ),
                                        Text(
                                            widget.isPurchased
                                                ? widget.purchasedCard!.balance.toStringAsFixed(0)
                                                : card.limit.toStringAsFixed(0),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      blurRadius: 8
                                                  )
                                                ]
                                            )
                                        )
                                      ]
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                      widget.isPurchased ? 'Available Balance' : 'Card Limit',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500
                                      )
                                  )
                                ]
                            ),

                            // Bottom Section
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'CARD NUMBER',
                                                  style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.7),
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1
                                                  )
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                  widget.isPurchased
                                                      ? widget.purchasedCard!.cardNumber
                                                      : card.cardDesign.cardNumber,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 2.5
                                                  )
                                              )
                                            ]
                                        ),
                                        // Container(
                                        //     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        //     decoration: BoxDecoration(
                                        //         color: Colors.white.withOpacity(0.25),
                                        //         borderRadius: BorderRadius.circular(8)
                                        //     ),
                                        //     child: Text(
                                        //         card.type,
                                        //         style: TextStyle(
                                        //             color: Colors.white,
                                        //             fontSize: 11,
                                        //             fontWeight: FontWeight.w700,
                                        //             letterSpacing: 0.5
                                        //         )
                                        //     )
                                        // )
                                      ]
                                  ),

                                ]
                            )
                          ]
                      )
                  ),

                  // Corner chip design
                  Positioned(
                      right: 24,
                      bottom: 76,
                      child: Container(
                          width: 45,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.6),
                                  width: 1.5
                              )
                          )
                      )
                  ),

                  // Eye Button - CHANGED: Stop propagation to prevent flip
                  if (widget.purchasedCard != null)
                    Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                            onTap: () {
                              // Navigate to details screen without flipping
                              Get.to(() => CardDetailsScreen(
                                  purchasedCard: widget.purchasedCard!
                              ));
                            },
                            child: Material(
                                color: Colors.transparent,
                                child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: Offset(0, 3)
                                          )
                                        ],
                                        border: Border.all(
                                            color: ColorUtils.hexToColor(
                                                widget.purchasedCard!.cardData.gradientColors[0])
                                                .withValues(alpha: 0.3),
                                            width: 2
                                        )
                                    ),
                                    child: Icon(
                                        Icons.visibility,
                                        color: ColorUtils.hexToColor(
                                            widget.purchasedCard!.cardData.gradientColors[0]),
                                        size: 22
                                    )
                                )
                            )
                        )
                    )
                ]
            )
        )
    );
  }

  Widget _buildCardBack(List<Color> gradientColors) {
    return Container(
        height: 230,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                  spreadRadius: 2
              ),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: Offset(0, 8)
              )
            ]
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight
                    )
                ),
                child: Stack(
                    children: [
                      // Hexagon Pattern
                      if (card.cardDesign.hasPattern)
                        CustomPaint(
                            painter: HexagonPatternPainter(),
                            size: Size.infinite
                        ),

                      Padding(
                          padding: EdgeInsets.all(28),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20)
                                          ),
                                          child: Text(
                                              'FIINWAY',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 2
                                              )
                                          )
                                      ),
                                      Icon(
                                          Icons.contactless,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          size: 32
                                      )
                                    ]
                                ),

                                SizedBox(height: 14),

                                // Magnetic Strip
                                Container(
                                    width: double.infinity,
                                    height: 25,
                                    decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(4)
                                    )
                                ),

                                SizedBox(height: 10),

                                // CVV Section
                                Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'CVV',
                                                    style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600
                                                    )
                                                ),
                                                Text(
                                                    '•••',
                                                    style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 3
                                                    )
                                                )
                                              ]
                                          ),
                                          Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                    'VALID THRU',
                                                    style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600
                                                    )
                                                ),
                                                Text(
                                                    '12/28',
                                                    style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700
                                                    )
                                                )
                                              ]
                                          )
                                        ]
                                    )
                                ),

                                Spacer(),

                                // Footer Info
                                Text(
                                    'For customer service call: 1800-XXX-XXXX',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 9
                                    )
                                ),
                                SizedBox(height: 4),
                                Text(
                                    'This card is property of FIINWAY',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 9
                                    )
                                )
                              ]
                          )
                      )
                    ]
                )
            )
        )
    );
  }
}

// class Card3DWidget extends StatefulWidget {
//   final PurchasedCard? purchasedCard;
//   final CardData? cardData;
//   final bool isPurchased;
//
//   const Card3DWidget({
//     Key? key,
//     this.purchasedCard,
//     this.cardData,
//     this.isPurchased = false,
//   }) : assert(purchasedCard != null || cardData != null,
//   'Either purchasedCard or cardData must be provided'),
//         super(key: key);
//
//   @override
//   _Card3DWidgetState createState() => _Card3DWidgetState();
// }
//
// class _Card3DWidgetState extends State<Card3DWidget>
//     with TickerProviderStateMixin {
//     double _rotationX = 0.0;
//     double _rotationY = 0.0;
//     late AnimationController _animationController;
//     late Animation<double> _elevationAnimation;
//     late AnimationController _shimmerController;
//     late AnimationController _flipController;
//     late Animation<double> _flipAnimation;
//
//     @override
//     void initState() {
//         super.initState();
//         _animationController = AnimationController(
//             duration: Duration(milliseconds: 300),
//             vsync: this
//         );
//         _elevationAnimation = Tween<double>(begin: 8, end: 20).animate(
//             CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
//         );
//
//         _shimmerController = AnimationController(
//             duration: Duration(seconds: 3),
//             vsync: this
//         )..repeat();
//
//         _flipController = AnimationController(
//             duration: Duration(milliseconds: 800),
//             vsync: this
//         );
//
//         _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
//             CurvedAnimation(parent: _flipController, curve: Curves.easeInOut)
//         );
//     }
//
//     @override
//     void dispose() {
//         _animationController.dispose();
//         _shimmerController.dispose();
//         _flipController.dispose();
//         super.dispose();
//     }
//
//     void _handleFlip() {
//         if (_flipController.isCompleted) {
//             _flipController.reverse();
//         }
//         else {
//             _flipController.forward();
//         }
//     }
//
//     CardData get card => widget.purchasedCard?.cardData ?? widget.cardData!;
//
//     @override
//     Widget build(BuildContext context) {
//         final gradientColors = card.gradientColors
//             .map((hex) => ColorUtils.hexToColor(hex))
//             .toList();
//
//         return Container(
//             margin: EdgeInsets.only(bottom: 20),
//             child: GestureDetector(
//                 onTap: widget.isPurchased
//                     ? () {
//                         Get.to(() => CardDetailsScreen(
//                                 purchasedCard: widget.purchasedCard!
//                             ));
//                     }
//                     : _handleFlip,
//                 child: MouseRegion(
//                     onEnter: (_) => _animationController.forward(),
//                     onExit: (_) {
//                         _animationController.reverse();
//                         setState(() {
//                                 _rotationX = 0;
//                                 _rotationY = 0;
//                             }
//                         );
//                     },
//                     onHover: (event) {
//                         final box = context.findRenderObject() as RenderBox;
//                         final localPosition = box.globalToLocal(event.position);
//                         final centerX = box.size.width / 2;
//                         final centerY = box.size.height / 2;
//
//                         setState(() {
//                                 _rotationY = (localPosition.dx - centerX) / centerX * 0.08;
//                                 _rotationX = -(localPosition.dy - centerY) / centerY * 0.08;
//                             }
//                         );
//                     },
//                     child: AnimatedBuilder(
//                         animation: Listenable.merge([_animationController, _flipAnimation]),
//                         builder: (context, child) {
//                             final angle = _flipAnimation.value;
//                             final isFrontVisible = angle < math.pi / 2;
//
//                             return Transform(
//                                 transform: Matrix4.identity()
//                                 ..setEntry(3, 2, 0.001)
//                                 ..rotateY(angle)
//                                 ..rotateX(_rotationX)
//                                 ..rotateY(_rotationY),
//                                 alignment: Alignment.center,
//                                 child: isFrontVisible
//                                     ? _buildCardFront(gradientColors)
//                                     : Transform(
//                                         alignment: Alignment.center,
//                                         transform: Matrix4.rotationY(math.pi),
//                                         child: _buildCardBack(gradientColors)
//                                     )
//                             );
//                         }
//                     )
//                 )
//             )
//         );
//     }
//
//     Widget _buildCardFront(List<Color> gradientColors) {
//         return Container(
//             height: 240,
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                     BoxShadow(
//                         color: gradientColors[0].withOpacity(0.3),
//                         blurRadius: _elevationAnimation.value,
//                         offset: Offset(0, _elevationAnimation.value / 2),
//                         spreadRadius: 2
//                     ),
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 15,
//                         offset: Offset(0, 8)
//                     )
//                 ]
//             ),
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(24),
//                 child: Stack(
//                     children: [
//                         // Gradient Background
//                         Container(
//                             decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                     colors: gradientColors,
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight
//                                 )
//                             )
//                         ),
//
//                         // Hexagon Pattern
//                         if (card.cardDesign.hasPattern)
//                         CustomPaint(
//                             painter: HexagonPatternPainter(),
//                             size: Size.infinite
//                         ),
//
//                         // Animated Shimmer Effect
//                         Positioned.fill(
//                             child: AnimatedBuilder(
//                                 animation: _shimmerController,
//                                 builder: (context, child) {
//                                     return Container(
//                                         decoration: BoxDecoration(
//                                             gradient: LinearGradient(
//                                                 begin: Alignment(-1.0, -0.3),
//                                                 end: Alignment(1.0, 0.3),
//                                                 colors: [
//                                                     Colors.transparent,
//                                                     Colors.white.withOpacity(0.15),
//                                                     Colors.transparent
//                                                 ],
//                                                 stops: [
//                                                     _shimmerController.value - 0.3,
//                                                     _shimmerController.value,
//                                                     _shimmerController.value + 0.3
//                                                 ]
//                                             )
//                                         )
//                                     );
//                                 }
//                             )
//                         ),
//
//                         // Hover Shine Effect
//                         Positioned.fill(
//                             child: AnimatedBuilder(
//                                 animation: _animationController,
//                                 builder: (context, child) {
//                                     return Container(
//                                         decoration: BoxDecoration(
//                                             gradient: RadialGradient(
//                                                 center: Alignment(_rotationY * 2, _rotationX * 2),
//                                                 radius: 1.5,
//                                                 colors: [
//                                                     Colors.white.withOpacity(0.2 * _animationController.value),
//                                                     Colors.transparent
//                                                 ]
//                                             )
//                                         )
//                                     );
//                                 }
//                             )
//                         ),
//
//                         // Medical Icons
//                         if (card.cardDesign.showIcons)
//                         Positioned(
//                             right: 20,
//                             top: 35,
//                             child: Opacity(
//                                 opacity: 0.4,
//                                 child: MedicalIconsWidget()
//                             )
//                         ),
//
//                         // Card Content
//                         Padding(
//                             padding: EdgeInsets.all(28),
//                             child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                     // Top Section
//                                     Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                             Container(
//                                                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                                 decoration: BoxDecoration(
//                                                     color: Colors.white.withOpacity(0.2),
//                                                     borderRadius: BorderRadius.circular(20)
//                                                 ),
//                                                 child: Text(
//                                                     'FIINWAY',
//                                                     style: TextStyle(
//                                                         color: Colors.white,
//                                                         fontSize: 12,
//                                                         fontWeight: FontWeight.w700,
//                                                         letterSpacing: 2
//                                                     )
//                                                 )
//                                             ),
//                                             SizedBox(height: 12),
//                                             Text(
//                                                 card.name,
//                                                 style: TextStyle(
//                                                     color: Colors.white.withOpacity(0.9),
//                                                     fontSize: 15,
//                                                     fontWeight: FontWeight.w600
//                                                 )
//                                             ),
//                                             SizedBox(height: 8),
//                                             Row(
//                                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                                 children: [
//                                                     Text(
//                                                         '',
//                                                         style: TextStyle(
//                                                             color: Colors.white,
//                                                             fontSize: 20,
//                                                             fontWeight: FontWeight.w600,
//                                                             height: 1.2
//                                                         )
//                                                     ),
//                                                     Text(
//                                                         widget.isPurchased
//                                                             ? widget.purchasedCard!.balance.toStringAsFixed(0)
//                                                             : card.limit.toStringAsFixed(0),
//                                                         style: TextStyle(
//                                                             color: Colors.white,
//                                                             fontSize: 32,
//                                                             fontWeight: FontWeight.w800,
//                                                             letterSpacing: 1,
//                                                             shadows: [
//                                                                 Shadow(
//                                                                     color: Colors.black.withOpacity(0.3),
//                                                                     blurRadius: 8
//                                                                 )
//                                                             ]
//                                                         )
//                                                     )
//                                                 ]
//                                             ),
//                                             SizedBox(height: 4),
//                                             Text(
//                                                 widget.isPurchased ? 'Available Balance' : 'Card Limit',
//                                                 style: TextStyle(
//                                                     color: Colors.white.withOpacity(0.75),
//                                                     fontSize: 11,
//                                                     fontWeight: FontWeight.w500
//                                                 )
//                                             )
//                                         ]
//                                     ),
//
//                                     // Bottom Section
//                                     Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                             Row(
//                                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                 children: [
//                                                     Column(
//                                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                                         children: [
//                                                             Text(
//                                                                 'CARD NUMBER',
//                                                                 style: TextStyle(
//                                                                     color: Colors.white.withOpacity(0.7),
//                                                                     fontSize: 9,
//                                                                     fontWeight: FontWeight.w600,
//                                                                     letterSpacing: 1
//                                                                 )
//                                                             ),
//                                                             SizedBox(height: 6),
//                                                             Text(
//                                                                 widget.isPurchased
//                                                                     ? widget.purchasedCard!.cardNumber
//                                                                     : card.cardDesign.cardNumber,
//                                                                 style: TextStyle(
//                                                                     color: Colors.white,
//                                                                     fontSize: 16,
//                                                                     fontWeight: FontWeight.w600,
//                                                                     letterSpacing: 2.5
//                                                                 )
//                                                             )
//                                                         ]
//                                                     ),
//                                                     Container(
//                                                         padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                                         decoration: BoxDecoration(
//                                                             color: Colors.white.withOpacity(0.25),
//                                                             borderRadius: BorderRadius.circular(8)
//                                                         ),
//                                                         child: Text(
//                                                             card.type,
//                                                             style: TextStyle(
//                                                                 color: Colors.white,
//                                                                 fontSize: 11,
//                                                                 fontWeight: FontWeight.w700,
//                                                                 letterSpacing: 0.5
//                                                             )
//                                                         )
//                                                     )
//                                                 ]
//                                             )
//                                         ]
//                                     )
//                                 ]
//                             )
//                         ),
//
//                         // Corner chip design
//                         Positioned(
//                             right: 24,
//                             bottom: 76,
//                             child: Container(
//                                 width: 45,
//                                 height: 32,
//                                 decoration: BoxDecoration(
//                                     color: Colors.amber.withOpacity(0.3),
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                         color: Colors.amber.withOpacity(0.6),
//                                         width: 1.5
//                                     )
//                                 )
//                             )
//                         ),
//
//                       if (widget.purchasedCard != null)
//                         Positioned(
//                             top: 12,
//                             right: 12,
//                             child: Material(
//                                 color: Colors.transparent,
//                                 child: InkWell(
//                                     onTap: () {
//                                         // Navigate to details screen
//                                       Get.to(() => CardDetailsScreen(
//                                           purchasedCard: widget.purchasedCard!
//                                       ));
//
//                                     },
//                                     borderRadius: BorderRadius.circular(30),
//                                     child: Container(
//                                         padding: EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                             color: Colors.white.withOpacity(0.95),
//                                             shape: BoxShape.circle,
//                                             boxShadow: [
//                                                 BoxShadow(
//                                                     color: Colors.black.withOpacity(0.15),
//                                                     blurRadius: 8,
//                                                     offset: Offset(0, 3)
//                                                 )
//                                             ],
//                                             border: Border.all(
//                                                 color: ColorUtils.hexToColor(
//                                                     widget.purchasedCard!.cardData.gradientColors[0])
//                                                     .withOpacity(0.3),
//                                                 width: 2
//                                             )
//                                         ),
//                                         child: Icon(
//                                             Icons.visibility,
//                                             color: ColorUtils.hexToColor(
//                                                 widget.purchasedCard!.cardData.gradientColors[0]),
//                                             size: 22
//                                         )
//                                     )
//                                 )
//                             )
//                         )
//                     ]
//                 )
//             )
//         );
//     }
//
//     Widget _buildCardBack(List<Color> gradientColors) {
//         return Container(
//             height: 230,
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                     BoxShadow(
//                         color: gradientColors[0].withOpacity(0.3),
//                         blurRadius: _elevationAnimation.value,
//                         offset: Offset(0, _elevationAnimation.value / 2),
//                         spreadRadius: 2
//                     ),
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 15,
//                         offset: Offset(0, 8)
//                     )
//                 ]
//             ),
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(24),
//                 child: Container(
//                     decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                             colors: gradientColors,
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight
//                         )
//                     ),
//                     child: Stack(
//                         children: [
//                             // Hexagon Pattern
//                             if (card.cardDesign.hasPattern)
//                             CustomPaint(
//                                 painter: HexagonPatternPainter(),
//                                 size: Size.infinite
//                             ),
//
//                             Padding(
//                                 padding: EdgeInsets.all(28),
//                                 child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                         // Header
//                                         Row(
//                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                             children: [
//                                                 Container(
//                                                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                                     decoration: BoxDecoration(
//                                                         color: Colors.white.withOpacity(0.2),
//                                                         borderRadius: BorderRadius.circular(20)
//                                                     ),
//                                                     child: Text(
//                                                         'FIINWAY',
//                                                         style: TextStyle(
//                                                             color: Colors.white,
//                                                             fontSize: 12,
//                                                             fontWeight: FontWeight.w700,
//                                                             letterSpacing: 2
//                                                         )
//                                                     )
//                                                 ),
//                                                 Icon(
//                                                     Icons.contactless,
//                                                     color: Colors.white.withOpacity(0.8),
//                                                     size: 32
//                                                 )
//                                             ]
//                                         ),
//
//                                         SizedBox(height: 14),
//
//                                         // Magnetic Strip
//                                         Container(
//                                             width: double.infinity,
//                                             height: 25,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black87,
//                                                 borderRadius: BorderRadius.circular(4)
//                                             )
//                                         ),
//
//                                         SizedBox(height: 10),
//
//                                         // CVV Section
//                                         Container(
//                                             padding: EdgeInsets.all(8),
//                                             decoration: BoxDecoration(
//                                                 color: Colors.white,
//                                                 borderRadius: BorderRadius.circular(8)
//                                             ),
//                                             child: Row(
//                                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                 children: [
//                                                     Column(
//                                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                                         children: [
//                                                             Text(
//                                                                 'CVV',
//                                                                 style: TextStyle(
//                                                                     color: Colors.black54,
//                                                                     fontSize: 10,
//                                                                     fontWeight: FontWeight.w600
//                                                                 )
//                                                             ),
//                                                             Text(
//                                                                 '•••',
//                                                                 style: TextStyle(
//                                                                     color: Colors.black87,
//                                                                     fontSize: 20,
//                                                                     fontWeight: FontWeight.bold,
//                                                                     letterSpacing: 3
//                                                                 )
//                                                             )
//                                                         ]
//                                                     ),
//                                                     Column(
//                                                         crossAxisAlignment: CrossAxisAlignment.end,
//                                                         children: [
//                                                             Text(
//                                                                 'VALID THRU',
//                                                                 style: TextStyle(
//                                                                     color: Colors.black54,
//                                                                     fontSize: 9,
//                                                                     fontWeight: FontWeight.w600
//                                                                 )
//                                                             ),
//                                                             Text(
//                                                                 '12/28',
//                                                                 style: TextStyle(
//                                                                     color: Colors.black87,
//                                                                     fontSize: 14,
//                                                                     fontWeight: FontWeight.w700
//                                                                 )
//                                                             )
//                                                         ]
//                                                     )
//                                                 ]
//                                             )
//                                         ),
//
//                                         Spacer(),
//
//                                         // Footer Info
//                                         Text(
//                                             'For customer service call: 1800-XXX-XXXX',
//                                             style: TextStyle(
//                                                 color: Colors.white.withOpacity(0.7),
//                                                 fontSize: 9
//                                             )
//                                         ),
//                                         SizedBox(height: 4),
//                                         Text(
//                                             'This card is property of FIINWAY',
//                                             style: TextStyle(
//                                                 color: Colors.white.withOpacity(0.7),
//                                                 fontSize: 9
//                                             )
//                                         )
//                                     ]
//                                 )
//                             )
//                         ]
//                     )
//                 )
//             )
//         );
//     }
// }

class CardItemWidget extends StatelessWidget {
    final CardData card;
    final MedicalCardController controller = Get.find<MedicalCardController>();

    CardItemWidget({super.key, required this.card});

    @override
    Widget build(BuildContext context) {
        final gradientColors = card.gradientColors
            .map((hex) => ColorUtils.hexToColor(hex))
            .toList();

        return Obx(() {
                final isPurchased = controller.isPurchased(card.id);

                return Container(
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: Offset(0, 8)
                            )
                        ]
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // 3D Card Preview
                            Padding(
                                padding: EdgeInsets.all(16),
                                child: Card3DWidget(
                                    cardData: card,
                                    isPurchased: false
                                )
                            ),

                            // Card Type Header
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                    card.type,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF)
                                    )
                                )
                            ),

                            // Features Section
                            Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        ...card.features
                                            .map((feature) => Padding(
                                                    padding: EdgeInsets.only(bottom: 12),
                                                    child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Container(
                                                                margin: EdgeInsets.only(top: 2),
                                                                padding: EdgeInsets.all(4),
                                                                decoration: BoxDecoration(
                                                                    color: Color(0xFFDC2626).withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(6)
                                                                ),
                                                                child: Icon(
                                                                    Icons.check,
                                                                    color: Color(0xFFDC2626),
                                                                    size: 14
                                                                )
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                                child: Text(
                                                                    feature,
                                                                    style: TextStyle(
                                                                        color: Color(0xFF1E40AF),
                                                                        fontSize: 14,
                                                                        height: 1.5,
                                                                        fontWeight: FontWeight.w500
                                                                    )
                                                                )
                                                            )
                                                        ]
                                                    )
                                                ))
                                            ,
                                        SizedBox(height: 20),

                                        // Purchase Button
                                        SizedBox(
                                            width: double.infinity,
                                            height: 54,
                                            child: ElevatedButton(
                                                onPressed: isPurchased
                                                    ? null
                                                    : () => showDialog(
                                                        context: context,
                                                        builder: (context) => PurchaseDialog(card: card)
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: isPurchased ? Colors.grey[300] : gradientColors[0],
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16)
                                                    ),
                                                    elevation: isPurchased ? 0 : 4,
                                                    shadowColor: gradientColors[0].withValues(alpha: 0.4)
                                                ),
                                                child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                        Icon(
                                                            isPurchased ? Icons.check_circle : Icons.shopping_bag_outlined,
                                                            size: 22
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                            isPurchased
                                                                ? 'Already Purchased'
                                                                : 'Purchase ${card.price.toStringAsFixed(0)}',
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                letterSpacing: 0.5
                                                            )
                                                        )
                                                    ]
                                                )
                                            )
                                        )
                                    ]
                                )
                            )
                        ]
                    )
                );
            }
        );
    }
}

class PurchaseDialog extends StatelessWidget {
    final CardData card;
    final MedicalCardController controller = Get.find<MedicalCardController>();

    PurchaseDialog({super.key, required this.card});

    @override
    Widget build(BuildContext context) {
        final gradientColors =
            card.gradientColors.map((hex) => ColorUtils.hexToColor(hex)).toList();

        return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Icon
                        Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: gradientColors
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                    BoxShadow(
                                        color: gradientColors[0].withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: Offset(0, 5)
                                    )
                                ]
                            ),
                            child: Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 40
                            )
                        ),
                        SizedBox(height: 20),

                        // Title
                        Text(
                            'Confirm Purchase',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold
                            )
                        ),
                        SizedBox(height: 16),

                        // Details Container
                        Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16)
                            ),
                            child: Column(
                                children: [
                                    _buildDetailRow('Card Type', card.type, false),
                                    Divider(height: 24),
                                    _buildDetailRow(
                                        'Credit Limit', '${card.limit.toStringAsFixed(0)}', false),
                                    Divider(height: 24),
                                    _buildDetailRow(
                                        'Price',
                                        '${card.price.toStringAsFixed(0)}',
                                        true,
                                        color: gradientColors[0]
                                    )
                                ]
                            )
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                            children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => Get.back(),
                                        style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            side: BorderSide(color: Colors.grey[300]!),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)
                                            )
                                        ),
                                        child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.bold
                                            )
                                        )
                                    )
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                    child: ElevatedButton(
                                        onPressed: () {
                                            Get.back();
                                            controller.purchaseCard(card);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: gradientColors[0],
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)
                                            ),
                                            elevation: 0
                                        ),
                                        child: Text(
                                            'Confirm',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold
                                            )
                                        )
                                    )
                                )
                            ]
                        )
                    ]
                )
            )
        );
    }

    Widget _buildDetailRow(String label, String value, bool isPrice,
        {Color? color}) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                    label,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isPrice ? 16 : 14
                    )
                ),
                Text(
                    value,
                    style: TextStyle(
                        fontSize: isPrice ? 20 : 14,
                        fontWeight: FontWeight.bold,
                        color: color ?? Colors.black87
                    )
                )
            ]
        );
    }
}

