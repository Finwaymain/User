import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:finway/controller/all_services_controller.dart';
import 'service_flow.dart';
import 'service_option_selection_screen.dart';

/// Backward-compatible entry for lab test multi-select flow.
@Deprecated('Use ServiceOptionSelectionScreen via openServiceFlow instead')
class LabSampleSelectionScreen extends StatelessWidget {
  final String categoryName;

  const LabSampleSelectionScreen({
    super.key,
    this.categoryName = 'Lab Sample Collection',
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllServicesController(), tag: 'lab_sample_legacy');
    return ServiceOptionSelectionScreen(
      serviceName: 'Lab Sample Collection',
      parentCategoryName: categoryName,
      mode: ServiceSelectionMode.multi,
      controller: controller,
    );
  }
}
