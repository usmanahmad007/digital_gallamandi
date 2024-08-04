// custom_gesture_detector.dart
import 'package:flutter/material.dart';

class sallerCustomGestureDetector extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final IconData trailingIcon;
  final Function() onTap;
  final Color? leadingIconColor;
  final Color? trailingIconColor;
  final Color? titleColor;

  const sallerCustomGestureDetector({
    required this.leadingIcon,
    required this.title,
    required this.trailingIcon,
    required this.onTap,
    this.leadingIconColor,
    this.trailingIconColor,
    this.titleColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(leadingIcon, color: leadingIconColor),
        trailing: Icon(trailingIcon, color: trailingIconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),
    );
  }
}
