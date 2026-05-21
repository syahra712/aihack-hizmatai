import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.4, 1.4),
                  duration: 500.ms,
                  delay: Duration(milliseconds: i * 150),
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 150));
          }),
        ),
      ),
    );
  }
}
