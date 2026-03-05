import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/update_service.dart';

/// Emergency Block Screen
/// 
/// Full-screen blocking UI when app is emergency blocked with modern engaging design.
/// User CANNOT dismiss this screen.
/// Only option is to update.
class EmergencyBlockScreen extends StatefulWidget {
  const EmergencyBlockScreen({super.key});

  @override
  State<EmergencyBlockScreen> createState() => _EmergencyBlockScreenState();
}

class _EmergencyBlockScreenState extends State<EmergencyBlockScreen> {
  bool _isDownloading = false;

  Future<void> _handleUpdate() async {
    if (!mounted) return;
    
    setState(() => _isDownloading = true);
    
    final updateService = context.read<UpdateService>();
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    final success = await updateService.openUpdateUrl();
    
    if (!mounted) return;
    
    if (!success) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Could not open download link')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateService = Provider.of<UpdateService>(context);
    final config = updateService.config;
    final message = config?.emergencyMessage ?? 
        'This app version has been temporarily disabled for security reasons. Please update to continue.';

    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0000),
                Color(0xFF0A0A12),
                Color(0xFF000000),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Image — transparent PNG, no wrapper needed
                  Image.asset(
                    'assets/images/app_crash.png',
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),

                  // Title with pulsing effect
                  Text(
                    '⚠️ EMERGENCY BLOCK ⚠️',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'App Temporarily Disabled',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Message Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[300],
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version Info Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'Current: v${updateService.currentVersion ?? "Unknown"}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.orange.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 8,
                        shadowColor: Colors.orange.withValues(alpha: 0.6),
                      ),
                      child: _isDownloading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Opening Download...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download_rounded, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Download Update',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exit App Button
                  TextButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: Text(
                      'Exit App',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Footer warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, 
                          size: 16, 
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Update required to continue',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red[300],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
