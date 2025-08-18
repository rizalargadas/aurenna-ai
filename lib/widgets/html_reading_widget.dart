import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../config/theme.dart';

class HtmlReadingWidget extends StatelessWidget {
  final String content;
  final String? fallbackTextColor;

  const HtmlReadingWidget({
    super.key,
    required this.content,
    this.fallbackTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check if content has HTML tags
    if (content.contains('<') && content.contains('>')) {
      return Html(
        data: content,
        style: {
          "body": Style(padding: HtmlPaddings.zero, margin: Margins.zero),
          "div.general-reading": Style(padding: HtmlPaddings.zero),
          "div.career-reading": Style(padding: HtmlPaddings.zero),
          "div.card-of-day-reading": Style(padding: HtmlPaddings.zero),
          "div.three-card-reading": Style(padding: HtmlPaddings.zero),
          "div.card-section": Style(
            margin: Margins.only(bottom: 24),
            padding: HtmlPaddings.all(20),
          ),
          "h3": Style(
            color: AurennaTheme.electricViolet,
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 12),
          ),
          "p": Style(
            color: AurennaTheme.textPrimary,
            fontSize: FontSize(15),
            lineHeight: LineHeight(1.6),
            margin: Margins.only(bottom: 16),
          ),
          "div.wake-up-call": Style(
            margin: Margins.only(top: 32),
            padding: HtmlPaddings.all(24),
            backgroundColor: AurennaTheme.electricViolet.withValues(
              alpha: 0.08,
            ),
            border: Border.all(
              color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          "div.wake-up-call h3": Style(
            color: AurennaTheme.electricViolet,
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            margin: Margins.only(bottom: 20),
          ),
          "div.real-talk": Style(margin: Margins.only(bottom: 20)),
          "div.real-talk p": Style(
            fontSize: FontSize(16),
            fontStyle: FontStyle.italic,
            color: AurennaTheme.textPrimary,
            margin: Margins.only(bottom: 16),
          ),
          "strong": Style(
            color: AurennaTheme.electricViolet,
            fontWeight: FontWeight.bold,
          ),
          "div.homework": Style(
            margin: Margins.only(bottom: 20),
            padding: HtmlPaddings.all(20),
            backgroundColor: AurennaTheme.mysticBlue.withValues(alpha: 0.2),
          ),
          "h4": Style(
            color: AurennaTheme.electricViolet,
            fontSize: FontSize(16),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 12),
          ),
          "ul": Style(
            padding: HtmlPaddings.only(left: 20),
            margin: Margins.zero,
          ),
          "li": Style(
            color: AurennaTheme.textPrimary,
            fontSize: FontSize(15),
            margin: Margins.only(bottom: 8),
            lineHeight: LineHeight(1.5),
          ),
          "div.final-push": Style(textAlign: TextAlign.center),
          "div.final-push p": Style(
            margin: Margins.only(bottom: 12),
            color: AurennaTheme.textPrimary,
          ),
          "em": Style(
            fontStyle: FontStyle.italic,
            color: AurennaTheme.electricViolet,
          ),
          "p.signature": Style(
            fontSize: FontSize(16),
            fontWeight: FontWeight.bold,
            color: AurennaTheme.electricViolet,
            margin: Margins.only(top: 16),
          ),
          "div.safety-message": Style(
            padding: HtmlPaddings.all(20),
            backgroundColor: AurennaTheme.electricViolet.withValues(
              alpha: 0.15,
            ),
            textAlign: TextAlign.center,
          ),
          "div.safety-message p": Style(
            color: AurennaTheme.textPrimary,
            fontSize: FontSize(16),
            fontWeight: FontWeight.w500,
          ),
        },
      );
    } else {
      // Plain text fallback
      final textColor = fallbackTextColor != null
          ? _parseColor(fallbackTextColor!)
          : AurennaTheme.silverMist;

      return Text(
        content,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.6, color: textColor),
      );
    }
  }

  Color _parseColor(String colorString) {
    // Simple color parsing - can be extended
    switch (colorString.toLowerCase()) {
      case 'textprimary':
        return AurennaTheme.textPrimary;
      case 'textsecondary':
        return AurennaTheme.textSecondary;
      case 'silvermist':
        return AurennaTheme.silverMist;
      default:
        return AurennaTheme.silverMist;
    }
  }
}
