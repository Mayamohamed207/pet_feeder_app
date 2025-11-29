//widgets/vibrant_button.dart
import 'package:flutter/material.dart';

class VibrantButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const VibrantButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2196F3), // was 'primary'
        foregroundColor: Colors.white,       // was 'onPrimary'
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
