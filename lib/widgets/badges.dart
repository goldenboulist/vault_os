import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../theme/app_theme.dart';

// ── Category tag ───────────────────────────────────────────────────────────────

class CategoryTag extends StatelessWidget {
  final VaultCategory category;

  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          color: category.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── 2FA badge ──────────────────────────────────────────────────────────────────

class TwoFABadge extends StatelessWidget {
  const TwoFABadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.tag2FA,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '2FA',
        style: TextStyle(
          color: AppTheme.tag2FAText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Strength bar ───────────────────────────────────────────────────────────────

class StrengthBar extends StatelessWidget {
  final PasswordStrength strength;

  const StrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fillWidth = switch (strength) {
          PasswordStrength.strong => totalWidth * 0.85,
          PasswordStrength.good   => totalWidth * 0.60,
          PasswordStrength.weak   => totalWidth * 0.30,
        };
        final color = switch (strength) {
          PasswordStrength.strong => AppTheme.strengthStrong,
          PasswordStrength.good   => AppTheme.strengthGood,
          PasswordStrength.weak   => AppTheme.strengthWeak,
        };
        final label = switch (strength) {
          PasswordStrength.strong => 'Strong',
          PasswordStrength.good   => 'Good',
          PasswordStrength.weak   => 'Weak',
        };

        return Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}