import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)],
              ),
              child: const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: _isUser
                    ? const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00B894)])
                    : null,
                color: _isUser ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(_isUser ? 18 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 18),
                ),
                boxShadow: _isUser ? AppShadows.primaryGlow : AppShadows.soft,
                border: _isUser ? null : Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: _hasArabicScript(message.text) ? TextDirection.rtl : TextDirection.ltr,
                    child: _isUser
                        ? Text(
                            message.text,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, height: 1.5),
                          )
                        : _buildRichText(message.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isUser ? Colors.white.withOpacity(0.6) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 15, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText(String text) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int li = 0; li < lines.length; li++) {
      final line = lines[li];
      if (li > 0) spans.add(const TextSpan(text: '\n'));

      if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('• ')) {
        spans.add(TextSpan(
          text: '  • ${line.trimLeft().substring(2)}',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text, height: 1.6),
        ));
        continue;
      }

      final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
      int lastEnd = 0;
      for (final match in regex.allMatches(line)) {
        if (match.start > lastEnd) {
          spans.add(TextSpan(
            text: line.substring(lastEnd, match.start),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text, height: 1.5),
          ));
        }
        if (match.group(1) != null) {
          spans.add(TextSpan(
            text: match.group(1),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700, height: 1.5),
          ));
        } else if (match.group(2) != null) {
          spans.add(TextSpan(
            text: match.group(2),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text, fontStyle: FontStyle.italic, height: 1.5),
          ));
        }
        lastEnd = match.end;
      }
      if (lastEnd < line.length) {
        spans.add(TextSpan(
          text: line.substring(lastEnd),
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text, height: 1.5),
        ));
      }
    }

    return Text.rich(TextSpan(children: spans));
  }

  bool _hasArabicScript(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);
}
