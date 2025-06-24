import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';

class SnapTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const SnapTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SnapUIDimensions.spacingL,
          vertical: SnapUIDimensions.spacingL,
        ),
      ),
    );
  }
} 