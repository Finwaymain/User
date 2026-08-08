import 'package:flutter/material.dart';

import 'service_style.dart';

String resolveServiceImageUrl(String? image) {
  if (image == null || image.isEmpty) return '';
  if (image.startsWith('icon:')) return '';
  if (image.startsWith('http')) return image;
  final path = image.startsWith('/') ? image.substring(1) : image;
  return 'https://fiinway.online/$path';
}

class ServiceCategoryIcon extends StatelessWidget {
  final String? label;
  final String? imageUrl;
  final double size;
  final ServiceCategoryStyle? parentStyle;
  final double borderRadius;

  const ServiceCategoryIcon({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 64,
    this.parentStyle,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final style = styleForServiceItem(label, parentStyle: parentStyle);
    final resolvedUrl = resolveServiceImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedUrl.isNotEmpty
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _iconBody(style),
            )
          : _iconBody(style),
    );
  }

  Widget _iconBody(ServiceCategoryStyle style) {
    return Center(child: Icon(style.icon, color: style.color, size: size * 0.48));
  }
}
