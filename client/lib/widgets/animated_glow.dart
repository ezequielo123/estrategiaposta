import 'package:flutter/material.dart';

class AnimatedGlow extends StatelessWidget {
  final Widget child;
  final bool active;

  const AnimatedGlow({
    super.key,
    required this.child,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.yellowAccent.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
