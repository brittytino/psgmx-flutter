import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/connectivity_service.dart';

/// Modern, sleek offline banner with smooth animations
class ModernOfflineBanner extends StatefulWidget {
  final Widget child;
  
  const ModernOfflineBanner({super.key, required this.child});

  @override
  State<ModernOfflineBanner> createState() => _ModernOfflineBannerState();
}

class _ModernOfflineBannerState extends State<ModernOfflineBanner>
    with SingleTickerProviderStateMixin {
  late StreamSubscription _connectionSubscription;
  bool _isOffline = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    ConnectivityService().init();
    _isOffline = !ConnectivityService().hasConnection;
    
    if (_isOffline) {
      _animationController.forward();
    }
    
    _connectionSubscription = ConnectivityService()
        .connectionChange
        .listen((isConnected) {
      setState(() {
        final wasOffline = _isOffline;
        _isOffline = !isConnected;
        
        if (_isOffline && !wasOffline) {
          // Just went offline
          _animationController.forward();
        } else if (!_isOffline && wasOffline) {
          // Just came back online
          _animationController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _slideAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                    : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    color: isDark ? Colors.orange[300] : Colors.orange[800],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You\'re Offline',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark 
                              ? Colors.orange[300]
                              : Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Some features may be unavailable',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark 
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Pulsing indicator
                _buildPulsingDot(isDark),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildPulsingDot(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? Colors.orange[300] : Colors.orange[800],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.orange[300]! : Colors.orange[800]!)
                    .withValues(alpha: value),
                blurRadius: 8 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted && _isOffline) {
          setState(() {});
        }
      },
    );
  }
}
