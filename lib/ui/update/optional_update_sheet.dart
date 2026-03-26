import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/update_service.dart';

class OptionalUpdateSheet extends StatefulWidget {
  const OptionalUpdateSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => const OptionalUpdateSheet(),
    );
  }

  @override
  State<OptionalUpdateSheet> createState() => _OptionalUpdateSheetState();
}

class _OptionalUpdateSheetState extends State<OptionalUpdateSheet> {
  bool _openingStore = false;
  bool _closingWithFunImage = false;

  Future<void> _handleCancel() async {
    if (_openingStore || _closingWithFunImage || !mounted) return;

    setState(() => _closingWithFunImage = true);
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;
    context.read<UpdateService>().dismissOptionalUpdate();
    Navigator.pop(context);
  }

  Future<void> _handleUpdate() async {
    if (_openingStore || !mounted) return;
    setState(() => _openingStore = true);

    final updateService = context.read<UpdateService>();
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    Navigator.pop(context);
    updateService.dismissOptionalUpdate();
    await updateService.openUpdateUrl();
  }

  @override
  Widget build(BuildContext context) {
    final updateService = context.watch<UpdateService>();
    final config = updateService.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    final bgTop = isDark ? const Color(0xFF111C31) : const Color(0xFFFFFFFF);
    final bgBottom = isDark ? const Color(0xFF0D1729) : const Color(0xFFF3F8FF);
    final border = isDark ? const Color(0xFF324866) : const Color(0xFFD6E4FB);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F2444);
    final textColor =
        isDark ? const Color(0xFFBCC9DE) : const Color(0xFF4C5F7F);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hPad = constraints.maxWidth < 400 ? 10.0 : 16.0;
          final maxHeight = math.min(media.size.height * 0.9, 700.0);
          final imageHeight = math.min(
            190.0,
            math.max(130.0, constraints.maxWidth * 0.35),
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 620),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border, width: 1.2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgTop, bgBottom],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.13),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 7),
                                Text(
                                  'Update Available',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Image.asset(
                            _closingWithFunImage
                                ? 'assets/images/app_update_cancelled.png'
                                : 'assets/images/app_update_available.png',
                            key: ValueKey(_closingWithFunImage),
                            height: imageHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _closingWithFunImage
                              ? 'No Problem, Catch You Later'
                              : 'A Better Version Is Ready',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: constraints.maxWidth < 360 ? 24 : 27,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _closingWithFunImage
                              ? 'We will remind you again soon.'
                              : 'Update now to get the newest improvements and bug fixes for PSGMX.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.45,
                            color: textColor,
                          ),
                        ),
                        if (!_closingWithFunImage) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF17263F)
                                  : const Color(0xFFF5F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2E466A)
                                    : const Color(0xFFDCE8FF),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _VersionPill(
                                  label: 'Current',
                                  value:
                                      'v${updateService.currentVersion ?? "?"}',
                                  color: const Color(0xFFEF4444),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: isDark
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF2563EB),
                                  size: 20,
                                ),
                                _VersionPill(
                                  label: 'Latest',
                                  value: 'v${config?.latestVersion ?? "?"}',
                                  color: const Color(0xFF22C55E),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _openingStore ? null : _handleUpdate,
                              icon: _openingStore
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.system_update_alt_rounded,
                                      size: 21),
                              label: Text(
                                _openingStore
                                    ? 'Opening Store...'
                                    : 'Update Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _openingStore ? null : _handleCancel,
                              icon:
                                  const Icon(Icons.schedule_rounded, size: 18),
                              label: Text(
                                'Maybe Later',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? const Color(0xFFD4E0F5)
                                    : const Color(0xFF415576),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF3C5578)
                                      : const Color(0xFFC5D7F2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 18),
                          Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VersionPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class OptionalUpdateDialog extends StatelessWidget {
  const OptionalUpdateDialog({super.key});

  static void show(BuildContext context) {
    OptionalUpdateSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
