import 'package:flutter/material.dart';

class CheteniLogo extends StatelessWidget {
  final double size;
  const CheteniLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
        ),
      ],
    );
  }
}
