import 'package:get/get.dart';

import 'package:finway/controller/all_services_controller.dart';
import 'package:finway/model/service_category_model.dart';
import 'service_category_detail_screen.dart';
import 'service_option_selection_screen.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

enum ServiceSelectionMode { none, single, multi }

enum ServiceFlowStep { categoryGrid, optionSingle, optionMulti, bookingForm }

const Set<String> _singleSelectServices = {
  'doctor home visit',
  'physiotherapy',
  'physiotherapist',
  'nursing care',
  'home tutor',
  'home tutor services',
};

const Set<String> _multiSelectServices = {
  'lab sample collection',
  'lab technician',
  'diagnostic lab',
  'blood tests',
  'lab tests',
};

ServiceSelectionMode selectionModeForName(String? rawName) {
  final clean = cleanServiceName(rawName).toLowerCase();
  if (_multiSelectServices.any((s) => clean.contains(s) || s.contains(clean))) {
    return ServiceSelectionMode.multi;
  }
  if (_singleSelectServices.any((s) => clean == s || clean.contains(s))) {
    return ServiceSelectionMode.single;
  }
  return ServiceSelectionMode.none;
}

bool isCategoryHub(String? rawName) {
  if (selectionModeForName(rawName) != ServiceSelectionMode.none) return false;
  return isParentServiceCategory(rawName);
}

ServiceFlowStep resolveFlowStep(ServiceCategoryData category, {List<ServiceCategoryData> knownChildren = const []}) {
  final mode = selectionModeForName(category.libelle);
  if (mode == ServiceSelectionMode.multi) return ServiceFlowStep.optionMulti;
  if (mode == ServiceSelectionMode.single) return ServiceFlowStep.optionSingle;

  final hasChildren = category.hasChildren ||
      knownChildren.isNotEmpty ||
      (isParentServiceCategory(category.libelle) &&
          AllServicesController().fallbackSubCategories(category.libelle ?? '').isNotEmpty);

  if (hasChildren && (isCategoryHub(category.libelle) || category.hasChildren)) {
    return ServiceFlowStep.categoryGrid;
  }

  return ServiceFlowStep.bookingForm;
}

String bookingCategoryName({
  required String tappedName,
  required String parentCategoryName,
}) {
  final cleanParent = cleanServiceName(parentCategoryName);
  final cleanTapped = cleanServiceName(tappedName);
  if (cleanParent.isEmpty) return cleanTapped;
  if (cleanParent.toLowerCase() == cleanTapped.toLowerCase()) return cleanTapped;
  if (isCategoryHub(cleanParent)) return cleanTapped;
  return cleanParent;
}

Future<void> openServiceFlow(
  ServiceCategoryData category, {
  required String parentCategoryName,
  required AllServicesController controller,
  List<ServiceCategoryData> knownChildren = const [],
}) async {
  final step = resolveFlowStep(category, knownChildren: knownChildren);
  final rawName = category.libelle ?? '';
  final categoryLabel = bookingCategoryName(tappedName: rawName, parentCategoryName: parentCategoryName);

  switch (step) {
    case ServiceFlowStep.categoryGrid:
      Get.to(() => ServiceCategoryDetailScreen(categoryId: category.id ?? 0, categoryName: rawName));
      return;
    case ServiceFlowStep.optionSingle:
      Get.to(() => ServiceOptionSelectionScreen(
            categoryId: category.id,
            serviceName: rawName,
            parentCategoryName: categoryLabel,
            mode: ServiceSelectionMode.single,
            controller: controller,
          ));
      return;
    case ServiceFlowStep.optionMulti:
      Get.to(() => ServiceOptionSelectionScreen(
            categoryId: category.id,
            serviceName: rawName,
            parentCategoryName: categoryLabel,
            mode: ServiceSelectionMode.multi,
            controller: controller,
          ));
      return;
    case ServiceFlowStep.bookingForm:
      Get.to(() => ServiceRequestScreen(
            serviceName: rawName,
            categoryName: categoryLabel,
            selectedServices: [cleanServiceName(rawName)],
          ));
      return;
  }
}
