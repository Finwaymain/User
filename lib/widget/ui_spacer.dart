import 'package:flutter/material.dart';

class UiSpacer {
  static Widget verticalSpace(double height) {
    return SizedBox(height: height);
  }

  static Widget horizontalSpace(double width) {
    return SizedBox(width: width);
  }

  static Widget emptySpace() {
    return const SizedBox.shrink();
  }

  static Widget verticalExpanded() {
    return Expanded(child: SizedBox.shrink());
  }

  static Widget horizontalExpanded() {
    return Expanded(child: SizedBox.shrink());
  }
}
