import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';

class SamplePromptChip extends StatelessWidget {
  final SamplePrompt prompt;
  final VoidCallback onTap;
  const SamplePromptChip({super.key, required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                prompt.label,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: prompt.lang == 'urdu' ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                prompt.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.text, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
