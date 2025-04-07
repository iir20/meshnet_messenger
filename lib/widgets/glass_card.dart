import 'dart:ui';
import 'package:flutter/material.dart';

/// A card widget with a frosted glass effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  
  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: borderRadius,
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A container with a holographic edge glow effect
class HoloContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color glowColor;
  final double glowOpacity;
  final double glowSpread;
  final double glowBlur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const HoloContainer({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.glowColor = Colors.blue,
    this.glowOpacity = 0.5,
    this.glowSpread = 1.0,
    this.glowBlur = 8.0,
    this.padding,
    this.margin,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black12,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(glowOpacity),
            spreadRadius: glowSpread,
            blurRadius: glowBlur,
          ),
        ],
        border: Border.all(
          color: glowColor.withOpacity(glowOpacity + 0.2),
          width: 1.5,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// A futuristic button with glow effects
class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final bool isOutlined;
  final IconData? icon;
  final bool isActive;

  const NeonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = Colors.blue,
    this.width = double.infinity,
    this.height = 50.0,
    this.isOutlined = false,
    this.icon,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isActive ? onPressed : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isActive ? color : color.withOpacity(0.6),
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A futuristic text field with glow effects
class HoloTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final int? maxLines;
  final TextInputType keyboardType;
  final Color accentColor;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const HoloTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.accentColor = Colors.blue,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: accentColor,
                size: 20,
              )
            : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
} 