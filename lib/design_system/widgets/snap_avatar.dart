import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';

class SnapAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isGroup;

  const SnapAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.isGroup = false,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '';
    final names = name!.split(' ');
    if (names.length > 1 && names[1].isNotEmpty) {
      return names[0][0].toUpperCase() + names[1][0].toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (isGroup) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: SnapUIColors.greyLight,
        child: Icon(
          EvaIcons.peopleOutline,
          size: radius,
          color: SnapUIColors.greyDark,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: SnapUIColors.greyLight,
      backgroundImage: hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
      child: !hasImage
          ? Text(
              _initials,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: SnapUIColors.greyDark,
                  ),
            )
          : null,
    );
  }
} 