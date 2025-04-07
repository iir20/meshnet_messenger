import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final bool autoFocus;
  
  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onClear,
    this.onSubmitted,
    this.autoFocus = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: themeData.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }
} 