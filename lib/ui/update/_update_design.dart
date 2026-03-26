/// Shared design tokens and helper widgets for all update-related screens.
/// Ensures a uniform visual language across [OptionalUpdateSheet],
/// [ForceUpdateScreen], and [EmergencyBlockScreen].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Tokens ────────────────────────────────────────────────────────────────

const Color kUpdateAccent = Colors.orange;
const Color kUpdateDangerAccent = Colors.red;
const double kCardRadius = 20.0;
const double kBtnRadius = 16.0;
const double kBtnHeight = 56.0;
const double kImageHeightFull = 220.0;
const double kImageHeightSheet = 190.0;

Color kSurfaceColor(bool isDark) =>
    isDark ? const Color(0xFF1E1E2E) : Colors.white;
Color kBgColor(bool isDark) =>
    isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FA);
Color kCardBorderColor(bool isDark) =>
    isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.15);
Color kBodyTextColor(bool isDark) =>
    isDark ? Colors.grey.shade300 : Colors.grey.shade700;
Color kSubtextColor(bool isDark) =>
    isDark ? Colors.grey.shade500 : Colors.grey.shade500;

// ─── Shared widgets ─────────────────────────────────────────────────────────

/// Primary CTA (orange filled button)
class UpdatePrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  const UpdatePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: kBtnHeight,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kUpdateAccent,
          disabledBackgroundColor: kUpdateAccent.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBtnRadius)),
          elevation: 0,
        ),
        child: loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingLabel ?? 'Opening…',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary text/outline button
class UpdateSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;

  const UpdateSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: kBtnHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          side: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBtnRadius)),
        ),
      ),
    );
  }
}

/// Version comparison row: Current → arrow → Latest
class UpdateVersionCard extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final bool isDark;

  const UpdateVersionCard({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  kUpdateAccent.withValues(alpha: 0.10),
                  Colors.deepOrange.withValues(alpha: 0.05),
                ]
              : [
                  kUpdateAccent.withValues(alpha: 0.07),
                  Colors.deepOrange.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
            color: kUpdateAccent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _versionBadge('Current', 'v$currentVersion', Colors.red, isDark),
          const Icon(Icons.arrow_forward_rounded,
              color: kUpdateAccent, size: 22),
          _versionBadge('Latest', 'v$latestVersion', Colors.green, isDark),
        ],
      ),
    );
  }

  Widget _versionBadge(
      String label, String version, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Text(
            version,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Info card with optional icon, used for messages
class UpdateMessageCard extends StatelessWidget {
  final String message;
  final Color accentColor;
  final IconData? leadingIcon;
  final bool isDark;

  const UpdateMessageCard({
    super.key,
    required this.message,
    required this.accentColor,
    required this.isDark,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
            color: accentColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 32, color: accentColor.withValues(alpha: 0.85)),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: kBodyTextColor(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
