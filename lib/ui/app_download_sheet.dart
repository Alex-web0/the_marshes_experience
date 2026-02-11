import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ui_layers.dart';

/// Animated bottom sheet dialog prompting users to download the native app.
///
/// Shows Google Play and/or App Store buttons based on which links are valid.
/// Uses slide-up + fade animation with glassmorphic styling.
class AppDownloadSheet extends StatefulWidget {
  final String? googlePlayLink;
  final String? appStoreLink;
  final VoidCallback onDismiss;
  final VoidCallback? onButtonSound;

  const AppDownloadSheet({
    this.googlePlayLink,
    this.appStoreLink,
    required this.onDismiss,
    this.onButtonSound,
    super.key,
  });

  @override
  State<AppDownloadSheet> createState() => _AppDownloadSheetState();
}

class _AppDownloadSheetState extends State<AppDownloadSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Future<void> _openLink(String url) async {
    widget.onButtonSound?.call();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: GestureDetector(
            onTap: () {}, // Block taps from passing through
            child: SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.04),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle bar
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: const Icon(
                                Icons.smartphone,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              'Get the App!',
                              style: kDisplayFont.copyWith(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Play The Marshes Experience\non your mobile device',
                              textAlign: TextAlign.center,
                              style: kGameFont.copyWith(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Store Buttons
                            if (widget.googlePlayLink != null)
                              _StoreButton(
                                icon: Icons.shop,
                                label: 'Google Play',
                                sublabel: 'GET IT ON',
                                gradientColors: const [
                                  Color(0xFF00C853),
                                  Color(0xFF1B5E20),
                                ],
                                onTap: () => _openLink(widget.googlePlayLink!),
                              ),

                            if (widget.googlePlayLink != null &&
                                widget.appStoreLink != null)
                              const SizedBox(height: 12),

                            if (widget.appStoreLink != null)
                              _StoreButton(
                                icon: Icons.apple,
                                label: 'App Store',
                                sublabel: 'DOWNLOAD ON THE',
                                gradientColors: const [
                                  Color(0xFF42A5F5),
                                  Color(0xFF0D47A1),
                                ],
                                onTap: () => _openLink(widget.appStoreLink!),
                              ),

                            const SizedBox(height: 16),

                            // Dismiss
                            GestureDetector(
                              onTap: () {
                                widget.onButtonSound?.call();
                                _dismiss();
                              },
                              child: Text(
                                'Maybe Later',
                                style: kGameFont.copyWith(
                                  fontSize: 14,
                                  color: Colors.white38,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _StoreButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sublabel,
                  style: kGameFont.copyWith(
                    fontSize: 10,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  label,
                  style: kGameFont.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
