import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/update_service.dart';

/// Full-screen blocking update UI.
class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _openingStore = false;

  Future<void> _handleUpdate() async {
    if (_openingStore || !mounted) return;

    setState(() => _openingStore = true);
    final updateService = context.read<UpdateService>();

    final success = await updateService.openUpdateUrl();
    if (!mounted) return;

    if (!success) {
      setState(() => _openingStore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open update link. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateService = context.watch<UpdateService>();
    final config = updateService.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final top = isDark ? const Color(0xFF090E1A) : const Color(0xFFF6F9FF);
    final bottom = isDark ? const Color(0xFF0E1F3A) : const Color(0xFFE7EEFA);
    final cardColor = isDark ? const Color(0xFF121D31) : Colors.white;
    final border = isDark ? const Color(0xFF2E4365) : const Color(0xFFD4E1F6);
    final titleColor = isDark ? Colors.white : const Color(0xFF10213F);
    final labelColor =
        isDark ? const Color(0xFFB8C8E4) : const Color(0xFF4D6186);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = math.min(560.0, constraints.maxWidth - 24);
              final gifHeight = math.min(
                constraints.maxHeight * 0.36,
                math.max(180.0, constraints.maxWidth * 0.52),
              );

              return Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Container(
                    width: maxWidth,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'App Update Required',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/force_update_app.gif',
                            height: gifHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Update to Continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: constraints.maxWidth < 360 ? 26 : 30,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current v${updateService.currentVersion ?? "?"}   ->   Latest v${config?.latestVersion ?? "?"}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _openingStore ? null : _handleUpdate,
                            icon: _openingStore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.system_update_alt_rounded,
                                    size: 22),
                            label: Text(
                              _openingStore ? 'Opening Store...' : 'Update Now',
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
