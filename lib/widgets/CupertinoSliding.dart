import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SegmentedAuthButtons extends StatefulWidget {
  const SegmentedAuthButtons({super.key});

  @override
  State<SegmentedAuthButtons> createState() => _SegmentedAuthButtonsState();
}

class _SegmentedAuthButtonsState extends State<SegmentedAuthButtons> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: _value,
      backgroundColor: const Color(0xFFF2F2F2),
      thumbColor: const Color(0xFF2E3A4F),
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Iniciar sesión',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Crear cuenta',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      },
      onValueChanged: (value) {
        setState(() {
          _value = value!;
        });
      },
    );
  }
}
